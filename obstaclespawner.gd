extends Node3D

# ────────────────────────────────────────────────
const LANES: Array[float] = [-1.5, 0.0, 1.5]
const EVADE_GAP: float = 7.5

@export var obstacle_scene: PackedScene
@export var star_scene: PackedScene
@export var spawn_chance: float = 0.95

const JUMP_OVER_SIZE: Vector3   = Vector3(1.0, 0.5, 0.5)
const SLIDE_UNDER_SIZE: Vector3 = Vector3(1.0, 0.5, 0.5)
const EVADE_SIZE: Vector3       = Vector3(2.5, 2.0, 0.6)

var last_single_free_lane: int = -1

# ────────────────────────────────────────────────
func spawn_obstacle(platform: Node3D) -> void:
	if randf() > spawn_chance:
		last_single_free_lane = -1
		return

	# === SECTION 1 (front) ===
	var section1_x = 4.0
	var free1 = spawn_section(platform, section1_x)
	spawn_star(platform, section1_x, free1)

	# === SECTION 2 (back) with exact 7.5 evade gap ===
	var section2_x = 4.0 + EVADE_GAP
	var free2 = spawn_section(platform, section2_x)
	spawn_star(platform, section2_x, free2)

# ────────────────────────────────────────────────
func spawn_section(platform: Node3D, section_x: float) -> Array[int]:
	var r = randf()
	var num_free = 1 if r < 0.5 else (2 if r < 0.9 else 3)

	var free_lanes: Array[int] = []

	# Smart flow from previous single-free section
	if last_single_free_lane != -1:
		var preferred = (last_single_free_lane + 1) % 3
		free_lanes.append(preferred)

	# Fill remaining lanes randomly
	var candidates = [0, 1, 2]
	for f in free_lanes:
		candidates.erase(f)
	while free_lanes.size() < num_free and not candidates.is_empty():
		var idx = randi() % candidates.size()
		free_lanes.append(candidates[idx])
		candidates.remove_at(idx)

	# Spawn obstacles only in blocked lanes
	for lane_idx in [0, 1, 2]:
		if not free_lanes.has(lane_idx):
			var typ = randi() % 3
			spawn_helper(platform, typ, LANES[lane_idx], section_x)

	# Remember for next section flow
	if free_lanes.size() == 1:
		last_single_free_lane = free_lanes[0]
	else:
		last_single_free_lane = -1

	return free_lanes

# ────────────────────────────────────────────────
func spawn_star(platform: Node3D, x_offset: float, free_lanes: Array[int]) -> void:
	if free_lanes.is_empty() or not star_scene:
		return
	var chosen = free_lanes[randi() % free_lanes.size()]
	var star = star_scene.instantiate()
	star.position = Vector3(x_offset, 1.2, LANES[chosen])  # ← now in safe lane!
	platform.add_child(star)

# ────────────────────────────────────────────────
# (keep your original spawn_helper exactly the same)
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

	# Visual + collision (same as your original)
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
	# ... your exact same code from before (mesh, material, collision, etc.)
	# (I didn't change anything here so nothing breaks)
	pass  # ← paste your full spawn_helper here
