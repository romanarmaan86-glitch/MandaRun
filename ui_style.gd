extends Node

# ─────────────────────────────────────────────────────────────
# UIStyle — Autoload singleton  (Scripts/ui_style.gd)
# Add to Autoloads as "UIStyle" (above everything else)
#
# Central style constants and factory helpers used by every UI scene.
# ─────────────────────────────────────────────────────────────

# ── Colours ──
const BG            = Color(0.08, 0.08, 0.12)
const CARD          = Color(0.14, 0.14, 0.22)
const CARD_SELECTED = Color(0.18, 0.30, 0.45)
const ACCENT        = Color(1.00, 0.90, 0.30)   # star yellow
const TEXT          = Color(1.00, 1.00, 1.00)
const TEXT_DIM      = Color(0.70, 0.70, 0.70)
const TEXT_DARK     = Color(0.35, 0.35, 0.35)
const GREEN         = Color(0.20, 0.90, 0.30)
const RED           = Color(0.90, 0.20, 0.20)

# ── Font sizes ──
const FS_TITLE   = 32
const FS_HEADING = 22
const FS_BODY    = 18
const FS_SUB     = 14
const FS_SMALL   = 12

# ── Custom font (used for titles) ──
const TITLE_FONT_PATH = "res://Some Time Later.otf"

# ─────────────────────────────────────────────────────────────
# Style factories

func card_style(selected: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = CARD_SELECTED if selected else CARD
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left   = 16
	s.content_margin_right  = 16
	s.content_margin_top    = 12
	s.content_margin_bottom = 12
	return s

func button_style(color: Color = Color(0.20, 0.20, 0.35)) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left   = 20
	s.content_margin_right  = 20
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	return s

func button_hover_style() -> StyleBoxFlat:
	return button_style(Color(0.28, 0.28, 0.48))

func button_pressed_style() -> StyleBoxFlat:
	return button_style(Color(0.14, 0.14, 0.28))

# ─────────────────────────────────────────────────────────────
# Node factories

func make_bg(parent: Control) -> void:
	var bg = ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)

func make_title(text: String, parent: Control, y: float = 24.0) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", FS_TITLE)
	lbl.add_theme_font_override("font", load(TITLE_FONT_PATH))  # ← custom font
	lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl.position = Vector2(-200, y)
	lbl.custom_minimum_size = Vector2(400, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

func make_label(text: String, size: int = FS_BODY, color: Color = TEXT) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", size)
	return lbl

func make_button(text: String, font_size: int = FS_BODY) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal",  button_style())
	btn.add_theme_stylebox_override("hover",   button_hover_style())
	btn.add_theme_stylebox_override("pressed", button_pressed_style())
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color",               TEXT)
	btn.add_theme_color_override("font_hover_color",         TEXT)
	btn.add_theme_color_override("font_pressed_color",       TEXT)
	btn.add_theme_color_override("font_focus_color",         TEXT)
	return btn

func make_scroll(parent: Control,
		top: float = 110, bottom: float = -70,
		left: float = 20, right: float = -20) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top    = top
	scroll.offset_bottom = bottom
	scroll.offset_left   = left
	scroll.offset_right  = right
	parent.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	return vbox

func make_back_button(parent: Control, target_scene: String) -> Button:
	var btn = make_button("← Back")
	btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn.offset_left   = 20
	btn.offset_top    = -60
	btn.offset_right  = 180
	btn.offset_bottom = -10
	btn.pressed.connect(func():
		parent.get_tree().change_scene_to_file(target_scene)
	)
	parent.add_child(btn)
	return btn
