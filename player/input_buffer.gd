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
var circle_motion_progress: int = 0
var back_forth_state: int = 0  # 0 = none, 1 = forward, 2 = back


func _ready() -> void:
	pass


func update(delta: float) -> void:
	if not config:
		return

	# Clean old inputs from buffer
	var current_time = Time.get_ticks_msec() / 1000.0
	buffer = buffer.filter(func(entry): return current_time - entry.timestamp < config.buffer_time)

	# Detect motion from input
	var input_dir = Input.get_vector("left", "right", "backward", "forward")
	var current_motion = _detect_motion(input_dir)

	# Add to buffer if motion changed
	if current_motion != last_motion:
		buffer.append(InputEntry.new(current_motion, current_time))
		last_motion = current_motion

		# Check for complex patterns
		_check_circle_motion(current_motion)
		_check_back_forth_motion(current_motion)


func _detect_motion(input_dir: Vector2) -> MotionType:
	if input_dir.length() < config.motion_detection_threshold:
		return MotionType.NEUTRAL

	# Determine primary direction
	if abs(input_dir.y) > abs(input_dir.x):
		if input_dir.y < 0:
			return MotionType.FORWARD
		else:
			return MotionType.BACKWARD
	else:
		if input_dir.x > 0:
			return MotionType.RIGHT
		else:
			return MotionType.LEFT


func _check_circle_motion(current: MotionType) -> void:
	# Simple circle detection: forward -> right -> backward -> left (or reverse)
	var expected_clockwise = [
		MotionType.FORWARD,
		MotionType.RIGHT,
		MotionType.BACKWARD,
		MotionType.LEFT
	]

	if circle_motion_progress < expected_clockwise.size() and \
	   current == expected_clockwise[circle_motion_progress]:
		circle_motion_progress += 1

		if circle_motion_progress >= expected_clockwise.size():
			combo_detected.emit("circle")
			circle_motion_progress = 0
	else:
		circle_motion_progress = 0
		if current == expected_clockwise[0]:
			circle_motion_progress = 1


func _check_back_forth_motion(current: MotionType) -> void:
	# Detect forward then backward motion
	if current == MotionType.FORWARD and back_forth_state == 0:
		back_forth_state = 1
	elif current == MotionType.BACKWARD and back_forth_state == 1:
		combo_detected.emit("back_forth")
		back_forth_state = 0
	elif current == MotionType.NEUTRAL:
		# Keep state on neutral
		pass
	else:
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


func clear_buffer() -> void:
	buffer.clear()
	circle_motion_progress = 0
	back_forth_state = 0


func set_config(new_config: PlayerConfig) -> void:
	config = new_config
