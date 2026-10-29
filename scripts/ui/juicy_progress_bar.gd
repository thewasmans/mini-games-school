@tool
class_name JuicyProgressBar
extends Control

@export var fill_color := UIStyle.GREEN
@export var text := "{percent}"
@export var stripes := false

var value := 0.0
var _shown := 0.0
var _t := 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(stripes)


func set_value(v: float, animate := true) -> void:
	var grew := v > value + 0.001
	value = clampf(v, 0.0, 1.0)
	if _tween:
		_tween.kill()
	if not animate:
		_shown = value
		queue_redraw()
		return
	_tween = create_tween()
	_tween.tween_method(_set_shown, _shown, value, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if grew and is_inside_tree():
		UIFeedback.punch(self, 0.06, 0.4)


func _set_shown(v: float) -> void:
	_shown = v
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := size.y / 2
	draw_style_box(UIStyle.box(Color("0c1648"), int(r), 0, 3, Color("060b2a")), Rect2(Vector2.ZERO, size))
	if _shown > 0.001:
		var inner := Rect2(4, 4, maxf(size.y - 8, (size.x - 8) * _shown), size.y - 8)
		draw_style_box(UIStyle.box(fill_color, int(r - 4)), inner)
		if stripes:
			var off := fmod(_t * 40.0, 36.0)
			var x := inner.position.x - 36 + off
			while x < inner.end.x:
				var x0 := clampf(x, inner.position.x + 6, inner.end.x - 6)
				var x1 := clampf(x + 14, inner.position.x + 6, inner.end.x - 6)
				var x2 := clampf(x + 14 + inner.size.y, inner.position.x + 6, inner.end.x - 6)
				var x3 := clampf(x + inner.size.y, inner.position.x + 6, inner.end.x - 6)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x0, inner.end.y - 3), Vector2(x1, inner.end.y - 3),
					Vector2(x2, inner.position.y + 3), Vector2(x3, inner.position.y + 3)]), Color(1, 1, 1, 0.12))
				x += 36
		var gloss := Rect2(inner.position + Vector2(6, 3), Vector2(inner.size.x - 12, inner.size.y * 0.35))
		if gloss.size.x > 0:
			draw_style_box(UIStyle.box(Color(1, 1, 1, 0.3), int(gloss.size.y / 2)), gloss)
	if not text.is_empty():
		var t := text.replace("{percent}", "%d %%" % roundi(_shown * 100))
		UIStyle.draw_text(self, t, size / 2, int(size.y * 0.58), Color.WHITE, 8)
