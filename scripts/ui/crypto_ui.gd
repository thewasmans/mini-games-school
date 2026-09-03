class_name CryptoUI
extends Control

signal completed

const NORMAL_COLOR := Color.WHITE
const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const SLOT_SIZE := Vector2(32, 44)
const LETTER_SIZE := Vector2(24, 44)
const SPACE_SIZE := Vector2(16, 44)
const REVEAL_DELAY := 0.6

@export var flow_container: FlowContainer
@export var hint_label: Label

var _crypto_data: CryptoData
var _puzzle_index: int = 0
var _puzzle: CryptoPuzzle
var _slots: Dictionary = {}

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

func _create_slot(character_index: int) -> LineEdit:
	var slot := LineEdit.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.max_length = 1
	slot.alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.context_menu_enabled = false
	slot.text_changed.connect(_on_slot_text_changed.bind(character_index))
	_slots[character_index] = slot
	return slot

func _on_slot_text_changed(new_text: String, character_index: int) -> void:
	_set_slots_color(NORMAL_COLOR)
	if new_text != "":
		_focus_next_slot(character_index)
	if _is_complete():
		_validate()

func _focus_next_slot(character_index: int) -> void:
	var indices := _sorted_slot_indices()
	var pos := indices.find(character_index)
	for offset in range(pos + 1, indices.size()):
		if _slots[indices[offset]].text == "":
			_slots[indices[offset]].grab_focus()
			return

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
