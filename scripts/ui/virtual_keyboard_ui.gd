class_name VirtualKeyboardUI
extends VBoxContainer

signal letter_pressed(letter: String)
signal erase_pressed

const ROWS: Array[String] = ["AZERTYUIOP", "QSDFGHJKLM", "WXCVBN"]
const ROW_UNITS := 10
const ERASE_KEY_UNITS := 2
const KEY_HEIGHT := 48.0
const KEY_SEPARATION := 4
const KEY_FONT_SIZE := 24
const ERASE_KEY_FONT_SIZE := 16
const ERASE_KEY_TEXT := "Effacer"
const KEY_BOUNCE_SCALE := 1.15
const DISABLED_ALPHA := 0.5

var _keys: Dictionary = {}
var _erase_key: Button
var _enabled := true

func _init() -> void:
	for row_index in ROWS.size():
		var row: String = ROWS[row_index]
		var is_last_row := row_index == ROWS.size() - 1
		var used_units := row.length() + (ERASE_KEY_UNITS if is_last_row else 0)
		var padding_units := (ROW_UNITS - used_units) / 2.0
		var row_box := _create_row()
		_add_padding(row_box, padding_units)
		for letter in row:
			var key := _create_key(letter, 1.0, KEY_FONT_SIZE)
			key.pressed.connect(_press_letter.bind(letter))
			_keys[letter] = key
			row_box.add_child(key)
		if is_last_row:
			_erase_key = _create_key(ERASE_KEY_TEXT, ERASE_KEY_UNITS, ERASE_KEY_FONT_SIZE)
			_erase_key.pressed.connect(_press_erase)
			row_box.add_child(_erase_key)
		_add_padding(row_box, padding_units)

func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	for key in _all_keys():
		key.disabled = not enabled
	modulate.a = 1.0 if enabled else DISABLED_ALPHA

func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not _enabled or not key_event.pressed:
		return
	if key_event.keycode == KEY_BACKSPACE:
		_press_erase()
		get_viewport().set_input_as_handled()
		return
	if key_event.echo or key_event.unicode == 0:
		return
	var letter := LetterNormalizer.base_letter(char(key_event.unicode))
	if not _keys.has(letter):
		return
	_press_letter(letter)
	get_viewport().set_input_as_handled()

func _create_row() -> HBoxContainer:
	var row_box := HBoxContainer.new()
	row_box.add_theme_constant_override("separation", KEY_SEPARATION)
	add_child(row_box)
	return row_box

func _add_padding(row_box: HBoxContainer, units: float) -> void:
	if units <= 0.0:
		return
	var padding := Control.new()
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padding.size_flags_stretch_ratio = units
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_child(padding)

func _create_key(key_text: String, units: float, font_size: int) -> Button:
	var key := Button.new()
	key.text = key_text
	key.custom_minimum_size = Vector2(0, KEY_HEIGHT)
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key.size_flags_stretch_ratio = units
	key.clip_text = true
	key.focus_mode = Control.FOCUS_NONE
	key.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	key.add_theme_font_size_override("font_size", font_size)
	return key

func _all_keys() -> Array:
	var keys := _keys.values()
	keys.append(_erase_key)
	return keys

func _press_letter(letter: String) -> void:
	UIFeedback.bounce(_keys[letter], KEY_BOUNCE_SCALE)
	letter_pressed.emit(letter)

func _press_erase() -> void:
	UIFeedback.bounce(_erase_key, KEY_BOUNCE_SCALE)
	erase_pressed.emit()
