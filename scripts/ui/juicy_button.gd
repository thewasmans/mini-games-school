class_name JuicyButton
extends Button
## Bouton épais façon jeu mobile. Fond et texte viennent du thème (variations Button<Couleur>,
## ButtonPlay, ButtonKey, ButtonBack, ButtonGear) ; le script ajoute les icônes vectorielles,
## les étincelles, le reflet, l'écrasement à l'appui et le rebond élastique.

const STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const FONT_COLORS := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]

var sound := "click"
## Icône seule au centre (bouton sans texte) : voir UIDraw.icon() et UISkin.ICON_BUTTONS.
var icon_kind := "":
	set(value):
		icon_kind = value
		_update_variation()
var icon_left := "":
	set(value):
		icon_left = value
		_apply_margins()
var icon_right := "":
	set(value):
		icon_right = value
		_apply_margins()
## Choisit la variation Button<Couleur> du thème la plus proche (sauf si `skin` est renseigné).
var color: Color = UIStyle.BLUE:
	set(value):
		color = value
		_update_variation()
## Variation du thème imposée (ex. "ButtonPlay", "ButtonKey") ; vide = déduite de `color`.
var skin := &"":
	set(value):
		skin = value
		_update_variation()
var text_color := Color.WHITE:
	set(value):
		text_color = value
		for c: String in FONT_COLORS:
			add_theme_color_override(c, value)
		add_theme_color_override("font_disabled_color", Color(value, 0.85))
## Marge horizontale du texte : -1 = celle du thème.
var padding := -1:
	set(value):
		padding = value
		_apply_margins()
var sparkles := false:
	set(value):
		sparkles = value
		_update_process()
var shine := false

var _t := 0.0
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


## Variation du thème : `skin`, sinon bouton rond si l'icône en a un (retour, réglages), sinon Button<Couleur>.
func _update_variation() -> void:
	var round: StringName = UISkin.ICON_BUTTONS.get(icon_kind, &"") if text == "" else &""
	if skin != &"":
		theme_type_variation = skin
	elif round != &"" and UIStyle.theme().has_stylebox("normal", round):
		theme_type_variation = round
	else:
		theme_type_variation = "Button" + UISkin.color_name(color)
	_apply_margins()
	queue_redraw()


func _uses_round_skin() -> bool:
	return UISkin.ICON_BUTTONS.values().has(theme_type_variation)


func _icon_size() -> float:
	return get_theme_font_size("font_size") * 1.5


## Copie les styles de la variation en élargissant les marges pour les icônes et le padding.
func _apply_margins() -> void:
	begin_bulk_theme_override()
	for state: String in STATES:
		remove_theme_stylebox_override(state)
	if padding >= 0 or icon_left != "" or icon_right != "":
		var t := UIStyle.theme()
		var type := theme_type_variation if t.has_stylebox("normal", theme_type_variation) else &"Button"
		var icon_w := _icon_size() + 8
		for state: String in STATES:
			var sb: StyleBox = t.get_stylebox(state, type).duplicate()
			if padding >= 0:
				sb.content_margin_left = padding
				sb.content_margin_right = padding
			sb.content_margin_left += icon_w if icon_left != "" else 0.0
			sb.content_margin_right += icon_w if icon_right != "" else 0.0
			add_theme_stylebox_override(state, sb)
	end_bulk_theme_override()
	queue_redraw()


func _draw() -> void:
	if icon_kind == "sound_off" and _uses_round_skin():
		var a := size * 0.22
		var b := size * 0.72
		draw_line(a, b, UIStyle.INK, size.x * 0.13, true)
		draw_line(a, b, Color("ff4d5a"), size.x * 0.07, true)
		return

	# Zone de contenu du style courant (suit le décalage à l'appui).
	var mode := get_draw_mode()
	var state := "normal"
	match mode:
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			state = "pressed"
		DRAW_HOVER:
			state = "hover"
		DRAW_DISABLED:
			state = "disabled"
	var sb := get_theme_stylebox(state)
	var top := sb.content_margin_top
	var face_h := size.y - sb.content_margin_bottom - top
	var cy := top + face_h / 2

	if shine and not disabled and _shine_t < 1.2:
		var x := (_shine_t / 1.2) * (size.x + 160) - 80
		var pts := PackedVector2Array([Vector2(x, 8), Vector2(x + 34, 8), Vector2(x + 8, size.y - 16), Vector2(x - 26, size.y - 16)])
		for i in pts.size():
			pts[i].x = clampf(pts[i].x, 14, size.x - 14)
		draw_colored_polygon(pts, Color(1, 1, 1, 0.3))

	var isz := _icon_size()
	if icon_kind != "" and not _uses_round_skin():
		UIDraw.icon(self, icon_kind, Vector2(size.x / 2, cy), minf(size.x, face_h) * 0.62)
	if icon_left != "":
		UIDraw.icon(self, icon_left, Vector2(sb.content_margin_left - 8 - isz / 2, cy), isz)
	if icon_right != "":
		UIDraw.icon(self, icon_right, Vector2(size.x - sb.content_margin_right + 8 + isz / 2, cy), isz)

	if sparkles and not disabled:
		var spots: Array[Vector3] = [Vector3(0.07, 0.2, 0.0), Vector3(0.93, 0.28, 1.7), Vector3(0.86, 0.78, 3.1), Vector3(0.15, 0.8, 4.4)]
		for sp in spots:
			var k := 0.5 + 0.5 * sin(_t * 3.0 + sp.z)
			UIDraw.sparkle(self, Vector2(sp.x * size.x, sp.y * (size.y - 10)), (6.0 + 9.0 * k) * (size.y / 120.0 + 0.4), Color(1, 1, 0.92, 0.5 + 0.5 * k))
