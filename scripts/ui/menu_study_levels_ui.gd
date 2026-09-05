class_name MenuStudyLevelsUI
extends Control

signal back_pressed

@export var buttons_container: Container

func _on_back_button_pressed() -> void:
	back_pressed.emit()
