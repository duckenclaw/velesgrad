extends Node
class_name InputBuffer

## InputBuffer system for registering combo inputs
## Supported patterns:
## - ⊙ Neutral (no movement)
## - ↑ Forward movement
## - ↓ Backward movement
## - ↻ Circle motion
## - ⇅ Back and forth movement

signal combo_detected(combo_type: String)

enum MotionType {
	NEUTRAL,
	FORWARD,
	BACKWARD,
	LEFT,
	RIGHT,
	CIRCLE,
	BACK_FORTH
}

class InputEntry:
	var motion: MotionType
	var timestamp: float

	func _init(m: MotionType, t: float):
		motion = m
		timestamp = t

var config: PlayerConfig
var buffer: Array[InputEntry] = []
var last_motion: MotionType = MotionType.NEUTRAL
var circle_motion_sequence: Array[MotionType] = []  # Track sequence for circle detection
var back_forth_state: int = 0  # 0 = none, 1 = forward detected, -1 = backward detected

# Track held inputs - record periodically while holding
var hold_record_interval: float = 0.15  # Record every 0.15 seconds while holding
var time_since_last_record: float = 0.0

# Track the last successfully detected combo
var last_detected_combo: String = ""
var combo_timeout: float = 2.0  # Combo is valid for 2 seconds
var time_since_combo: float = 0.0


func _ready() -> void:
	pass


func update(delta: float) -> void:
	if not config:
		return

	# Update combo timeout
	time_since_combo += delta
	if time_since_combo > combo_timeout:
		last_detected_combo = ""

	# Clean old inputs from buffer
	var current_time = Time.get_ticks_msec() / 1000.0
	buffer = buffer.filter(func(entry): return current_time - entry.timestamp < config.buffer_time)

	# Detect motion from input
	var input_dir = Input.get_vector("left", "right", "backward", "forward")
	var current_motion = _detect_motion(input_dir)

	# Track time for periodic recording
	time_since_last_record += delta

	# Record motion in two cases:
	# 1. When motion changes (for immediate combo detection)
	# 2. Periodically while holding a direction (for better combo recognition)
	var should_record = false

	if current_motion != last_motion:
		# Motion changed - check for complex patterns
		_check_circle_motion(current_motion)
		_check_back_forth_motion(current_motion)

		# Record immediately only if not NEUTRAL
		if current_motion != MotionType.NEUTRAL:
			should_record = true

		time_since_last_record = 0.0
		last_motion = current_motion

	elif current_motion != MotionType.NEUTRAL and time_since_last_record >= hold_record_interval:
		# Holding a direction - record periodically
		should_record = true
		time_since_last_record = 0.0

	# Add entry to buffer if needed (never record NEUTRAL)
	if should_record:
		buffer.append(InputEntry.new(current_motion, current_time))
		print("Input recorded: ", MotionType.keys()[current_motion], " | Buffer size: ", buffer.size())


func _detect_motion(input_dir: Vector2) -> MotionType:
	if input_dir.length() < config.motion_detection_threshold:
		return MotionType.NEUTRAL

	# Determine primary direction
	# Note: Input.get_vector("left", "right", "backward", "forward")
	# - negative Y = backward
	# - positive Y = forward
	# - negative X = left
	# - positive X = right
	if abs(input_dir.y) > abs(input_dir.x):
		if input_dir.y > 0:  # Positive Y = forward
			return MotionType.FORWARD
		else:  # Negative Y = backward
			return MotionType.BACKWARD
	else:
		if input_dir.x > 0:  # Positive X = right
			return MotionType.RIGHT
		else:  # Negative X = left
			return MotionType.LEFT


func _check_circle_motion(current: MotionType) -> void:
	# Circle detection: track sequence of 4 unique cardinal directions
	# Clockwise: FORWARD→RIGHT→BACKWARD→LEFT (or starting from any point)
	# Counter-clockwise: FORWARD→LEFT→BACKWARD→RIGHT (or starting from any point)

	# Only track cardinal directions
	if current not in [MotionType.FORWARD, MotionType.RIGHT, MotionType.BACKWARD, MotionType.LEFT]:
		return

	# Add to sequence if it's different from the last entry
	if circle_motion_sequence.is_empty() or circle_motion_sequence.back() != current:
		circle_motion_sequence.append(current)
		print("Circle sequence: ", circle_motion_sequence.map(func(m): return MotionType.keys()[m]))

		# Keep only last 4 entries
		if circle_motion_sequence.size() > 4:
			circle_motion_sequence.pop_front()

	# Check if we have 4 unique directions
	if circle_motion_sequence.size() == 4:
		if _is_valid_circle_pattern(circle_motion_sequence):
			combo_detected.emit("circle")
			last_detected_combo = "circle"
			time_since_combo = 0.0
			circle_motion_sequence.clear()
			print("=== CIRCLE COMBO DETECTED ===")


