class_name CryptoUI
extends Control

signal completed

const NORMAL_COLOR := Color.WHITE
const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const SLOT_SIZE := Vector2(26, 38)
const LETTER_SIZE := Vector2(0, 44)
const SPACE_SIZE := Vector2(16, 44)
const REVEAL_DELAY := 0.6
const HIDDEN_BOX_STYLES: Array[StringName] = [&"normal", &"read_only"]
const LETTER_COLOR_NAMES: Array[StringName] = [&"font_color", &"font_uneditable_color"]

@export var flow_container: FlowContainer
@export var hint_label: Label

var _crypto_data: CryptoData
var _puzzle_index: int = 0
var _puzzle: CryptoPuzzle
var _slots: Dictionary = {}
var _hidden_box_style := StyleBoxEmpty.new()

func initialize(crypto_data: CryptoData) -> void:
	_crypto_data = crypto_data
	_load_puzzle()

func _load_puzzle() -> void:
	for child in flow_container.get_children():
		child.queue_free()
	_slots.clear()
	_puzzle = CryptoMasker.mask(_crypto_data.phrases[_puzzle_index], _crypto_data.hidden_letter_ratio)
	hint_label.text = _puzzle.phrase_data.hint
	var solution := _puzzle.solution()
	for character_index in solution.length():
		if solution[character_index] == " ":
			flow_container.add_child(_create_space())
		elif _puzzle.is_hidden(character_index):
			flow_container.add_child(_create_slot(character_index))
		else:
			flow_container.add_child(_create_letter(solution[character_index]))
	if _slots.is_empty():
		_advance()
		return
	var first_slot: LineEdit = _slots[_sorted_slot_indices()[0]]
	if first_slot.is_inside_tree():
		first_slot.grab_focus()
	else:
		first_slot.grab_focus.call_deferred()

func _create_space() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = SPACE_SIZE
	return spacer

func _create_letter(letter: String) -> Label:
	var label := Label.new()
	label.text = letter
	label.custom_minimum_size = LETTER_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _create_slot(character_index: int) -> CryptoSlot:
	var slot := CryptoSlot.new()
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
	_set_slots_color(NORMAL_COLOR)
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
	_set_slots_color(NORMAL_COLOR)
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
	for character_index in _slots:
		if _slots[character_index].text.to_upper() != solution[character_index].to_upper():
			_set_slots_color(INCORRECT_COLOR)
			return
	_set_slots_color(CORRECT_COLOR)
	for character_index in _slots:
		_slots[character_index].editable = false
	await get_tree().create_timer(REVEAL_DELAY).timeout
	_advance()

func _advance() -> void:
	_puzzle_index += 1
	if _puzzle_index >= _crypto_data.phrases.size():
		completed.emit()
		return
	_load_puzzle()

func _set_slots_color(color: Color) -> void:
	for character_index in _slots:
		_slots[character_index].modulate = color

func _sorted_slot_indices() -> Array:
	var indices := _slots.keys()
	indices.sort()
	return indices
