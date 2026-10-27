class_name CryptoUI
extends Control

signal completed
signal progress_changed(completed_count: int, total_count: int)

const NORMAL_COLOR := Color.WHITE
const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const SLOT_SIZE := Vector2(10, 38)
const LETTER_SIZE := Vector2(0, 44)
const SPACE_SIZE := Vector2(16, 44)
const WORD_LETTER_SEPARATION := 4
const HIDDEN_BOX_STYLES: Array[StringName] = [&"normal", &"read_only"]
const LETTER_COLOR_NAMES: Array[StringName] = [&"font_color", &"font_uneditable_color"]
const THEME_LETTER_EMPTY: Theme = preload("res://content/theme/mini_games/crypto/theme_crypto.tres")

@export var flow_container: FlowContainer
@export var hint_label: Label
@export var fix_errors_button: Button
@export var validate_button: Button

var _crypto_data: CryptoData
var _puzzle_index: int = 0
var _puzzle: CryptoPuzzle
var _slots: Dictionary = {}
var _incorrect_indices: Dictionary = {}
var _hidden_box_style := StyleBoxEmpty.new()

func initialize(crypto_data: CryptoData) -> void:
	_crypto_data = crypto_data
	progress_changed.emit(_puzzle_index, _crypto_data.phrases.size())
	fix_errors_button.pressed.connect(_correct_errors)
	validate_button.pressed.connect(_on_validate_button_pressed)
	_load_puzzle()

func _load_puzzle() -> void:
	for child in flow_container.get_children():
		child.queue_free()
	_slots.clear()
	_incorrect_indices.clear()
	_update_fix_errors_button()
	validate_button.hide()
	_puzzle = CryptoMasker.mask(_crypto_data.phrases[_puzzle_index], _crypto_data.hidden_letter_ratio)
	hint_label.text = _puzzle.phrase_data.hint
	var solution := _puzzle.solution()
	var word_box: HBoxContainer = null
	for character_index in solution.length():
		if solution[character_index] == " ":
			flow_container.add_child(_create_space())
			word_box = null
			continue
		if word_box == null:
			word_box = _create_word_box()
			flow_container.add_child(word_box)
		if _puzzle.is_hidden(character_index):
			word_box.add_child(_create_slot(character_index))
		else:
			word_box.add_child(_create_letter(solution[character_index]))
	if _slots.is_empty():
		_advance()
		return
	_focus_first_slot()

func _focus_first_slot() -> void:
	var first_slot: LineEdit = _slots[_sorted_slot_indices()[0]]
	if first_slot.is_inside_tree():
		first_slot.grab_focus()
	else:
		first_slot.grab_focus.call_deferred()

func _correct_errors() -> void:
	var incorrect_indices := _incorrect_indices.keys()
	incorrect_indices.sort()
	for character_index in incorrect_indices:
		var slot: LineEdit = _slots[character_index]
		slot.text = ""
		slot.modulate = NORMAL_COLOR
		_refresh_slot_box(slot)
	_incorrect_indices.clear()
	_update_fix_errors_button()
	if not incorrect_indices.is_empty():
		_slots[incorrect_indices[0]].grab_focus()

func _mark_slot_edited(character_index: int) -> void:
	_slots[character_index].modulate = NORMAL_COLOR
	_incorrect_indices.erase(character_index)
	_update_fix_errors_button()

func _update_fix_errors_button() -> void:
	fix_errors_button.visible = not _incorrect_indices.is_empty()

func _create_space() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = SPACE_SIZE
	return spacer

func _create_word_box() -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", WORD_LETTER_SEPARATION)
	return box

func _create_letter(letter: String) -> Label:
	var label := Label.new()
	label.text = letter
	label.custom_minimum_size = LETTER_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _create_slot(character_index: int) -> CryptoSlot:
	var slot := CryptoSlot.new()
	slot.theme = THEME_LETTER_EMPTY
	slot.custom_minimum_size = SLOT_SIZE
	slot.minimum_click_width = SLOT_SIZE.x
	slot.max_length = 1
	slot.alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.context_menu_enabled = false
	slot.select_all_on_focus = true
	slot.text_changed.connect(_on_slot_text_changed.bind(character_index))
	slot.gui_input.connect(_on_slot_gui_input.bind(character_index))
	slot.focus_entered.connect(_refresh_slot_box.bind(slot))
	slot.focus_exited.connect(_refresh_slot_box.bind(slot))
	_slots[character_index] = slot
	return slot

