@tool
class_name ProgressRing
extends Control

var _value := 0.0
var _shown := 0.0
var _text := ""


func set_progress(current: int, total: int) -> void:
	_text = "%d/%d" % [current, total]
	_value = current / float(maxi(total, 1))
	var tw := create_tween()
	tw.tween_method(_set_shown, _shown, _value, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()


func _draw() -> void:
	var c := size / 2
	var r := minf(size.x, size.y) / 2 - 8
	draw_circle(c, r + 6, Color("0f1d52"))
	draw_circle(c, r - 8, Color("13235e"))
	draw_arc(c, r - 1, 0, TAU, 48, Color(1, 1, 1, 0.12), 12, true)
	var start := -PI / 2
	var steps := 24
	for i in steps:
		var t0 := float(i) / steps * _shown
		var t1 := float(i + 1) / steps * _shown
		var col := Color("ffd23f").lerp(Color("ff5fa8"), t0).lerp(Color("4fb6ff"), maxf(0, t0 - 0.5))
		draw_arc(c, r - 1, start + TAU * t0, start + TAU * t1 + 0.01, 4, col, 12, true)
	UIStyle.draw_text(self, _text, c, int(r * 0.62), Color("ffe066"), 8)
