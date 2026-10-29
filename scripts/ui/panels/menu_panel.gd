@tool
class_name MenuPanel
extends PanelContainer

@export_multiline var header_text := "":
	set(value):
		header_text = value
		if has_node("Content/Header"):
			$Content/Header.text = value
			$Content/Header.visible = value != ""

var content: VBoxContainer:
	get:
		return $Content


func _ready() -> void:
	header_text = header_text
