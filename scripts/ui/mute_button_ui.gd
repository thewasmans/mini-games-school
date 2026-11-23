class_name MuteButtonUI
extends Button

const MASTER_BUS := &"Master"
const ICON_COLOR := Color.WHITE
const ICON_SCALE := 0.55
const LINE_WIDTH_RATIO := 0.09

func _ready() -> void:
	ButtonPressAnimation.attach(self)
	button_pressed = AudioServer.is_bus_mute(_master_bus_index())
	toggled.connect(_on_toggled)

func _on_toggled(is_muted: bool) -> void:
	AudioServer.set_bus_mute(_master_bus_index(), is_muted)
	queue_redraw()

func _master_bus_index() -> int:
	return AudioServer.get_bus_index(MASTER_BUS)

func _draw() -> void:
	var icon_size := minf(size.x, size.y) * ICON_SCALE
	var origin := (size - Vector2.ONE * icon_size) * 0.5
	var line_width := icon_size * LINE_WIDTH_RATIO
	var speaker := PackedVector2Array()
	for point in [Vector2(0.0, 0.35), Vector2(0.25, 0.35), Vector2(0.5, 0.1), Vector2(0.5, 0.9), Vector2(0.25, 0.65), Vector2(0.0, 0.65)]:
		speaker.append(origin + point * icon_size)
	draw_colored_polygon(speaker, ICON_COLOR)
	if button_pressed:
		draw_line(origin + Vector2(0.65, 0.35) * icon_size, origin + Vector2(0.95, 0.65) * icon_size, ICON_COLOR, line_width, true)
		draw_line(origin + Vector2(0.95, 0.35) * icon_size, origin + Vector2(0.65, 0.65) * icon_size, ICON_COLOR, line_width, true)
		return
	var wave_center := origin + Vector2(0.5, 0.5) * icon_size
	draw_arc(wave_center, icon_size * 0.22, -PI / 4.0, PI / 4.0, 12, ICON_COLOR, line_width, true)
	draw_arc(wave_center, icon_size * 0.42, -PI / 4.0, PI / 4.0, 16, ICON_COLOR, line_width, true)
