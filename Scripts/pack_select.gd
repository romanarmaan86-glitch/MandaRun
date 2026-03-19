extends Control

# pack_select.gd  (Scripts/pack_select.gd)
#
# Scene structure (Scenes/pack_select.tscn):
#   Control (root, this script)
#     Panel
#     Label           (name: TitleLabel,  text: "Choose a Pack")
#     ScrollContainer
#       VBoxContainer (name: PackList)
#     Button          (name: StartBtn,    text: "Start Run")
#     Button          (name: BackBtn,     text: "Back")

@onready var pack_list: VBoxContainer = $ScrollContainer/PackList
@onready var start_btn: Button        = $HBoxContainer/StartBtn
@onready var back_btn:  Button        = $HBoxContainer/BackBtn

var _selected_pack: String = ""

func _ready() -> void:
	_selected_pack = SaveManager.active_pack
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	)
	_populate()
	_update_start_btn()

func _populate() -> void:
	for child in pack_list.get_children():
		child.queue_free()
	for pack in WordPacks.get_all_packs():
		if SaveManager.owns_pack(pack["id"]):
			pack_list.add_child(_make_pack_row(pack))

func _make_pack_row(pack: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Pack info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = pack["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text     = "%d words  •  %s" % [pack["size"], pack["desc"]]
	desc_lbl.modulate = Color(0.75, 0.75, 0.75)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_lbl)

	# Select button
	var select_btn = Button.new()
	var is_selected = (_selected_pack == pack["id"])
	select_btn.text    = "✓ Selected" if is_selected else "Select"
	select_btn.modulate = Color(0.3, 1.0, 0.3) if is_selected else Color.WHITE
	select_btn.pressed.connect(_on_select.bind(pack["id"]))
	hbox.add_child(select_btn)

	return panel

func _on_select(pack_id: String) -> void:
	_selected_pack = pack_id
	SaveManager.set_active_pack(pack_id)
	_populate()   # rebuild to update selected highlight
	_update_start_btn()

func _update_start_btn() -> void:
	start_btn.disabled = _selected_pack.is_empty()

func _on_start() -> void:
	if _selected_pack.is_empty():
		return
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
