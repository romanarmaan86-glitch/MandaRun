extends Node3D

# ─────────────────────────────────────────────────────────────
# platformspawner.gd  (Scripts/platformspawner.gd)
#
# Delete fix: instead of a fixed DELETE_X threshold, each platform
# is deleted only when its FAR END has scrolled past x = -20.
# Far end = position.x + platform_length.
# This prevents the quiz platform (60 units long) from being
# deleted while its panels are still on screen.
# ─────────────────────────────────────────────────────────────

const PLATFORM_COUNT       := 7
const PLATFORM_LENGTH      := 20.0
const QUIZ_PLATFORM_LENGTH := 60.0
const DELETE_X             := -20.0   # far end must pass this to delete
const MOVE_SPEED           := 15.0
const QUIZ_EVERY_N         := 5

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

		# Delete only when the FAR END of the platform is off screen
		var length = _get_platform_length(platform)
		if platform.position.x + length < DELETE_X:
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
		printerr("quiz_platform_scene not assigned — falling back to normal")
		_spawn_normal()
		return
	var p = quiz_platform_scene.instantiate() as Node3D
	if p == null:
		printerr("Failed to instantiate quiz_platform_scene!")
		return
	p.position = Vector3(_next_x(QUIZ_PLATFORM_LENGTH), 0, 0)
	add_child(p)
	platforms.append(p)

func _next_x(incoming_length: float) -> float:
	if platforms.is_empty():
		return 0.0
	var last = platforms.back()
	return last.position.x + _get_platform_length(last)

func _get_platform_length(p: Node3D) -> float:
	if p.get_script() != null:
		var val = p.get("QUIZ_PLATFORM_LENGTH")
		if val != null:
			return float(val)
	return PLATFORM_LENGTH
