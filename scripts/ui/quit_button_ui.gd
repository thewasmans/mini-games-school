class_name QuitButtonUI
extends Button

const ICON_COLOR := Color.WHITE
const ICON_RADIUS_RATIO := 0.31
const ICON_LINE_RATIO := 0.095

func _draw() -> void:
	var icon_size := minf(size.x, size.y)
	var center := size * 0.5
	var radius := icon_size * ICON_RADIUS_RATIO
	var line_width := icon_size * ICON_LINE_RATIO
	# Leave the top arc open for the power symbol's vertical stroke.
	draw_arc(center, radius, PI * 1.75, PI * 3.25, 32, ICON_COLOR, line_width, true)
	var stem_top := center - Vector2(0.0, radius * 1.45)
	var stem_bottom := center - Vector2(0.0, radius * 0.15)
	draw_line(stem_top, stem_bottom, ICON_COLOR, line_width, true)
	draw_circle(stem_top, line_width * 0.5, ICON_COLOR)
	draw_circle(stem_bottom, line_width * 0.5, ICON_COLOR)
