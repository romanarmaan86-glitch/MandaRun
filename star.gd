extends Area3D

@export var points := 10

func _ready():
	# Connect in code to be sure (safer than editor sometimes)
	body_entered.connect(_on_body_entered)
	# Debug: print when ready
	print("Star ready at ", global_position, " - monitoring: ", monitoring)

func _process(delta: float):
	rotate_y(delta * 4.0)  # spin

func _on_body_entered(body: Node3D):
	print("Something entered star! Body: ", body.name, " | Class: ", body.get_class())
	# Temporarily collect on ANY body – remove this check later
	collect()
	# Or stricter: if body.is_in_group("player") or body.name == "Player":
	#     collect()

func collect():
	print("⭐ Star collected! +", points)
	# Add your score here later, e.g. Global.score += points
	queue_free()
