extends Node3D

# ─────────────────────────────────────────────────────────────
# platformspawner.gd
# Every QUIZ_EVERY_N platforms after the grace period becomes a
# quiz platform (120 units long instead of 20).
# ─────────────────────────────────────────────────────────────

const PLATFORM_COUNT      := 7
const PLATFORM_LENGTH     := 20.0
const QUIZ_PLATFORM_LENGTH := 120.0
const DELETE_X            := -20
const MOVE_SPEED          := 15.0
const QUIZ_EVERY_N        := 5

@export var platform_scene: PackedScene
@export var quiz_platform_scene: PackedScene

var platforms: Array[Node3D] = []
var _spawned_after_grace: int = 0

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	for i in PLATFORM_COUNT:
		_spawn_normal(i)

func _physics_process(delta: float) -> void:
	for platform in platforms.duplicate():
		if platform == null or not is_instance_valid(platform):
			platforms.erase(platform)
			continue
		platform.position.x -= MOVE_SPEED * delta
		if platform.position.x < DELETE_X:
			platform.queue_free()
			platforms.erase(platform)
			_spawn_next()

# ─────────────────────────────────────────────────────────────

func _spawn_next() -> void:
	_spawned_after_grace += 1
	if _spawned_after_grace % QUIZ_EVERY_N == 0:
		_spawn_quiz()
	else:
		_spawn_normal()

func _spawn_normal(index: int = -1) -> void:
	var p = platform_scene.instantiate() as Node3D
	if p == null:
		printerr("Failed to instantiate platform_scene!")
		return
	p.position = Vector3(_next_x(PLATFORM_LENGTH), 0, 0)
	add_child(p)
	platforms.append(p)

	var obs = get_parent().get_node_or_null("obstaclespawner")
	if obs:
		obs.spawn_obstacle(p)

func _spawn_quiz() -> void:
	if quiz_platform_scene == null:
		printerr("quiz_platform_scene not assigned — falling back to normal platform")
		_spawn_normal()
		return
	var p = quiz_platform_scene.instantiate() as Node3D
	if p == null:
		printerr("Failed to instantiate quiz_platform_scene!")
		return
	p.position = Vector3(_next_x(QUIZ_PLATFORM_LENGTH), 0, 0)
	add_child(p)
	platforms.append(p)
	# No obstacles on quiz platforms

func _next_x(incoming_length: float) -> float:
	if platforms.is_empty():
		return 0.0
	var last = platforms.back()
	var last_len = _get_platform_length(last)
	return last.position.x + last_len

func _get_platform_length(p: Node3D) -> float:
	# Quiz platforms expose QUIZ_PLATFORM_LENGTH as a script constant
	if p.get_script() != null:
		var val = p.get("QUIZ_PLATFORM_LENGTH")
		if val != null:
			return float(val)
	return PLATFORM_LENGTH
