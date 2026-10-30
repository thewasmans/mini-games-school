class_name CryptoCell
extends Control

signal clicked

enum State { VISIBLE, EMPTY, FILLED, CORRECT, WRONG, SYMBOL }

const THEME_TYPE := &"CryptoCell"

var original := ""
var typed := ""
var state := State.VISIBLE
var is_cursor := false

var _t := 0.0
var _shake := 0.0


func setup(ch: String, cell_size: Vector2) -> void:
	original = ch
	custom_minimum_size = cell_size


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
	if size.x < 4:
		return
	draw_set_transform(Vector2(_shake, 0), 0, Vector2.ONE)
	var fs := int(size.y * 0.58)
	if state == State.SYMBOL or state == State.VISIBLE:
		UIStyle.draw_text(self, original, Vector2(size.x / 2, size.y / 2 - 2), fs, Color.WHITE, 8)
		return
	var depth := 5.0
	var radius := 10.0
	var top := Color("f4f1ff")
	var bottom := Color("d6cdfb")
	var text := original
	var text_color := UIStyle.INK
	var outline := 0
	var outline_color := UIStyle.INK
	match state:
		State.FILLED:
			text = typed
		State.CORRECT:
			top = Color("7be86a")
			bottom = Color("22a83a")
			text_color = Color.WHITE
			outline = 8
			outline_color = Color("0f5a1e")
		State.WRONG:
			top = Color("ff8088")
			bottom = Color("e8323f")
			text = typed
			text_color = Color.WHITE
			outline = 8
			outline_color = Color("7a0f1a")
		State.EMPTY:
			text = ""
	var face := Rect2(0, 0, size.x, size.y - depth)
	if is_cursor:
		var a := 0.55 + 0.45 * sin(_t * 6.0)
		UIDraw.glow(self, face, radius, Color(0.5, 0.95, 1.0, a), 10.0, 4)
		top = Color("fff6c4")
		bottom = Color("ffd84a")
	var skin := &"word"
	match state:
		State.CORRECT:
			skin = &"good"
		State.WRONG:
			skin = &"wrong"
	if is_cursor:
		skin = &"cursor"
	var skin_tex := get_theme_icon(skin, THEME_TYPE) if has_theme_icon(skin, THEME_TYPE) else null
	if state == State.EMPTY and not is_cursor:
		UIDraw.rrect(self, face, radius, Color(0.03, 0.08, 0.3, 0.7), Color(0.05, 0.12, 0.38, 0.7), Color(0.55, 0.75, 1.0, 0.6), 2.0)
		draw_line(Vector2(8, face.size.y - 9), Vector2(size.x - 8, face.size.y - 9), Color(0.7, 0.85, 1.0, 0.7), 3)
	elif skin_tex != null:
		draw_texture_rect(skin_tex, Rect2(Vector2.ZERO, size), false)
	else:
		UIDraw.rrect(self, Rect2(Vector2.ZERO, size), radius, bottom.darkened(0.35))
		UIDraw.rrect(self, face, radius, top, bottom, top.lightened(0.5), 1.5)
		UIDraw.rrect(self, Rect2(size.x * 0.14, 4, size.x * 0.72, face.size.y * 0.3), radius * 0.6, Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.05))
	if is_cursor and text == "":
		var a := 0.5 + 0.5 * sin(_t * 8.0)
		draw_line(Vector2(size.x / 2, 12), Vector2(size.x / 2, face.size.y - 12), Color(UIStyle.INK, a), 3)
	if text != "":
		UIStyle.draw_text(self, text, Vector2(size.x / 2, face.size.y / 2 + 1), fs, text_color, outline, outline_color)
