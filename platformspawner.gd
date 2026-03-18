extends Node3D

# ─────────────────────────────────────────────────────────────
# platformspawner.gd  (updated)
# Every 5th platform spawned after the grace period is a quiz platform.
# ─────────────────────────────────────────────────────────────

const PLATFORM_COUNT := 7
const PLATFORM_LENGTH := 20.0
const QUIZ_PLATFORM_LENGTH := 60.0   # quiz platforms are 3× longer
const DELETE_X := -20
const MOVE_SPEED := 15.0
const QUIZ_EVERY_N := 5              # one quiz platform per N normal platforms

@export var platform_scene: PackedScene
@export var quiz_platform_scene: PackedScene   # assign quiz_platform.tscn in editor

var platforms: Array[Node3D] = []
var _total_spawned: int = 0   # counts every spawn after _ready (excludes grace)

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
	_total_spawned += 1
	if _total_spawned % QUIZ_EVERY_N == 0:
		_spawn_quiz()
	else:
		_spawn_normal()

func _spawn_normal(_index: int = -1) -> void:
	var p = platform_scene.instantiate() as Node3D
	if p == null:
		printerr("Failed to instantiate platform_scene!")
		return

	p.position = Vector3(_next_x(PLATFORM_LENGTH), 0, 0)
	add_child(p)
	platforms.append(p)

	var obs_spawner = get_parent().get_node_or_null("obstaclespawner")
	if obs_spawner:
		obs_spawner.spawn_obstacle(p)

func _spawn_quiz() -> void:
	if quiz_platform_scene == null:
		printerr("platformspawner: quiz_platform_scene not assigned! Spawning normal platform.")
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

func _next_x(_length: float) -> float:
	if platforms.size() > 0:
		# Account for variable-length platforms by using last platform's x + its length
		var last = platforms.back()
		# Try to read the length from the platform itself if it exposes it,
		# otherwise fall back to a stored value
		return last.position.x + _get_platform_length(last)
	return 0.0

func _get_platform_length(p: Node3D) -> float:
	# Quiz platforms expose a const; normal ones use PLATFORM_LENGTH
	if p.get_script() != null and p.get("QUIZ_PLATFORM_LENGTH") != null:
		return QUIZ_PLATFORM_LENGTH
	return PLATFORM_LENGTH
