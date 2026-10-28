class_name DefaultQuizImage
extends Control
## Image par défaut du quiz : une île flottante avec un gros point d'interrogation.

var _t := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) / 300.0
	var c := size / 2 + Vector2(0, sin(_t * 1.6) * 8 * s)
	draw_colored_polygon(UIStyle.ellipse(Vector2(size.x / 2, size.y * 0.95), Vector2(90, 14) * s), Color(0, 0, 0, 0.2))
	# Rocher sous l'île
	var rock := PackedVector2Array([c + Vector2(-120, 30) * s, c + Vector2(120, 30) * s, c + Vector2(60, 95) * s,
		c + Vector2(10, 130) * s, c + Vector2(-50, 100) * s])
	draw_colored_polygon(rock, Color("8a5a3c"))
	draw_colored_polygon(UIStyle.ellipse(c + Vector2(0, 30) * s, Vector2(125, 40) * s), Color("6a4128"))
	draw_colored_polygon(UIStyle.ellipse(c + Vector2(0, 18) * s, Vector2(125, 40) * s), Color("5cc65a"))
	draw_colored_polygon(UIStyle.ellipse(c + Vector2(-20, 10) * s, Vector2(80, 22) * s), Color("78dd73"))
	# Bulle « ? »
	var bubble := c + Vector2(0, -70 + sin(_t * 2.4) * 6) * s
	draw_circle(bubble + Vector2(0, 6) * s, 62 * s, Color("1f5cc7"))
	draw_circle(bubble, 62 * s, Color("3b8cff"))
	draw_circle(bubble + Vector2(-18, -22) * s, 18 * s, Color(1, 1, 1, 0.3))
	UIStyle.draw_text(self, "?", bubble + Vector2(0, 4) * s, int(84 * s), Color.WHITE, int(16 * s))
	for i in 3:
		var a := _t * 1.5 + TAU * i / 3.0
		var p := bubble + Vector2(cos(a) * 95, sin(a) * 30) * s
		draw_colored_polygon(UIStyle.star(p, 12 * s, 5 * s, _t), Color("ffe066"))
