class_name MenuLevelsUI
extends Control

signal back_pressed

@export var scrol_container: ScrollContainer
@export var grid_container: GridContainer

func _on_back_button_pressed() -> void:
	back_pressed.emit()
