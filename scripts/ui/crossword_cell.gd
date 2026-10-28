class_name CrosswordCell
extends Control
## Une case du mot croisé (lavande, orange une fois validée), dessinée à la main
## pour pouvoir l'animer librement.

signal clicked

enum Highlight { NONE, WORD, CURSOR }

const EMPTY := [Color("ddd6ff"), Color("b9aef0")]
const WORD := [Color("f4f1ff"), Color("d6cdfb")]
const CURSOR := [Color("fff6c4"), Color("ffd84a")]
const DONE := [Color("ffc451"), Color("f28a1c")]
const WRONG := [Color("ff8088"), Color("e8323f")]

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
	var depth := maxf(3.0, size.y * 0.1)
	var radius := size.x * 0.2
	var pal: Array = EMPTY
	var skin := "cell_empty"
	if validated:
		pal = DONE
		skin = "cell_done"
	elif wrong:
		pal = WRONG
		skin = "cell_wrong"
	elif highlight == Highlight.CURSOR:
		pal = CURSOR
		skin = "cell_cursor"
	elif highlight == Highlight.WORD:
		pal = WORD
		skin = "cell_word"
	var skin_tex := UISkin.tex(skin)
	var top: Color = pal[0]
	var bottom: Color = pal[1]
	var face := Rect2(0, 0, size.x, size.y - depth)

	if highlight == Highlight.CURSOR and not validated:
		var a := 0.55 + 0.45 * sin(_t * 6.0)
		UIDraw.glow(self, face, radius, Color(0.5, 0.95, 1.0, a), size.x * 0.22, 4)
	UIDraw.rrect(self, Rect2(1, 3, size.x - 2, size.y - 2), radius, Color(0.02, 0.05, 0.2, 0.3))
	if skin_tex != null:
		draw_texture_rect(skin_tex, Rect2(Vector2.ZERO, size), false)
	else:
		UIDraw.rrect(self, Rect2(Vector2.ZERO, size), radius, bottom.darkened(0.35))
		UIDraw.rrect(self, face, radius, top, bottom, top.lightened(0.5), maxf(1.5, size.x * 0.04))
		UIDraw.rrect(self, Rect2(size.x * 0.14, size.y * 0.07, size.x * 0.72, face.size.y * 0.32), radius * 0.6, Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.05))

	var face_center := Vector2(size.x / 2, face.size.y / 2 + 1)
	var fs := int(size.y * 0.58)
	if letter != "":
		var light := validated or wrong
		var outline_col := Color("8a3d00") if validated else Color("7a0f1a")
		UIStyle.draw_text(self, letter, face_center, fs, Color.WHITE if light else UIStyle.INK, int(fs * 0.24) if light else 0, outline_col)
	elif hint:
		UIStyle.draw_text(self, solution, face_center, fs, Color(0.1, 0.1, 0.4, 0.25))
	if number > 0:
		var ns := int(size.y * 0.25)
		UIStyle.draw_text(self, str(number), Vector2(ns * 0.62 + 2, ns * 0.6 + 1), ns, Color(0.08, 0.1, 0.35, 0.8))
	if highlight == Highlight.CURSOR and not validated:
		var k := 0.5 + 0.5 * sin(_t * 5.0)
		UIDraw.sparkle(self, Vector2(size.x * 0.92, size.y * 0.05), size.x * (0.1 + 0.08 * k), Color(1, 1, 0.9, 0.9))
		UIDraw.sparkle(self, Vector2(size.x * 0.05, size.y * 0.85), size.x * (0.06 + 0.06 * (1 - k)), Color(1, 1, 0.9, 0.8))
	if _flash > 0:
		UIDraw.rrect(self, Rect2(Vector2.ZERO, size), radius, Color(1, 1, 1, _flash * 0.7))