func _refresh_slot_box(slot: LineEdit) -> void:
	if slot.has_focus() or slot.text == "":
		_show_slot_box(slot)
	else:
		_show_slot_as_letter(slot)

func _show_slot_box(slot: LineEdit) -> void:
	slot.custom_minimum_size = SLOT_SIZE
	slot.expand_to_text_length = false
	slot.remove_theme_constant_override("minimum_character_width")
	slot.remove_theme_constant_override("outline_size")
	slot.remove_theme_color_override("font_outline_color")
	slot.remove_theme_font_override("font")
	slot.remove_theme_font_size_override("font_size")
	for color_name in LETTER_COLOR_NAMES:
		slot.remove_theme_color_override(color_name)
	for style_name in HIDDEN_BOX_STYLES:
		slot.remove_theme_stylebox_override(style_name)

func _show_slot_as_letter(slot: LineEdit) -> void:
	slot.custom_minimum_size = LETTER_SIZE
	slot.expand_to_text_length = true
	slot.add_theme_constant_override("minimum_character_width", 0)
	slot.add_theme_constant_override("outline_size", slot.get_theme_constant("outline_size", "Label"))
	slot.add_theme_color_override("font_outline_color", slot.get_theme_color("font_outline_color", "Label"))
	slot.add_theme_font_override("font", slot.get_theme_font("font", "Label"))
	slot.add_theme_font_size_override("font_size", slot.get_theme_font_size("font_size", "Label"))
	for color_name in LETTER_COLOR_NAMES:
		slot.add_theme_color_override(color_name, slot.get_theme_color("font_color", "Label"))
	for style_name in HIDDEN_BOX_STYLES:
		slot.add_theme_stylebox_override(style_name, _hidden_box_style)

func _on_slot_text_changed(new_text: String, character_index: int) -> void:
	_mark_slot_edited(character_index)
	if new_text != "":
		_focus_next_slot(character_index)
	_refresh_slot_box(_slots[character_index])
	if _is_complete():
		_validate()

func _on_slot_gui_input(event: InputEvent, character_index: int) -> void:
	var slot: LineEdit = _slots[character_index]
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.keycode != KEY_BACKSPACE:
		return
	if not slot.editable or slot.text != "":
		return
	slot.accept_event()
	_clear_previous_slot(character_index)

func _clear_previous_slot(character_index: int) -> void:
	var indices := _sorted_slot_indices()
	var pos := indices.find(character_index)
	if pos <= 0:
		return
	var previous_slot: LineEdit = _slots[indices[pos - 1]]
	previous_slot.text = ""
	_mark_slot_edited(indices[pos - 1])
	previous_slot.grab_focus()

func _focus_next_slot(character_index: int) -> void:
	var indices := _sorted_slot_indices()
	var pos := indices.find(character_index)
	for offset in range(pos + 1, indices.size()):
		if _slots[indices[offset]].text == "":
			_slots[indices[offset]].grab_focus()
			return
	_slots[character_index].release_focus()

func _is_complete() -> bool:
	for character_index in _slots:
		if _slots[character_index].text == "":
			return false
	return true

func _validate() -> void:
	var solution := _puzzle.solution()
	_incorrect_indices.clear()
	for character_index in _slots:
		var slot: LineEdit = _slots[character_index]
		if slot.text.to_upper() == solution[character_index].to_upper():
			slot.modulate = CORRECT_COLOR
		else:
			slot.modulate = INCORRECT_COLOR
			_incorrect_indices[character_index] = true
	_update_fix_errors_button()
	if not _incorrect_indices.is_empty():
		return
	for character_index in _slots:
		_slots[character_index].editable = false
	if _puzzle_index == _crypto_data.phrases.size() - 1:
		_advance()
		return
	validate_button.show()
	validate_button.grab_focus()

func _on_validate_button_pressed() -> void:
	validate_button.hide()
	_advance()

func _advance() -> void:
	_puzzle_index += 1
	progress_changed.emit(_puzzle_index, _crypto_data.phrases.size())
	if _puzzle_index >= _crypto_data.phrases.size():
		completed.emit()
		return
	_load_puzzle()

func _sorted_slot_indices() -> Array:
	var indices := _slots.keys()
	indices.sort()
	return indices
