extends CharacterBody3D

@export var forward_speed := 10.0
@export var lane_distance := 3.0
@export var lane_change_speed := 10.0

var current_lane := 1 # 0 = left, 1 = middle, 2 = right

func _physics_process(delta):
	# Constant forward movement
	velocity.z = -forward_speed

	# Lane switching input
	if Input.is_action_just_pressed("move_left"):
		change_lane(-1)
	elif Input.is_action_just_pressed("move_right"):
		change_lane(1)

	# Target lane X position
	var target_x = (current_lane - 1) * lane_distance

	# Smooth lane movement
	position.x = move_toward(position.x, target_x, lane_change_speed * delta)

	move_and_slide()


func change_lane(direction: int):
	current_lane += direction
	current_lane = clamp(current_lane, 0, 2)
