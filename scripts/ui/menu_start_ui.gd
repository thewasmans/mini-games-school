class_name MenuStartUI
extends Control

signal play_pressed
signal credits_pressed

func _on_play_button_pressed() -> void:
	play_pressed.emit()

func _on_credits_button_pressed() -> void:
	credits_pressed.emit()
