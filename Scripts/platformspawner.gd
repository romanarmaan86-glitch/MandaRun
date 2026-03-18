extends Node3D

# platformspawner.gd  (Scripts/platformspawner.gd)

const PLATFORM_COUNT       := 7
const PLATFORM_LENGTH      := 20.0
const QUIZ_PLATFORM_LENGTH := 60.0
const DELETE_X             := -20.0
const QUIZ_EVERY_N         := 8

@export var platform_scene: PackedScene
@export var quiz_platform_scene: PackedScene

var platforms: Array[Node3D] = []
var _spawned_after_grace: int = 0

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	for i in PLATFORM_COUNT:
		_spawn_normal(i)

func _physics_process(delta: float) -> void:
	var speed: float = QuizManager.move_speed if QuizManager.get("move_speed") != null else 15.0

	for platform in platforms.duplicate():
		if platform == null or not is_instance_valid(platform):
			platforms.erase(platform)
			continue
		platform.position.x -= speed * delta
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
	p.set_meta("platform_length", PLATFORM_LENGTH)
	add_child(p)
	platforms.append(p)

	# Restore speed when the next platform spawns after a wrong answer
	if QuizManager.get("speed_penalised") and QuizManager.speed_penalised:
		QuizManager.move_speed      = QuizManager.base_move_speed
		QuizManager.speed_penalised = false

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
	p.set_meta("platform_length", QUIZ_PLATFORM_LENGTH)
	add_child(p)
	platforms.append(p)

func _next_x(incoming_length: float) -> float:
	if platforms.is_empty():
		return 0.0
	var last = platforms.back()
	return last.position.x + _get_platform_length(last)

func _get_platform_length(p: Node3D) -> float:
	if p.has_meta("platform_length"):
		return p.get_meta("platform_length")
	return PLATFORM_LENGTH
