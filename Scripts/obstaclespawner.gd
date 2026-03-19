extends Node3D

# ────────────────────────────────────────────────

const LANES: Array[float] = [-1.5, 0.0, 1.5]

const EVADE_GAP: float = 7.5

@export var obstacle_scene: PackedScene
@export var star_scene: PackedScene
@export var spawn_chance: float = 0.95  # overridden by difficulty at run start

const JUMP_OVER_SIZE: Vector3 = Vector3(1.0, 0.5, 0.5)
const SLIDE_UNDER_SIZE: Vector3 = Vector3(1.0, 0.5, 0.5)
const EVADE_SIZE: Vector3 = Vector3(2.5, 2.0, 0.6)

var last_single_free_lane: int = -1

func _ready() -> void:
	if QuizManager.has_meta("spawn_chance"):
		spawn_chance = QuizManager.get_meta("spawn_chance")

const GRACE_PLATFORMS: int = 3
var platforms_seen: int = 0

# ────────────────────────────────────────────────

func spawn_obstacle(platform: Node3D) -> void:
	platforms_seen += 1

	if platforms_seen <= GRACE_PLATFORMS:
		last_single_free_lane = -1
		return

	if randf() > spawn_chance:
		last_single_free_lane = -1
		return

	# === SECTION 1 (front) ===
	var section1_x = 4.0
	var result1 = spawn_section(platform, section1_x)
	spawn_star(platform, section1_x, result1)

	# === SECTION 2 (back) with exact 7.5 evade gap ===
	var section2_x = 4.0 + EVADE_GAP
	var result2 = spawn_section(platform, section2_x)
	spawn_star(platform, section2_x, result2)

# ────────────────────────────────────────────────
# Returns a Dictionary with:
#   "free":  Array[int]  — lanes with no obstacle (always safe)
#   "jump":  Array[int]  — lanes with a jump-over obstacle (star goes high)
#   "slide": Array[int]  — lanes with a slide-under obstacle (star goes low)

func spawn_section(platform: Node3D, section_x: float) -> Dictionary:
	var r = randf()
	var num_free = 1 if r < 0.7 else (2 if r < 0.9 else 3)

	var free_lanes: Array[int] = []

	if last_single_free_lane != -1:
		var preferred = (last_single_free_lane + 1) % 3
		free_lanes.append(preferred)

	var candidates = [0, 1, 2]
	for f in free_lanes:
		candidates.erase(f)

	while free_lanes.size() < num_free and not candidates.is_empty():
		var idx = randi() % candidates.size()
		free_lanes.append(candidates[idx])
		candidates.remove_at(idx)

	# Spawn obstacles in blocked lanes, track type per lane
	var jump_lanes: Array[int] = []
	var slide_lanes: Array[int] = []

	for lane_idx in [0, 1, 2]:
		if not free_lanes.has(lane_idx):
			var typ = randi() % 3
			spawn_helper(platform, typ, LANES[lane_idx], section_x)
			if typ == 0:
				jump_lanes.append(lane_idx)
			elif typ == 1:
				slide_lanes.append(lane_idx)
			# typ == 2 (evade) → not added, remains blocked

	if free_lanes.size() == 1:
		last_single_free_lane = free_lanes[0]
	else:
		last_single_free_lane = -1

	return { "free": free_lanes, "jump": jump_lanes, "slide": slide_lanes }

# ────────────────────────────────────────────────

func spawn_star(platform: Node3D, x_offset: float, section: Dictionary) -> void:
	if not star_scene:
		return

	# Build list of all "safe" lanes with their appropriate Y heights
	# free lane  → y = 1.2 (normal floating height)
	# jump lane  → y = 1.5 (above the low obstacle, reachable at jump apex)
	# slide lane → y = 0.3 (low, reachable while sliding under)
	var safe: Array = []  # Array of [lane_idx, y]

	for lane_idx in section["free"]:
		safe.append([lane_idx, 1.2])
	for lane_idx in section["jump"]:
		safe.append([lane_idx, 1.5])
	for lane_idx in section["slide"]:
		safe.append([lane_idx, 0.3])

	if safe.is_empty():
		return

	var chosen = safe[randi() % safe.size()]
	var star = star_scene.instantiate()
	star.position = Vector3(x_offset, chosen[1], LANES[chosen[0]])
	platform.add_child(star)

# ────────────────────────────────────────────────

func spawn_helper(platform: Node3D, type_idx: int, lane_z: float, x_offset: float) -> void:
	var obs = obstacle_scene.instantiate()
	if not obs: return

	obs.set("obstacle_type", type_idx)

	var size: Vector3
	match type_idx:
		0: size = JUMP_OVER_SIZE
		1: size = SLIDE_UNDER_SIZE
		2: size = EVADE_SIZE
		_: size = Vector3.ONE

	var y: float
	match type_idx:
		0: y = size.y / 2.0 - 0.12
		1: y = 1.2
		2: y = size.y / 2.0
		_: y = size.y / 2.0

	obs.position = Vector3(x_offset, y, lane_z)

	var mesh = obs.get_node_or_null("MeshInstance3D")
	if mesh:
		var box = BoxMesh.new()
		box.size = size
		mesh.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.98, 0.18, 0.18) if type_idx == 0 else \
			Color(0.18, 0.45, 0.98) if type_idx == 1 else \
			Color(0.98, 0.88, 0.12)
		mesh.material_override = mat

	var col = obs.get_node_or_null("Area3D/CollisionShape3D")
	if col:
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape

	platform.add_child(obs)
