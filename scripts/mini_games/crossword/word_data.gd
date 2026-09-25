@tool
class_name WordData
extends Resource

@export var word: String = "":
	set(value):
		word = value.to_upper().strip_edges()

@export var hint: String = ""
@export var grid_position: Vector2i = Vector2i.ZERO
@export var is_horizontal: bool = true
