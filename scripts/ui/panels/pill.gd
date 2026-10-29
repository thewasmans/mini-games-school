@tool
class_name Pill
extends PanelContainer

@export var text := "":
	set(value):
		text = value
		if has_node("Text"):
			$Text.text = value


func _ready() -> void:
	text = text
