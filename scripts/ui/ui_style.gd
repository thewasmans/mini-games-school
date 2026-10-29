@tool
class_name UIStyle
extends RefCounted

const BLUE := Color("3d84f2")
const GREEN := Color("4cc24a")
const PURPLE := Color("a855e0")
const YELLOW := Color("ffd23f")
const RED := Color("ff4d5a")
const GOLD := Color("ffb43b")
const INK := Color("13235e")
const PANEL := Color("2c62d9")
const PANEL_DARK := Color("1a2d6e")
const FRAME_LIGHT := Color("7cc0ff")

const THEME_PATH := "res://content/ui/game_theme.tres"

static var _theme: Theme


static func theme() -> Theme:
	if _theme == null:
		_theme = ThemeDB.get_project_theme()
		if _theme == null:
			_theme = load(THEME_PATH)
	return _theme


static func font() -> Font:
	return theme().default_font


static func box(color: Color, radius := 20, depth := 0, border := 0, border_color := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	sb.border_color = border_color if border_color.a > 0 else color.darkened(0.4)
	sb.set_border_width_all(border)
	sb.border_width_bottom = border + depth
	return sb


static func label(text: String, size := 28, color := Color.WHITE, outline := 10) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_constant_override("shadow_outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func star(center: Vector2, outer: float, inner: float, rotation := -PI / 2) -> PackedVector2Array:
	return UIDraw.star_points(center, outer, inner, 5, rotation)


static func draw_text(ci: CanvasItem, text: String, center: Vector2, size: int, color := Color.WHITE, outline := 0, outline_color := INK) -> void:
	if size <= 0 or text.is_empty():
		return
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center.x - w / 2.0, center.y + (f.get_ascent(size) - f.get_descent(size)) / 2.0)
	if outline > 0:
		ci.draw_string_outline(f, pos + Vector2(0, size * 0.08), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0.02, 0.05, 0.2, 0.4))
		ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_color)
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
