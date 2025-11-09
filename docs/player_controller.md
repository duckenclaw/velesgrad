# PlayerController

The player script is the main controller for the player. It handles all of the inputs and utilizes the StateMachine to transition between states. The states themselves contain all of the logic for the movement. The Hands is used to handle attacks using left and right hands through Hand class. And finally the Camera script is used to handle the camera movement.

The player controller must also include an input buffer system to register combo inputs:

- ⊙ Neutral (no movement)
- ↑ Forward movement
- ↓ Backward movement
- ↻ Circle motion
- ⇅ Back and forth movement

Actions:

- forward
- backward
- left
- right
- tilt_left
- tilt_right
- jump
- activate
- left_hand
- right_hand
- crouch
- sprint

states:

- idle
  - standing
- moving
  - regular movement, sprint handling (only when moving forward), crouch movement
- jumping
- falling

hierarchy:

- Player (Player)
  - CollisionShape3D
  - CameraPivot (Camera)
    - Camera3D
    - Hands
      - RightHand (Hand)
      - LeftHand (Hand)
  - StateMachine
    - IdleState
    - MovingState
    - JumpingState
    - FallingState

Player:
handles all input and communication with Camera, Hands and StateMachine.

PlayerConfig:
stores all of the player settings such as movement speed, jump force, camera sensitivity etc.

Camera:
Camera movement and rotation as well as tilting (through "tilt_left" and "tilt_right" actions)

Hand:
handles item picking and attacking through the currently equipped item.

StateMachine:
handles the state transitions between the states.