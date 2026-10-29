class_name OnScreenKeyboard
extends PanelContainer

signal letter_pressed(letter: String)
signal backspace_pressed

@export var backspace_key: Button


func _ready() -> void:
	for key: Button in find_children("*", "Button", true, false):
		if key == backspace_key:
			key.pressed.connect(backspace_pressed.emit)
		else:
			key.pressed.connect(letter_pressed.emit.bind(key.text))
