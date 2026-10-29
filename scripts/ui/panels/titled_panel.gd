@tool
class_name TitledPanel
extends PanelContainer

@export var title := "Titre":
	set(value):
		title = value
		if has_node("Layout/Header/Title"):
			$Layout/Header/Title.text = value

var content: VBoxContainer:
	get:
		return $Layout/Inner/Content


func _ready() -> void:
	title = title
