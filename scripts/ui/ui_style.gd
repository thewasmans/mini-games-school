class_name UIStyle
extends RefCounted
## Direction artistique : palette, accès au thème du projet, fabriques de labels / pastilles / bannières.
## Les styles (boutons, panneaux, sprites) sont dans le thème Godot assets/ui/game_theme.tres.

const BLUE := Color("3d84f2")
const ORANGE := Color("ff9a1f")
const PINK := Color("d94fc4")
const GREEN := Color("4cc24a")
const PURPLE := Color("a855e0")
const YELLOW := Color("ffd23f")
const RED := Color("ff4d5a")
const GREY := Color("8a93a6")
const CYAN := Color("4fe0ff")
const GOLD := Color("ffb43b")
const INK := Color("13235e")
const PANEL := Color("2c62d9")
const PANEL_DARK := Color("1a2d6e")
const FRAME_LIGHT := Color("7cc0ff")
const SUBJECT_COLORS: Array[Color] = [Color("3d84f2"), Color("ff9a1f"), Color("4cc24a"), Color("a855e0"), Color("ff5d8f"), Color("1fc6b4")]
const STUDY_COLORS: Array[Color] = [Color("ff9a1f"), Color("4cc24a"), Color("a855e0")]
const STUDY_ICONS := [["book", "pencil"], ["compass", "ruler"], ["scroll", "microscope"]]

const THEME_PATH := "res://assets/ui/game_theme.tres"

static var _theme: Theme


## Thème du projet (assets/ui/game_theme.tres, généré par tools/build_theme.gd).
static func theme() -> Theme:
	if _theme == null:
		_theme = ThemeDB.get_project_theme()
		if _theme == null:
			_theme = load(THEME_PATH)
	return _theme


static func font() -> Font:
	return theme().default_font


## StyleBoxFlat arrondi, pour les éléments dessinés à la main (jauges, ruban) et le générateur de thème.
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


## PanelContainer avec une variation du thème (PanelFrame, PanelTitled, PanelInner, PanelBig, PanelGlass…).
static func panel(variation: StringName) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


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


## Bannière de titre (pilule bleue brillante).
static func banner(text: String, color := BLUE, size := 40, text_color := Color.WHITE) -> Banner:
	return Banner.new(text, color, size, text_color)


## Petite pastille arrondie (compteur, tag) : variation Pill ou PillBlue.
static func pill(text: String, size := 22, variation := &"Pill") -> PanelContainer:
	var p := panel(variation)
	p.add_child(label(text, size, Color.WHITE, 6))
	return p


static func ellipse(center: Vector2, radius: Vector2, steps := 40) -> PackedVector2Array:
	return UIDraw.ellipse(center, radius, steps)


static func star(center: Vector2, outer: float, inner: float, rotation := -PI / 2) -> PackedVector2Array:
	return UIDraw.star_points(center, outer, inner, 5, rotation)


## Texte centré cerné (avec ombre), dessiné dans un _draw().
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


## Bannière de titre : PanelContainer avec la variation Banner<Couleur> du thème.
class Banner extends PanelContainer:
	var color: Color
	var _label: Label

	func _init(text: String, color_: Color, size: int, text_color: Color) -> void:
		color = color_
		theme_type_variation = "Banner" + UISkin.color_name(color)
		_label = UIStyle.label(text, size, text_color, maxi(6, size / 4))
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_label)

	func set_text(t: String) -> void:
		_label.text = t
