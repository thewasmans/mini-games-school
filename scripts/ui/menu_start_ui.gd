class_name MenuStartUI
extends Control

signal play_pressed
signal credits_pressed

@export var play_button: Button

func _ready() -> void:
	play_button.resized.connect(_update_play_button_shader_size)
	_update_play_button_shader_size()

func _update_play_button_shader_size() -> void:
	(play_button.material as ShaderMaterial).set_shader_parameter("button_size", play_button.size)

func _on_play_button_pressed() -> void:
	play_pressed.emit()

func _on_credits_button_pressed() -> void:
	credits_pressed.emit()
