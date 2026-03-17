extends Area3D

@export var points := 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("Star ready at ", global_position, " - monitoring: ", monitoring)

func _process(delta: float) -> void:
	rotate_y(delta * 4.0)  # nice spin speed

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):   # ← only player collects (safer)
		print("⭐ Star collected by player! +", points, " at ", global_position)
		collect()

func collect() -> void:
	# Later: Global.score += points  or signal to HUD
	# For now just visual feedback
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.12)
	tween.tween_callback(queue_free)
