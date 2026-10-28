class_name JuicyButton
extends Button
## Bouton épais façon jeu mobile : dégradé, liseré clair, bord sombre, reflet, étincelles,
## icônes vectorielles, écrasement à l'appui et rebond élastique.
## Le texte est dessiné à la main (le texte natif sert seulement au calcul de taille).

var sound := "click"
## Icône seule au centre (bouton sans texte) : voir UIDraw.icon().
var icon_kind := "":
	set(value):
		icon_kind = value
		_apply_margins()
var icon_left := "":
	set(value):
		icon_left = value
		_apply_margins()
var icon_right := "":
	set(value):
		icon_right = value
		_apply_margins()
var color: Color = UIStyle.BLUE:
	set(value):
		color = value
		_skin_style = null
		queue_redraw()
## Skin bitmap (assets/ui) : vide = le plus proche de `color`, "none" = dessin vectoriel.
var skin := "":
	set(value):
		skin = value
		_skin_style = null
		queue_redraw()
## Couleur du bas du dégradé. Transparent = dérivée de `color`.
var color_bottom := Color(0, 0, 0, 0):
	set(value):
		color_bottom = value
		queue_redraw()
var text_color := Color.WHITE
## Contour du texte : -1 = automatique, 0 = aucun.
var text_outline := -1
var padding := 22:
	set(value):
		padding = value
		_apply_margins()
var depth := 9.0
var radius := 24.0
var sparkles := false:
	set(value):
		sparkles = value
		_update_process()
var shine := false

var _t := 0.0
var _shine_t := 0.0
var _scale_tween: Tween
var _skin_style: StyleBoxTexture


func _init(text_ := "", color_ := UIStyle.BLUE, font_size := 30) -> void:
	text = text_
	color = color_
	focus_mode = FOCUS_NONE
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color",
			"font_disabled_color", "font_outline_color", "font_shadow_color"]:
		add_theme_color_override(c, Color(0, 0, 0, 0))
	add_theme_constant_override("outline_size", 0)
	add_theme_constant_override("shadow_outline_size", 0)
	_apply_margins()


func _ready() -> void:
	pivot_offset = size / 2
	resized.connect(func() -> void: pivot_offset = size / 2)
	button_down.connect(func() -> void: _tween_scale(Vector2(0.92, 0.88), 0.08, Tween.TRANS_QUAD))
	button_up.connect(func() -> void: _tween_scale(Vector2.ONE, 0.5, Tween.TRANS_ELASTIC))
	mouse_entered.connect(func() -> void:
		if not disabled:
			_tween_scale(Vector2(1.04, 1.04), 0.25, Tween.TRANS_BACK))
	mouse_exited.connect(func() -> void: _tween_scale(Vector2.ONE, 0.25, Tween.TRANS_BACK))
	pressed.connect(func() -> void: Sfx.play(sound))
	_update_process()


func set_shine(on: bool) -> void:
	shine = on
	_update_process()


func _update_process() -> void:
	set_process(shine or sparkles)


func _process(delta: float) -> void:
	_t += delta
	_shine_t = fmod(_shine_t + delta, 2.8)
	queue_redraw()


func _tween_scale(target: Vector2, duration: float, trans: Tween.TransitionType) -> void:
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target, duration).set_trans(trans).set_ease(Tween.EASE_OUT)


func _get_skin_style() -> StyleBoxTexture:
	if skin == "none":
		return null
	if _skin_style == null:
		var name := skin if skin != "" else UISkin.button_for(color)
		_skin_style = UISkin.style(name)
	return _skin_style


func _icon_size() -> float:
	return get_theme_font_size("font_size") * 1.5


func _apply_margins() -> void:
	var sb := StyleBoxEmpty.new()
	var icon_w := _icon_size() + 8
	sb.content_margin_left = padding + (icon_w if icon_left != "" else 0.0)
	sb.content_margin_right = padding + (icon_w if icon_right != "" else 0.0)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12 + depth
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, sb)
	queue_redraw()


