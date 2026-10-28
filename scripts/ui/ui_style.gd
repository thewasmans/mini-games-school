class_name UIStyle
extends RefCounted
## Direction artistique : palette, police Fredoka, thème et panneaux (cadre bleu lumineux,
## intérieur bleu nuit, verre), d'après les maquettes du jeu.

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

static var _font: Font
static var _theme: Theme


static func font() -> Font:
	if _font == null:
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/Fredoka.ttf")
		var ts := TextServerManager.get_primary_interface()
		fv.variation_opentype = {ts.name_to_tag("wght"): 650}
		_font = fv
	return _font


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


## Cadre bleu à liseré clair et halo (panneaux « Clue », question du quiz).
static func frame_box(color := PANEL, radius := 26) -> StyleBoxFlat:
	var sb := box(color, radius, 0, 4, FRAME_LIGHT)
	sb.border_width_bottom = 6
	sb.shadow_color = Color(0.45, 0.75, 1.0, 0.45)
	sb.shadow_size = 12
	sb.set_content_margin_all(16)
	return sb


## Intérieur bleu nuit d'un cadre (liste d'indices, phrase du cryptogramme).
static func inner_box(radius := 18) -> StyleBoxFlat:
	var sb := box(PANEL_DARK, radius, 0, 2, Color("0f1d52"))
	sb.set_content_margin_all(14)
	return sb


## Grand conteneur bleu nuit translucide à bord lumineux (menu des niveaux).
static func container_box() -> StyleBoxFlat:
	var sb := box(Color(0.1, 0.17, 0.45, 0.88), 30, 0, 5, Color("4f8fff"))
	sb.shadow_color = Color(0.35, 0.65, 1.0, 0.55)
	sb.shadow_size = 16
	sb.set_content_margin_all(26)
	return sb


## Verre dépoli (clavier).
static func glass_box() -> StyleBoxFlat:
	var sb := box(Color(0.85, 0.9, 1.0, 0.22), 24, 0, 2, Color(1, 1, 1, 0.5))
	sb.set_content_margin_all(12)
	return sb


## Gardé pour compatibilité : panneau = cadre bleu.
static func panel_box(color := PANEL, radius := 26) -> StyleBoxFlat:
	return frame_box(color, radius)


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
		t.set_color("font_shadow_color", type, Color(0.02, 0.05, 0.2, 0.45))
		t.set_constant("shadow_offset_x", type, 0)
		t.set_constant("shadow_offset_y", type, 3)
		t.set_constant("shadow_outline_size", type, 10)
	t.set_stylebox("panel", "PanelContainer", frame_box())
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
	l.add_theme_constant_override("shadow_outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Bannière de titre (pilule bleue brillante).
static func banner(text: String, color := BLUE, size := 40, text_color := Color.WHITE) -> Banner:
	return Banner.new(text, color, size, text_color)


## Petite pastille arrondie (compteur, tag).
static func pill(text: String, color := PANEL_DARK, size := 22) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(color, 40, 0, 2, color.lightened(0.25))
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
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


## Bannière dessinée à la main : dégradé, bord sombre en bas, liseré clair, reflet.
class Banner extends PanelContainer:
	var color: Color
	var _label: Label

	func _init(text: String, color_: Color, size: int, text_color: Color) -> void:
		color = color_
		var sb := StyleBoxEmpty.new()
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		sb.content_margin_top = 10
		sb.content_margin_bottom = 18
		add_theme_stylebox_override("panel", sb)
		_label = UIStyle.label(text, size, text_color, maxi(6, size / 4))
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_theme_color_override("font_outline_color", color.darkened(0.6))
		_label.add_theme_color_override("font_outline_color", UIStyle.INK)
		add_child(_label)

	func set_text(t: String) -> void:
		_label.text = t

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var rad := minf(28.0, size.y / 2.0)
		UIDraw.rrect(self, Rect2(0, 6, size.x, size.y - 4), rad, Color(0, 0, 0, 0.3))
		UIDraw.rrect(self, r, rad, color.darkened(0.45))
		var face := Rect2(0, 0, size.x, size.y - 8)
		UIDraw.rrect(self, face, rad, color.lightened(0.18), color.darkened(0.05), UIStyle.FRAME_LIGHT.lerp(color.lightened(0.5), 0.5), 3.0)
		UIDraw.rrect(self, Rect2(10, 5, size.x - 20, face.size.y * 0.4), rad * 0.7, Color(1, 1, 1, 0.25), Color(1, 1, 1, 0.05))
