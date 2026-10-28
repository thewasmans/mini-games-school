class_name UIStyle
extends RefCounted
## Palette, police et thème « cartoon » (boutons épais, texte blanc cerné de bleu nuit).

const BLUE := Color("3b8cff")
const ORANGE := Color("ff9f1c")
const GREEN := Color("4cc44a")
const PURPLE := Color("b05ce0")
const YELLOW := Color("ffc928")
const RED := Color("ff4d5a")
const GREY := Color("8a93a6")
const CYAN := Color("35d0ff")
const GOLD := Color("ffb43b")
const INK := Color("101a4a")
const PANEL := Color("2346a8")
const PANEL_DARK := Color("162d78")
const SUBJECT_COLORS: Array[Color] = [Color("3b8cff"), Color("ff9f1c"), Color("4cc44a"), Color("b05ce0"), Color("ff5d8f"), Color("1fc6b4")]
const STUDY_COLORS: Array[Color] = [Color("ff9f1c"), Color("4cc44a"), Color("b05ce0")]

static var _font: Font
static var _theme: Theme


static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Lilita One", "Baloo 2", "Fredoka One", "Segoe UI Black", "Arial Rounded MT Bold", "Arial Black", "Sans-Serif"])
		f.font_weight = 900
		_font = f
	return _font


static func box(color: Color, radius := 20, depth := 0, border := 0, border_color := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	var edge := border_color if border_color.a > 0 else color.darkened(0.4)
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.border_width_bottom = border + depth
	return sb


## Panneau bleu « carte de jeu » avec épaisseur et ombre.
static func panel_box(color := PANEL, radius := 26) -> StyleBoxFlat:
	var sb := box(color, radius, 8, 4, PANEL_DARK.darkened(0.2))
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(22)
	sb.content_margin_bottom = 28
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 28
	for type in ["Label", "Button", "CheckBox"]:
		t.set_color("font_color", type, Color.WHITE)
		t.set_color("font_outline_color", type, INK)
		t.set_constant("outline_size", type, 10)
		t.set_color("font_shadow_color", type, Color(0, 0, 0, 0.3))
		t.set_constant("shadow_offset_x", type, 0)
		t.set_constant("shadow_offset_y", type, 3)
		t.set_constant("shadow_outline_size", type, 10)
	for state in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.8))
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var grabber := box(Color(1, 1, 1, 0.35), 6)
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	t.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	var track := box(Color(0, 0, 0, 0.15), 6)
	track.content_margin_left = 6
	track.content_margin_right = 6
	t.set_stylebox("scroll", "VScrollBar", track)
	_theme = t
	return t


static func label(text: String, size := 28, color := Color.WHITE, outline := 10) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Bannière de titre façon ruban.
static func banner(text: String, color := BLUE, size := 40) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(color, 22, 8, 4, color.darkened(0.45))
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 10
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text, size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p


## Petite pastille arrondie (compteur, tag).
static func pill(text: String, color := PANEL_DARK, size := 22) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(color, 40)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(label(text, size, Color.WHITE, 6))
	return p


static func ellipse(center: Vector2, radius: Vector2, steps := 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * i / steps
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return pts


static func star(center: Vector2, outer: float, inner: float, rotation := -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var r := outer if i % 2 == 0 else inner
		var a := rotation + TAU * i / 10.0
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


## Texte centré cerné, dessiné dans un _draw().
static func draw_text(ci: CanvasItem, text: String, center: Vector2, size: int, color := Color.WHITE, outline := 0, outline_color := INK) -> void:
	if size <= 0 or text.is_empty():
		return
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center.x - w / 2.0, center.y + (f.get_ascent(size) - f.get_descent(size)) / 2.0)
	if outline > 0:
		ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_color)
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
