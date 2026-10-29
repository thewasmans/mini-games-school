@tool
class_name IconView
extends Control

@export var icon := "":
	set(value):
		icon = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	UIDraw.icon(self, icon, size / 2, minf(size.x, size.y))
