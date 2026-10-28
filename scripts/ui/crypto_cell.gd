class_name CryptoCell
extends Control
## Une case du cryptogramme. Une lettre tapée garde le style des lettres visibles.

signal clicked

enum State { VISIBLE, EMPTY, FILLED, CORRECT, WRONG, SYMBOL }

var original := ""   # caractère de la phrase (avec accent éventuel)
var typed := ""
var state := State.VISIBLE
var is_cursor := false
var hint := false

var _t := 0.0
var _shake := 0.0


func _init(ch := "", cell_size := Vector2(44, 58)) -> void:
	original = ch
	custom_minimum_size = cell_size
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		accept_event()


func _process(delta: float) -> void:
	_t += delta
	if is_cursor:
		queue_redraw()


func refresh() -> void:
	queue_redraw()


func shake() -> void:
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		_shake = sin(t * 36.0) * size.x * 0.18 * (1.0 - t)
		queue_redraw(), 0.0, 1.0, 0.45)


func _draw() -> void:
	draw_set_transform(Vector2(_shake, 0), 0, Vector2.ONE)
	var fs := int(size.y * 0.58)
	var center := Vector2(size.x / 2, size.y / 2 - 2)
	if state == State.SYMBOL:
		UIStyle.draw_text(self, original, center, fs, Color.WHITE, 8)
		return
	var depth := 5.0
	var radius := 10
	var face := Color("f4f6ff")
	var text := original
	var text_color := UIStyle.INK
	var outline := 0
	match state:
		State.EMPTY:
			face = Color(1, 1, 1, 0.16)
			text = ""
		State.FILLED:
			text = typed
		State.CORRECT:
			face = Color("3fd06a")
			text_color = Color.WHITE
			outline = 8
		State.WRONG:
			face = Color("ff5a64")
			text = typed
			text_color = Color.WHITE
			outline = 8
	if is_cursor:
		face = Color("ffe14d")
	if state == State.EMPTY and not is_cursor:
		draw_style_box(UIStyle.box(face, radius, 0, 2, Color(1, 1, 1, 0.45)), Rect2(0, 0, size.x, size.y - depth))
		draw_line(Vector2(8, size.y - depth - 9), Vector2(size.x - 8, size.y - depth - 9), Color(1, 1, 1, 0.6), 3)
	else:
		draw_style_box(UIStyle.box(face.darkened(0.3), radius), Rect2(Vector2.ZERO, size))
		draw_style_box(UIStyle.box(face, radius), Rect2(0, 0, size.x, size.y - depth))
	if is_cursor:
		var a := 0.5 + 0.5 * sin(_t * 8.0)
		draw_style_box(UIStyle.box(Color(0, 0, 0, 0), radius + 2, 0, 3, Color(1, 1, 1, a)), Rect2(-3, -3, size.x + 6, size.y - depth + 6))
		if text == "":
			draw_line(Vector2(size.x / 2, 12), Vector2(size.x / 2, size.y - depth - 14), Color(UIStyle.INK, a), 3)
	if text != "":
		UIStyle.draw_text(self, text, Vector2(size.x / 2, (size.y - depth) / 2 + 1), fs, text_color, outline)
	elif hint:
		UIStyle.draw_text(self, original, Vector2(size.x / 2, (size.y - depth) / 2 + 1), fs, Color(1, 1, 1, 0.3))
