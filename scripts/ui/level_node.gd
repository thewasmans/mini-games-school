class_name LevelNode
extends Control
## Un level sur le chemin : plateforme ronde posée sur un rocher flottant.
## Verrouillée (pierre grise + cadenas), ouverte (disque bleu lumineux), en cours (halo pulsant)
## ou terminée (disque doré + étoile).

signal pressed

enum State { LOCKED, OPEN, CURRENT, DONE }

const NODE_SIZE := Vector2(170, 170)

var index := 0
var state := State.LOCKED
var kind := ""        # "crossword", "memo", "crypto"
var lock_offset := Vector2.ZERO
var flash := 0.0

var _t := 0.0
var _phase := 0.0
var _title: Label


func _init(index_: int, title: String, kind_: String) -> void:
	index = index_
	kind = kind_
	_phase = index_ * 1.3
	size = NODE_SIZE
	pivot_offset = NODE_SIZE / 2
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_title = UIStyle.label(title, 24, Color.WHITE, 8)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size = Vector2(250, 64)
	_title.position = Vector2((NODE_SIZE.x - 250) / 2, -34)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_title.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_title)


func _process(delta: float) -> void:
	_t += delta
	_title.modulate.a = 0.7 if state == State.LOCKED else 1.0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(1.1, 0.86), 0.07)
		else:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			if Rect2(Vector2.ZERO, size).has_point(event.position):
				pressed.emit()
		accept_event()


func shake() -> void:
	UIFeedback.shake(self, 10.0, 0.35)


func _draw() -> void:
	var bob := sin(_t * 1.8 + _phase) * 5.0
	var c := Vector2(size.x / 2, size.y * 0.52 + bob)
	var locked := state == State.LOCKED

	# Rocher sous la plateforme
	var rock := PackedVector2Array([c + Vector2(-62, 12), c + Vector2(62, 12), c + Vector2(46, 40), c + Vector2(18, 74),
		c + Vector2(2, 98), c + Vector2(-18, 72), c + Vector2(-48, 40)])
	draw_colored_polygon(rock, Color("6e7584") if locked else Color("8b5a3c"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(4, 12), c + Vector2(62, 12), c + Vector2(46, 40), c + Vector2(18, 74), c + Vector2(2, 98)]),
		Color("4f5563") if locked else Color("6b4228"))

	if state == State.CURRENT:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		for k in 3:
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, 4), Vector2(86, 44) * (1.0 + k * 0.14 + pulse * 0.08)), Color(0.35, 0.9, 1.0, 0.12 - k * 0.03))

	# Rebord (cylindre)
	var rim_dark := Color("7b8190") if locked else (Color("b8790a") if state == State.DONE else Color("c46a1c"))
	var rim_light := Color("aeb4c0") if locked else (Color("ffd45c") if state == State.DONE else Color("f6a640"))
	draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, 16), Vector2(68, 30)), rim_dark)
	draw_rect(Rect2(c.x - 68, c.y, 136, 16), rim_dark)
	draw_colored_polygon(UIDraw.ellipse(c, Vector2(68, 30)), rim_light)

	# Disque supérieur
	match state:
		State.LOCKED:
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, -2), Vector2(56, 23)), Color("c9ced8"))
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(-6, -6), Vector2(36, 12)), Color("dde1e8"))
			draw_line(c + Vector2(-30, -2), c + Vector2(-6, 8), Color("a3a9b6"), 2)
			draw_line(c + Vector2(14, -14), c + Vector2(34, -4), Color("a3a9b6"), 2)
		State.DONE:
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, -2), Vector2(56, 23)), Color("ffb92e"))
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, -4), Vector2(42, 16)), Color("ffd45c"))
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(-8, -8), Vector2(22, 7)), Color(1, 1, 1, 0.45))
		_:
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, -2), Vector2(56, 23)), Color("2f7de0"))
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, -4), Vector2(44, 17)), Color("4fb6ff"))
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(0, -6), Vector2(28, 10)), Color("a8e9ff"))
			draw_colored_polygon(UIDraw.ellipse(c + Vector2(-10, -9), Vector2(14, 4)), Color(1, 1, 1, 0.7))

	match state:
		State.LOCKED:
			UIDraw.lock(self, c + Vector2(0, -22) + lock_offset, 50)
		State.DONE:
			UIDraw.icon(self, "star", c + Vector2(0, -26 + sin(_t * 2.5 + _phase) * 3), 52)
		_:
			UIStyle.draw_text(self, str(index + 1), c + Vector2(0, -28), 44, Color.WHITE, 12)
			for k in 3:
				var a := _t * 1.2 + TAU * k / 3.0 + _phase
				var tw := 0.5 + 0.5 * sin(_t * 3.0 + k * 2.0)
				UIDraw.sparkle(self, c + Vector2(cos(a) * 62, -14 + sin(a) * 26), 4.0 + 6.0 * tw, Color(1, 1, 0.9, 0.5 + 0.5 * tw))
	_draw_kind_badge(c + Vector2(58, 26))

	if flash > 0:
		draw_colored_polygon(UIDraw.ellipse(c, Vector2(68, 30) * (1.0 + (1.0 - flash) * 0.7)), Color(1, 1, 1, flash))


func _draw_kind_badge(c: Vector2) -> void:
	draw_circle(c + Vector2(0, 3), 20, UIStyle.INK)
	draw_circle(c, 19, UIStyle.INK)
	draw_circle(c, 16, Color.WHITE)
	match kind:
		"crossword":
			for i in 4:
				var p := c + Vector2((i % 2) * 11 - 10, (i / 2) * 11 - 10)
				draw_rect(Rect2(p, Vector2(9, 9)), UIStyle.GOLD if i != 3 else Color("c9c1f2"))
		"memo":
			UIStyle.draw_text(self, "?", c + Vector2(0, 1), 26, UIStyle.PURPLE)
		"crypto":
			UIStyle.draw_text(self, "A_", c + Vector2(0, 1), 17, UIStyle.GREEN.darkened(0.2))


## Animation de déblocage : le cadenas tremble, éclate, puis le level devient « en cours ».
func play_unlock() -> void:
	state = State.LOCKED
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_method(func(t: float) -> void: lock_offset = Vector2(sin(t * 50.0) * 6.0 * (1.0 - t * 0.5), 0), 0.0, 1.0, 0.6)
	tw.tween_callback(func() -> void:
		lock_offset = Vector2.ZERO
		state = State.CURRENT
		flash = 1.0
		Sfx.play("unlock")
		Confetti.sparkle(self, global_position + size / 2, 26))
	tw.tween_property(self, "scale", Vector2.ONE * 1.3, 0.1)
	tw.parallel().tween_property(self, "flash", 0.0, 0.5)
	tw.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
