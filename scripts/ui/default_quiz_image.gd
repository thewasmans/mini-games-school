class_name DefaultQuizImage
extends Control

var roof := Color("3b6fd8")
var _t := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x / 2.3, size.y / 2.9)
	if s <= 1:
		return
	var c := Vector2(size.x / 2, size.y * 0.58 + sin(_t * 1.4) * s * 0.04)
	draw_circle(c + Vector2(0, -s * 0.3), s * 1.35, Color(0.5, 0.8, 1.0, 0.08))
	draw_circle(c + Vector2(0, -s * 0.3), s * 1.05, Color(0.6, 0.85, 1.0, 0.08))
	if has_theme_icon("island", "DefaultQuizImage"):
		var sprite := get_theme_icon("island", "DefaultQuizImage")
		UISkin.draw_fit(self, sprite, size / 2 + Vector2(0, sin(_t * 1.4) * s * 0.04), minf(size.x, size.y) * 0.95)
	else:
		UIDraw.castle_island(self, c, s, roof)
	for i in 5:
		var a := _t * 0.8 + TAU * i / 5.0
		var p := c + Vector2(cos(a) * s * 1.15, -s * 0.45 + sin(a) * s * 0.35)
		var k := 0.5 + 0.5 * sin(_t * 3.0 + i)
		UIDraw.sparkle(self, p, s * (0.05 + 0.05 * k), Color(1, 1, 0.85, 0.6 + 0.4 * k))