func _draw() -> void:
	var mode := get_draw_mode()
	var is_down := mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	var hover := mode == DRAW_HOVER
	var d := 3.0 if is_down else depth
	var off := depth - d
	var top := color.lightened(0.2 + (0.06 if hover else 0.0))
	var bottom := color_bottom if color_bottom.a > 0 else color.darkened(0.08)
	if hover and color_bottom.a > 0:
		bottom = bottom.lightened(0.06)
	var edge := bottom.darkened(0.45)
	var face := Rect2(0, off, size.x, size.y - depth)

	# Bouton-icône entièrement dessiné par un sprite (retour, réglages).
	var sprite_name: String = UISkin.BUTTON_SPRITES.get(icon_kind, "") if text == "" else ""
	var sprite := UISkin.tex(sprite_name) if sprite_name != "" else null
	if sprite != null:
		var r := Rect2(0, off * 0.5, size.x, size.y - off * 0.5)
		draw_texture_rect(sprite, r, false, Color(1.08, 1.08, 1.08) if hover else Color.WHITE)
		if icon_kind == "sound_off":
			draw_line(r.position + r.size * 0.22, r.position + r.size * 0.72, UIStyle.INK, size.x * 0.13, true)
			draw_line(r.position + r.size * 0.22, r.position + r.size * 0.72, Color("ff4d5a"), size.x * 0.07, true)
		return

	var skin_style := _get_skin_style()
	UIDraw.rrect(self, Rect2(3, 7, size.x - 6, size.y - 3), radius, Color(0.02, 0.05, 0.2, 0.3))
	if skin_style != null:
		skin_style.modulate_color = Color(1.1, 1.1, 1.1) if hover else Color.WHITE
		draw_style_box(skin_style, Rect2(0, off, size.x, size.y - off))
	else:
		UIDraw.rrect(self, Rect2(0, off, size.x, size.y - off), radius, edge)
		UIDraw.rrect(self, face, radius, top, bottom, top.lightened(0.4), 2.5)
		UIDraw.rrect(self, Rect2(9, off + 5, size.x - 18, face.size.y * 0.42), radius * 0.7, Color(1, 1, 1, 0.34), Color(1, 1, 1, 0.04))

	if shine and not disabled and _shine_t < 1.2:
		var x := (_shine_t / 1.2) * (size.x + 160) - 80
		var pts := PackedVector2Array([Vector2(x, off + 6), Vector2(x + 34, off + 6), Vector2(x + 8, off + face.size.y - 6), Vector2(x - 26, off + face.size.y - 6)])
		for i in pts.size():
			pts[i].x = clampf(pts[i].x, 12, size.x - 12)
		draw_colored_polygon(pts, Color(1, 1, 1, 0.3))

	var fs := get_theme_font_size("font_size")
	var isz := _icon_size()
	var cy := off + face.size.y / 2
	if icon_kind != "":
		UIDraw.icon(self, icon_kind, Vector2(size.x / 2, cy), minf(size.x, face.size.y) * 0.62)
	if icon_left != "":
		UIDraw.icon(self, icon_left, Vector2(padding + isz / 2, cy), isz)
	if icon_right != "":
		UIDraw.icon(self, icon_right, Vector2(size.x - padding - isz / 2, cy), isz)

	if text != "":
		var f := get_theme_font("font")
		var ml := padding + (isz + 8 if icon_left != "" else 0.0)
		var mr := padding + (isz + 8 if icon_right != "" else 0.0)
		var area := Rect2(ml, off, size.x - ml - mr, face.size.y)
		var oc := bottom.darkened(0.62)
		var ow := int(fs * 0.22) if text_outline < 0 else text_outline
		var tc := text_color
		if disabled:
			tc.a = 0.85
		var hal := alignment
		if autowrap_mode != TextServer.AUTOWRAP_OFF:
			var sz := f.get_multiline_string_size(text, hal, area.size.x, fs)
			var pos := Vector2(area.position.x, area.position.y + (area.size.y - sz.y) / 2 + f.get_ascent(fs))
			if ow > 0:
				draw_multiline_string_outline(f, pos + Vector2(0, fs * 0.09), text, hal, area.size.x, fs, -1, ow, Color(0.02, 0.05, 0.2, 0.35))
				draw_multiline_string_outline(f, pos, text, hal, area.size.x, fs, -1, ow, oc)
			draw_multiline_string(f, pos, text, hal, area.size.x, fs, -1, tc)
		else:
			var pos := Vector2(area.position.x, cy + (f.get_ascent(fs) - f.get_descent(fs)) / 2)
			if ow > 0:
				draw_string_outline(f, pos + Vector2(0, fs * 0.09), text, hal, area.size.x, fs, ow, Color(0.02, 0.05, 0.2, 0.35))
				draw_string_outline(f, pos, text, hal, area.size.x, fs, ow, oc)
			draw_string(f, pos, text, hal, area.size.x, fs, tc)

	if sparkles and not disabled:
		var spots: Array[Vector3] = [Vector3(0.07, 0.2, 0.0), Vector3(0.93, 0.28, 1.7), Vector3(0.86, 0.78, 3.1), Vector3(0.15, 0.8, 4.4)]
		for sp in spots:
			var k := 0.5 + 0.5 * sin(_t * 3.0 + sp.z)
			UIDraw.sparkle(self, Vector2(sp.x * size.x, off + sp.y * face.size.y), (6.0 + 9.0 * k) * (size.y / 120.0 + 0.4), Color(1, 1, 0.92, 0.5 + 0.5 * k))
