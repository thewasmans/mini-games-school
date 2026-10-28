class_name CrosswordCell
extends Control
## Une case du mot croisé, dessinée à la main pour pouvoir l'animer librement.

signal clicked

enum Highlight { NONE, WORD, CURSOR }

const EMPTY := Color("d6d0ff")
const WORD := Color("fff2b8")
const CURSOR := Color("ffe14d")
const DONE := Color("ffb43b")
const WRONG := Color("ff5a64")

var solution := ""
var letter := ""
var number := 0
var words: Array[int] = []
var validated := false
var wrong := false
var hint := false
var highlight := Highlight.NONE

var _shake := 0.0
var _flash := 0.0
var _t := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


func _process(delta: float) -> void:
	_t += delta
	if highlight == Highlight.CURSOR:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		accept_event()


func refresh() -> void:
	queue_redraw()


func shake() -> void:
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		_shake = sin(t * 36.0) * size.x * 0.14 * (1.0 - t)
		queue_redraw(), 0.0, 1.0, 0.45)


## Rebond + flash blanc (mot validé, vague de fin).
func celebrate(delay := 0.0) -> void:
	pivot_offset = size / 2
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void: _flash = 1.0)
	tw.tween_property(self, "scale", Vector2.ONE * 1.28, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float) -> void:
		_flash = v
		queue_redraw(), 1.0, 0.0, 0.35)


func _draw() -> void:
	if size.x < 4:
		return
	draw_set_transform(Vector2(_shake, 0), 0, Vector2.ONE)
	var depth := maxf(3.0, size.y * 0.09)
	var radius := int(size.x * 0.18)
	var top := EMPTY
	if validated:
		top = DONE
	elif wrong:
		top = WRONG
	elif highlight == Highlight.CURSOR:
		top = CURSOR
	elif highlight == Highlight.WORD:
		top = WORD
	draw_style_box(UIStyle.box(top.darkened(0.35), radius), Rect2(Vector2.ZERO, size))
	draw_style_box(UIStyle.box(top, radius), Rect2(0, 0, size.x, size.y - depth))
	draw_style_box(UIStyle.box(Color(1, 1, 1, 0.35), radius / 2), Rect2(size.x * 0.12, size.y * 0.07, size.x * 0.76, size.y * 0.16))
	if highlight == Highlight.CURSOR and not validated:
		var a := 0.55 + 0.45 * sin(_t * 8.0)
		var glow := UIStyle.box(Color(0, 0, 0, 0), radius + 2, 0, maxi(2, int(size.x * 0.07)), Color(1, 1, 1, a))
		draw_style_box(glow, Rect2(-2, -2, size.x + 4, size.y - depth + 4))

	var face_center := Vector2(size.x / 2, (size.y - depth) / 2 + 1)
	var fs := int(size.y * 0.56)
	if letter != "":
		var light := validated or wrong
		UIStyle.draw_text(self, letter, face_center, fs, Color.WHITE if light else UIStyle.INK, int(fs * 0.22) if light else 0)
	elif hint:
		UIStyle.draw_text(self, solution, face_center, fs, Color(0.1, 0.1, 0.4, 0.25))
	if number > 0:
		var ns := int(size.y * 0.24)
		UIStyle.draw_text(self, str(number), Vector2(ns * 0.6 + 2, ns * 0.55 + 1), ns, Color(0.1, 0.1, 0.35, 0.75))
	if _flash > 0:
		draw_style_box(UIStyle.box(Color(1, 1, 1, _flash * 0.7), radius), Rect2(Vector2.ZERO, size))
