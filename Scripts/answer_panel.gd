extends Area3D

# ─────────────────────────────────────────────────────────────
# answer_panel.gd
# Attach to an Area3D node inside quiz_platform.tscn.
# Each panel sits in one lane and shows one answer option.
#
# Scene structure expected:
#   AnswerPanel (Area3D)  ← this script
#     CollisionShape3D    (BoxShape3D, thin slab ~0.1 deep)
#     MeshInstance3D      (flat panel, visual)
#     Label3D             (answer text)
# ─────────────────────────────────────────────────────────────

@export var lane_index: int = 0   # Set in quiz_platform.gd when spawning

@onready var label: Label3D = $Label3D

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_answer_text(text: String) -> void:
	if label:
		label.text = text

func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true
	QuizManager.submit_answer(lane_index)
