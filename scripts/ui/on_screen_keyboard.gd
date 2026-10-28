class_name OnScreenKeyboard
extends VBoxContainer
## Clavier AZERTY à l'écran (le clavier physique fonctionne aussi).

signal letter_pressed(letter: String)
signal backspace_pressed

const ROWS: Array[String] = ["AZERTYUIOP", "QSDFGHJKLM", "WXCVBN"]
const KEY_COLOR := Color("eef1ff")


func _init(key_height := 72.0) -> void:
	add_theme_constant_override("separation", 8)
	for r in ROWS.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		add_child(row)
		for letter in ROWS[r]:
			var key := _key(letter, Vector2(60, key_height))
			key.pressed.connect(func() -> void: letter_pressed.emit(letter))
			row.add_child(key)
		if r == ROWS.size() - 1:
			var back := _key("", Vector2(128, key_height))
			back.icon_kind = "back"
			back.color = UIStyle.RED
			back.pressed.connect(func() -> void: backspace_pressed.emit())
			row.add_child(back)


func _key(letter: String, min_size: Vector2) -> JuicyButton:
	var key := JuicyButton.new(letter, KEY_COLOR, 30)
	key.sound = "type"
	key.padding = 2
	key.custom_minimum_size = min_size
	key.add_theme_color_override("font_color", UIStyle.INK)
	key.add_theme_color_override("font_hover_color", UIStyle.INK)
	key.add_theme_color_override("font_pressed_color", UIStyle.INK)
	key.add_theme_color_override("font_hover_pressed_color", UIStyle.INK)
	key.add_theme_constant_override("outline_size", 0)
	key.add_theme_constant_override("shadow_outline_size", 0)
	key.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return key
