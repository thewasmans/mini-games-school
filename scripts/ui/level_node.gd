class_name LevelNode
extends Control
## Un level sur le chemin : plateforme ronde, verrouillée, ouverte, en cours ou terminée.

signal pressed

enum State { LOCKED, OPEN, CURRENT, DONE }

const NODE_SIZE := Vector2(150, 150)

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
	_title = UIStyle.label(title, 21, Color.WHITE, 7)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size = Vector2(230, 60)
	_title.position = Vector2((NODE_SIZE.x - 230) / 2, NODE_SIZE.y - 18)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_title.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_title)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(1.1, 0.85), 0.07)
		else:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			if Rect2(Vector2.ZERO, size).has_point(event.position):
				pressed.emit()
		accept_event()


func _draw() -> void:
	var bob := sin(_t * 2.0 + _phase) * 4.0
	var c := Vector2(size.x / 2, size.y / 2 - 6 + bob)
	var top: Color
	var base: Color
	match state:
		State.LOCKED:
			top = Color("9aa3b8")
			base = Color("5d6478")
		State.OPEN:
			top = Color("4aa3ff")
			base = Color("1f5cc7")
		State.CURRENT:
			top = Color("3fe0ff")
			base = Color("1786c9")
		State.DONE:
			top = Color("ffc93c")
			base = Color("c98a0a")

	draw_colored_polygon(UIStyle.ellipse(Vector2(size.x / 2, size.y - 14), Vector2(56, 13)), Color(0, 0, 0, 0.25))
	if state == State.CURRENT:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_colored_polygon(UIStyle.ellipse(c + Vector2(0, 6), Vector2(78, 54) * (1.0 + pulse * 0.12)), Color(0.3, 0.95, 1.0, 0.18 + pulse * 0.15))
	# Socle (épaisseur)
	var thick := 20.0
	var rx := 62.0
	var ry := 40.0
	draw_colored_polygon(UIStyle.ellipse(c + Vector2(0, thick), Vector2(rx, ry)), base.darkened(0.25))
	draw_rect(Rect2(c.x - rx, c.y, rx * 2, thick), base.darkened(0.25))
	draw_colored_polygon(UIStyle.ellipse(c + Vector2(0, thick * 0.55), Vector2(rx, ry)), base)
	draw_colored_polygon(UIStyle.ellipse(c, Vector2(rx, ry)), top)
	draw_colored_polygon(UIStyle.ellipse(c + Vector2(-8, -10), Vector2(rx * 0.7, ry * 0.5)), Color(1, 1, 1, 0.25))

	match state:
		State.LOCKED:
			_draw_lock(c + lock_offset)
		State.DONE:
			UIStyle.draw_text(self, str(index + 1), c + Vector2(0, -2), 40, Color.WHITE, 10)
			for k in 3:
				var p := c + Vector2((k - 1) * 30, -50 - (1 - absi(k - 1)) * 10)
				draw_colored_polygon(UIStyle.star(p + Vector2(0, 2), 16, 7), Color("8a5a00"))
				draw_colored_polygon(UIStyle.star(p, 15, 6.5), UIStyle.YELLOW)
		_:
			UIStyle.draw_text(self, str(index + 1), c + Vector2(0, -2), 44, Color.WHITE, 12)
	_draw_kind_badge(c + Vector2(48, 18))

	if state == State.CURRENT:
		var y := c.y - 80 - absf(sin(_t * 3.5)) * 16
		var tri := PackedVector2Array([Vector2(c.x - 22, y - 24), Vector2(c.x + 22, y - 24), Vector2(c.x, y)])
		draw_colored_polygon(tri, UIStyle.INK)
		tri = PackedVector2Array([Vector2(c.x - 15, y - 21), Vector2(c.x + 15, y - 21), Vector2(c.x, y - 5)])
		draw_colored_polygon(tri, UIStyle.YELLOW)
	if flash > 0:
		draw_colored_polygon(UIStyle.ellipse(c, Vector2(rx, ry) * (1.0 + (1.0 - flash) * 0.6)), Color(1, 1, 1, flash))


func _draw_lock(c: Vector2) -> void:
	draw_arc(c + Vector2(0, -10), 15, PI, TAU, 16, UIStyle.INK, 11)
	draw_arc(c + Vector2(0, -10), 15, PI, TAU, 16, Color("d9dde8"), 6)
	draw_style_box(UIStyle.box(Color("f2b705"), 6, 0, 3, UIStyle.INK), Rect2(c.x - 22, c.y - 12, 44, 34))
	draw_circle(c + Vector2(0, 2), 5, UIStyle.INK)
	draw_rect(Rect2(c.x - 2, c.y + 2, 4, 10), UIStyle.INK)


func _draw_kind_badge(c: Vector2) -> void:
	draw_circle(c + Vector2(0, 2), 19, UIStyle.INK)
	draw_circle(c, 17, Color.WHITE)
	match kind:
		"crossword":
			for i in 4:
				var p := c + Vector2((i % 2) * 11 - 10, (i / 2) * 11 - 10)
				draw_rect(Rect2(p, Vector2(9, 9)), UIStyle.GOLD if i != 3 else Color("d6d0ff"))
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
