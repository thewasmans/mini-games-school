class_name MenuLevelsUI
extends Panel

@export var scrol_container: ScrollContainer
@export var grid_container: GridContainer

func _on_back_button_pressed() -> void:
	hide()
