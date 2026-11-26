class_name TouchJoystick
extends Control

signal moved(direction: Vector2)

@export_group("Réglages")
## Rayon du socle du joystick, en pixels.
@export var radius := 110.0
## Rayon de la manette qui suit le doigt, en pixels.
@export var knob_radius := 48.0
## Part du rayon en dessous de laquelle le joystick ne réagit pas.
@export_range(0.0, 0.5) var dead_zone := 0.12

var direction := Vector2.ZERO

var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _active := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_center = size / 2
	resized.connect(func() -> void: _center = size / 2)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_active = event.pressed
		_update_knob(event.position if event.pressed else _center)
		accept_event()
	elif event is InputEventMouseMotion and _active:
		_update_knob(event.position)
		accept_event()


func release() -> void:
	_active = false
	_update_knob(_center)


func _update_knob(point: Vector2) -> void:
	var offset := (point - _center).limit_length(radius)
	_knob = offset
	var value := offset / radius
	direction = value if value.length() > dead_zone else Vector2.ZERO
	moved.emit(direction)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release()


func _draw() -> void:
	draw_circle(_center, radius, Color(0.02, 0.04, 0.15, 0.35))
	draw_arc(_center, radius, 0, TAU, 48, Color(1, 1, 1, 0.5), 4.0, true)
	draw_circle(_center + _knob, knob_radius + 4, Color(0.02, 0.04, 0.15, 0.6))
	draw_circle(_center + _knob, knob_radius, Color(1, 1, 1, 0.9) if _active else Color(1, 1, 1, 0.7))
