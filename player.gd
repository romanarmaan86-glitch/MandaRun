extends CharacterBody3D

signal died

const LANES = [-1.5, 0.0, 1.5]
const JUMP_VELOCITY = 6.0
const GRAVITY = 25.0
const AIR_SLIDE_FALL_SPEED = 12.0
const SLIDE_TIME = 0.5
const AIR_SLIDE_TIME_MULTIPLIER = 0.7   # Makes mid-air slides feel snappier (optional)
const NORMAL_HEIGHT = 1.6
const SLIDE_HEIGHT = 0.8
const LANE_LERP_SPEED = 12.0
const DEATH_Y = -10.0

var current_lane : int = 1
var is_sliding : bool = false
var slide_timer : float = 0.0
var dead : bool = false

@onready var collider : CollisionShape3D = $CollisionShape3D
@onready var mesh_stand: MeshInstance3D = $MeshInstance3D_Stand
@onready var mesh_slide: MeshInstance3D = $MeshInstance3D_Slide

func _ready() -> void:
	position.z = LANES[current_lane]

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector3.ZERO
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Faster fall when sliding (works on ground or in air)
	if is_sliding and velocity.y < 0:
		velocity.y = -AIR_SLIDE_FALL_SPEED

	# Smooth lane movement
	var target_z = LANES[current_lane]
	position.z = lerp(position.z, target_z, LANE_LERP_SPEED * delta)

	# Jump (now allowed even while sliding)
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not dead:
		if is_sliding:
			end_slide()          # Cancel slide before jumping (recommended feel)
		velocity.y = JUMP_VELOCITY

	# Slide timer countdown
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			end_slide()

	move_and_slide()

	# Fall death
	if global_position.y < DEATH_Y:
		hit_obstacle()

func _input(event: InputEvent) -> void:
	if dead:
		return
	if event.is_action_pressed("ui_left"):
		move_left()
	elif event.is_action_pressed("ui_right"):
		move_right()
	elif event.is_action_pressed("ui_down"):
		start_slide()

func move_left() -> void:
	if is_sliding:
		end_slide()
	current_lane = max(current_lane - 1, 0)

func move_right() -> void:
	if is_sliding:
		end_slide()
	current_lane = min(current_lane + 1, LANES.size() - 1)

func start_slide() -> void:
	if is_sliding or dead:
		return

	# Now allowed in air too (removed not is_on_floor() check)
	is_sliding = true

	# Slightly shorter slide duration when in air
	var this_slide_time = SLIDE_TIME
	if not is_on_floor():
		this_slide_time *= AIR_SLIDE_TIME_MULTIPLIER

	slide_timer = this_slide_time

	var shape = collider.shape as CapsuleShape3D
	if shape:
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(shape, "height", SLIDE_HEIGHT, 0.15)

	mesh_stand.visible = false
	mesh_slide.visible = true

func end_slide() -> void:
	if not is_sliding:
		return

	is_sliding = false

	var shape = collider.shape as CapsuleShape3D
	if shape:
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(shape, "height", NORMAL_HEIGHT, 0.15)

	mesh_stand.visible = true
	mesh_slide.visible = false

func hit_obstacle() -> void:
	if dead:
		return
	dead = true
	died.emit()
	print("Player died! (obstacle / fall)")
