@tool
class_name TitleBanner
extends PanelContainer

@export var text := "Titre":
	set(value):
		text = value
		if has_node("Text"):
			$Text.text = value
@export var color := UIStyle.BLUE:
	set(value):
		color = value
		theme_type_variation = "Banner" + UISkin.color_name(value)


func _ready() -> void:
	text = text
