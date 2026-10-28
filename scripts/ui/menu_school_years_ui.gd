class_name MenuSchoolYearsUI
extends Control

signal back_pressed

@export var title_label: Label
@export var buttons_container: Container

func _on_back_button_pressed() -> void:
	back_pressed.emit()
