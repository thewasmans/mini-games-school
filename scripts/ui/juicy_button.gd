class_name JuicyButton
extends Button
## Bouton épais façon jeu mobile : écrasement à l'appui, rebond élastique, reflet, son.

## Icône dessinée : "", "back", "check".
var icon_kind := ""
## Reflet lumineux qui balaie le bouton à intervalle régulier.
var shine := false
var sound := "click"
var color: Color = UIStyle.BLUE:
	set(value):
		color = value
		_apply_styles()
## Marge intérieure gauche/droite du texte.
var padding := 22:
	set(value):
		padding = value
		_apply_styles()

var _depth := 8
var _radius := 22
var _shine_t := 0.0
var _scale_tween: Tween


func _init(text_ := "", color_ := UIStyle.BLUE, font_size := 30) -> void:
	text = text_
	focus_mode = FOCUS_NONE
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", font_size)
	color = color_


func _ready() -> void:
	pivot_offset = size / 2
	resized.connect(func() -> void: pivot_offset = size / 2)
	button_down.connect(func() -> void: _tween_scale(Vector2(0.9, 0.86), 0.08, Tween.TRANS_QUAD))
	button_up.connect(func() -> void: _tween_scale(Vector2.ONE, 0.5, Tween.TRANS_ELASTIC))
	mouse_entered.connect(func() -> void:
		if not disabled:
			_tween_scale(Vector2(1.04, 1.04), 0.25, Tween.TRANS_BACK))
	mouse_exited.connect(func() -> void: _tween_scale(Vector2.ONE, 0.25, Tween.TRANS_BACK))
	pressed.connect(func() -> void: Sfx.play(sound))
	set_process(shine)


func set_shine(on: bool) -> void:
	shine = on
	set_process(on)


func _process(delta: float) -> void:
	_shine_t = fmod(_shine_t + delta, 2.6)
	queue_redraw()


func _tween_scale(target: Vector2, duration: float, trans: Tween.TransitionType) -> void:
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target, duration).set_trans(trans).set_ease(Tween.EASE_OUT)


func _apply_styles() -> void:
	var normal := _style(color)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", _style(color.lightened(0.1)))
	var pressed_sb := _style(color.darkened(0.06))
	pressed_sb.border_width_bottom = 4
	pressed_sb.content_margin_top += 4
	add_theme_stylebox_override("pressed", pressed_sb)
	add_theme_stylebox_override("hover_pressed", pressed_sb)
	add_theme_stylebox_override("disabled", _style(color.darkened(0.12)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	queue_redraw()


func _style(c: Color) -> StyleBoxFlat:
	var sb := UIStyle.box(c, _radius, _depth, 3, c.darkened(0.42))
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = padding
	sb.content_margin_right = padding
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	return sb


func _draw() -> void:
	var face_h := size.y - _depth - 3
	# Reflet sur la moitié haute
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.22 if not disabled else 0.08)
	gloss.set_corner_radius_all(_radius - 6)
	gloss.corner_detail = 6
	draw_style_box(gloss, Rect2(8, 6, size.x - 16, face_h * 0.42))
	if shine and not disabled:
		var x := (_shine_t / 1.2) * (size.x + 200) - 100
		if _shine_t < 1.2:
			var pts := PackedVector2Array([
				Vector2(x, 6), Vector2(x + 40, 6), Vector2(x + 10, face_h), Vector2(x - 30, face_h)])
			for i in pts.size():
				pts[i].x = clampf(pts[i].x, 10, size.x - 10)
			draw_colored_polygon(pts, Color(1, 1, 1, 0.35))
	match icon_kind:
		"back":
			var c := Vector2(size.x / 2 - 3, face_h / 2 + 3)
			var s := minf(size.x, face_h) * 0.22
			var pts := PackedVector2Array([c + Vector2(s * 0.6, -s), c + Vector2(-s * 0.5, 0), c + Vector2(s * 0.6, s)])
			draw_polyline(pts, UIStyle.INK, s * 0.75, true)
			draw_polyline(pts, Color.WHITE, s * 0.42, true)
		"check":
			var c := Vector2(size.x / 2, face_h / 2 + 3)
			var s := minf(size.x, face_h) * 0.22
			var pts := PackedVector2Array([c + Vector2(-s, 0), c + Vector2(-s * 0.3, s * 0.7), c + Vector2(s, -s * 0.7)])
			draw_polyline(pts, UIStyle.INK, s * 0.75, true)
			draw_polyline(pts, Color.WHITE, s * 0.42, true)
