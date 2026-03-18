extends Area3D

# star.gd  (Scripts/star.gd)

@export var points := 1   # changed from 10 to 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(delta * 4.0)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	QuizManager.stars_collected += points
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3(1.8, 1.8, 1.8), 0.12)
	tween.tween_callback(queue_free)
