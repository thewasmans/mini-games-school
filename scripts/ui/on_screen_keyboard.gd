class_name OnScreenKeyboard
extends PanelContainer
## Clavier AZERTY à l'écran, dans un panneau de verre (le clavier physique fonctionne aussi).

signal letter_pressed(letter: String)
signal backspace_pressed

const ROWS: Array[String] = ["AZERTYUIOP", "QSDFGHJKLM", "WXCVBN"]


func _init(key_height := 68.0) -> void:
	theme_type_variation = &"PanelGlass"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	for r in ROWS.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		col.add_child(row)
		for letter in ROWS[r]:
			var key := _key(letter, Vector2(58, key_height))
			key.pressed.connect(func() -> void: letter_pressed.emit(letter))
			row.add_child(key)
		if r == ROWS.size() - 1:
			var back := _key("", Vector2(124, key_height))
			back.icon_kind = "backspace"
			back.pressed.connect(func() -> void: backspace_pressed.emit())
			row.add_child(back)


func _key(letter: String, min_size: Vector2) -> JuicyButton:
	var key := JuicyButton.new(letter, Color("eef0ff"), 30)
	key.skin = &"ButtonKey"
	key.sound = "type"
	key.custom_minimum_size = min_size
	return key
