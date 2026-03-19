extends Control

# ─────────────────────────────────────────────────────────────
# word_packs_scene.gd  (Scripts/word_packs_scene.gd)
#
# Builds the entire UI in code so it works regardless of what
# nodes exist in the tscn. The tscn only needs a root Control
# with this script attached — nothing else required.
# ─────────────────────────────────────────────────────────────

var _stars_label: Label
var _pack_list:   VBoxContainer

func _ready() -> void:
	_build_ui()
	_populate()

func _build_ui() -> void:
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "Word Packs"
	title.add_theme_font_size_override("font_size", 32)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-100, 20)
	title.custom_minimum_size = Vector2(200, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Stars balance
	_stars_label = Label.new()
	_stars_label.add_theme_font_size_override("font_size", 18)
	_stars_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_stars_label.position = Vector2(-100, 70)
	_stars_label.custom_minimum_size = Vector2(200, 30)
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_label.modulate = Color(1.0, 0.9, 0.3)
	add_child(_stars_label)

	# Scroll container
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = 110
	scroll.offset_bottom = -70
	scroll.offset_left   = 20
	scroll.offset_right  = -20
	add_child(scroll)

	_pack_list = VBoxContainer.new()
	_pack_list.add_theme_constant_override("separation", 12)
	_pack_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_pack_list)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.offset_left   = 20
	back_btn.offset_top    = -60
	back_btn.offset_right  = 160
	back_btn.offset_bottom = -10
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/words_hub.tscn")
	)
	add_child(back_btn)

func _populate() -> void:
	# Clear existing rows
	for child in _pack_list.get_children():
		child.queue_free()

	_stars_label.text = "⭐ %d stars" % SaveManager.total_stars

	var packs = WordPacks.get_all_packs()
	if packs.is_empty():
		var lbl = Label.new()
		lbl.text = "No packs available."
		_pack_list.add_child(lbl)
		return

	for pack in packs:
		_pack_list.add_child(_make_pack_row(pack))

func _make_pack_row(pack: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Left: pack info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = pack["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text     = pack["desc"]
	desc_lbl.modulate = Color(0.75, 0.75, 0.75)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_lbl)

	var size_lbl = Label.new()
	size_lbl.text     = "%d words" % pack["size"]
	size_lbl.modulate = Color(0.6, 0.6, 0.6)
	size_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(size_lbl)

	# Right: owned badge or buy button
	var owned = SaveManager.owns_pack(pack["id"])
	if owned:
		var badge = Label.new()
		badge.text                 = "✓ Owned"
		badge.modulate             = Color(0.3, 1.0, 0.3)
		badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 16)
		hbox.add_child(badge)
	else:
		var buy_btn    = Button.new()
		var can_afford = SaveManager.total_stars >= pack["price"]
		buy_btn.text     = "⭐ %d" % pack["price"]
		buy_btn.disabled = not can_afford
		buy_btn.modulate = Color(1, 1, 1) if can_afford else Color(0.5, 0.5, 0.5)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.pressed.connect(_on_buy_pressed.bind(pack["id"], pack["price"]))
		hbox.add_child(buy_btn)

	return panel

func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color            = Color(0.14, 0.14, 0.22)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 16
	style.content_margin_right  = 16
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	return style

func _on_buy_pressed(pack_id: String, price: int) -> void:
	var success = SaveManager.buy_pack(pack_id, price)
	if success:
		_populate()
	else:
		# Flash stars label red — not enough stars
		_stars_label.modulate = Color(1.0, 0.3, 0.3)
		await get_tree().create_timer(0.6).timeout
		_stars_label.modulate = Color(1.0, 0.9, 0.3)