func _is_valid_circle_pattern(sequence: Array[MotionType]) -> bool:
	# Check if sequence contains all 4 cardinal directions in circular order

	# Define clockwise and counter-clockwise patterns
	var clockwise = [
		MotionType.FORWARD,
		MotionType.RIGHT,
		MotionType.BACKWARD,
		MotionType.LEFT
	]

	var counter_clockwise = [
		MotionType.FORWARD,
		MotionType.LEFT,
		MotionType.BACKWARD,
		MotionType.RIGHT
	]

	# Check if sequence matches clockwise pattern from any starting point
	for start_idx in range(4):
		var matches_clockwise = true
		var matches_counter = true

		for i in range(4):
			var expected_cw_idx = (start_idx + i) % 4
			var expected_ccw_idx = (start_idx + i) % 4

			if sequence[i] != clockwise[expected_cw_idx]:
				matches_clockwise = false

			if sequence[i] != counter_clockwise[expected_ccw_idx]:
				matches_counter = false

		if matches_clockwise:
			print("Circle pattern: CLOCKWISE from ", MotionType.keys()[clockwise[start_idx]])
			return true

		if matches_counter:
			print("Circle pattern: COUNTER-CLOCKWISE from ", MotionType.keys()[counter_clockwise[start_idx]])
			return true

	return false


func _check_back_forth_motion(current: MotionType) -> void:
	# Detect bidirectional back-forth motion: forward->backward OR backward->forward

	if current == MotionType.FORWARD:
		if back_forth_state == -1:
			# BACKWARD->FORWARD combo detected!
			combo_detected.emit("back_forth")
			last_detected_combo = "back_forth"
			time_since_combo = 0.0
			back_forth_state = 0
			print("=== BACK_FORTH COMBO DETECTED (BACKWARD→FORWARD) ===")
		elif back_forth_state == 0:
			# Start tracking forward
			back_forth_state = 1
			print("Back-forth progress: FORWARD detected")
		# If state is 1, we're already tracking forward, just continue

	elif current == MotionType.BACKWARD:
		if back_forth_state == 1:
			# FORWARD->BACKWARD combo detected!
			combo_detected.emit("back_forth")
			last_detected_combo = "back_forth"
			time_since_combo = 0.0
			back_forth_state = 0
			print("=== BACK_FORTH COMBO DETECTED (FORWARD→BACKWARD) ===")
		elif back_forth_state == 0:
			# Start tracking backward
			back_forth_state = -1
			print("Back-forth progress: BACKWARD detected")
		# If state is -1, we're already tracking backward, just continue

	elif current == MotionType.NEUTRAL:
		# Keep state on neutral - don't reset
		pass

	elif current in [MotionType.LEFT, MotionType.RIGHT]:
		# Left/Right movement resets the combo
		if back_forth_state != 0:
			print("Back-forth progress reset (side movement)")
		back_forth_state = 0


func has_motion_in_buffer(motion: MotionType) -> bool:
	for entry in buffer:
		if entry.motion == motion:
			return true
	return false


func get_latest_motion() -> MotionType:
	if buffer.is_empty():	
		return MotionType.NEUTRAL
	return buffer.back().motion


func get_latest_non_neutral_motion() -> MotionType:
	# Search backwards through buffer for the most recent non-neutral motion
	for i in range(buffer.size() - 1, -1, -1):
		if buffer[i].motion != MotionType.NEUTRAL:
			return buffer[i].motion
	return MotionType.NEUTRAL


func get_recent_motion_history(count: int = 5) -> Array:
	# Get the last N motions for debugging
	var history = []
	var start_idx = max(0, buffer.size() - count)
	for i in range(start_idx, buffer.size()):
		history.append(MotionType.keys()[buffer[i].motion])
	return history


func get_last_detected_combo() -> String:
	# Return the last successfully detected combo (circle or back_forth)
	# or empty string if none or expired
	if time_since_combo < combo_timeout:
		return last_detected_combo
	return ""


func clear_buffer() -> void:
	buffer.clear()
	circle_motion_sequence.clear()
	back_forth_state = 0
	time_since_last_record = 0.0
	last_detected_combo = ""
	time_since_combo = 0.0


func set_config(new_config: PlayerConfig) -> void:
	config = new_config
