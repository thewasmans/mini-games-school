class_name CryptoUI
extends Control

signal completed
signal progress_changed(completed_count: int, total_count: int)

const NORMAL_COLOR := Color.WHITE
const TYPED_BOUNCE_SCALE := 1.3
const CORRECT_FLASH_COLOR := Color(1.5, 1.9, 1.5)
const CORRECT_POP_SCALE := 1.3
const SUCCESS_LETTER_STAGGER := 0.04
const COMPLETED_DELAY := 0.8
const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const LETTER_SIZE := Vector2(0, 44)
const SPACE_SIZE := Vector2(16, 44)
const WORD_LETTER_SEPARATION := 4
const NO_SELECTION := -1
const THEME_SLOT: Theme = preload("res://content/theme/mini_games/crypto/theme_crypto.tres")

@export var flow_container: FlowContainer
@export var hint_label: Label
@export var fix_errors_button: Button
@export var validate_button: Button
@export var keyboard: VirtualKeyboardUI

var _crypto_data: CryptoData
var _puzzle_index: int = 0
var _puzzle: CryptoPuzzle
var _slots: Dictionary = {}
var _incorrect_indices: Dictionary = {}
var _selected_index: int = NO_SELECTION
var _locked := false

func initialize(crypto_data: CryptoData) -> void:
	_crypto_data = crypto_data
	progress_changed.emit(_puzzle_index, _crypto_data.phrases.size())
	fix_errors_button.pressed.connect(_correct_errors)
	validate_button.pressed.connect(_on_validate_button_pressed)
	keyboard.letter_pressed.connect(_on_letter_pressed)
	keyboard.erase_pressed.connect(_on_erase_pressed)
	_load_puzzle()

func _load_puzzle() -> void:
	for child in flow_container.get_children():
		child.queue_free()
	_slots.clear()
	_incorrect_indices.clear()
	_selected_index = NO_SELECTION
	_locked = false
	keyboard.set_enabled(true)
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
	_select_slot(_sorted_slot_indices()[0])

func _select_slot(character_index: int) -> void:
	if _locked:
		return
	if _slots.has(_selected_index):
		_slots[_selected_index].selected = false
	_selected_index = character_index
	_slots[character_index].selected = true

func _clear_selection() -> void:
	if _slots.has(_selected_index):
		_slots[_selected_index].selected = false
	_selected_index = NO_SELECTION

func _on_letter_pressed(letter: String) -> void:
	if _locked or not _slots.has(_selected_index):
		return
	var character_index := _selected_index
	var slot: CryptoSlot = _slots[character_index]
	slot.set_letter(_displayed_letter(letter, character_index))
	_mark_slot_edited(character_index)
	UIFeedback.bounce(slot, TYPED_BOUNCE_SCALE)
	_select_next_empty_slot(character_index)
	if _is_complete():
		_validate()

func _on_erase_pressed() -> void:
	if _locked or not _slots.has(_selected_index):
		return
	var slot: CryptoSlot = _slots[_selected_index]
	if slot.text != "":
		_clear_slot(_selected_index)
		return
	var indices := _sorted_slot_indices()
	var pos := indices.find(_selected_index)
	if pos <= 0:
		return
	var previous_index: int = indices[pos - 1]
	_clear_slot(previous_index)
	_select_slot(previous_index)

func _clear_slot(character_index: int) -> void:
	_slots[character_index].set_letter("")
	_mark_slot_edited(character_index)

func _displayed_letter(letter: String, character_index: int) -> String:
	var expected := _puzzle.solution()[character_index]
	return letter.to_lower() if expected == expected.to_lower() else letter

func _select_next_empty_slot(character_index: int) -> void:
	var indices := _sorted_slot_indices()
	var pos := indices.find(character_index)
	for offset in range(1, indices.size()):
		var candidate: int = indices[(pos + offset) % indices.size()]
		if _slots[candidate].text == "":
			_select_slot(candidate)
			return
	_clear_selection()

func _correct_errors() -> void:
	var incorrect_indices := _incorrect_indices.keys()
	incorrect_indices.sort()
	for character_index in incorrect_indices:
		_slots[character_index].set_letter("")
		_slots[character_index].modulate = NORMAL_COLOR
	_incorrect_indices.clear()
	_update_fix_errors_button()
	if not incorrect_indices.is_empty():
		_select_slot(incorrect_indices[0])

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
	slot.theme = THEME_SLOT
	slot.pressed.connect(_select_slot.bind(character_index))
	_slots[character_index] = slot
	return slot

func _is_complete() -> bool:
	for character_index in _slots:
		if _slots[character_index].text == "":
			return false
	return true

func _validate() -> void:
	var solution := _puzzle.solution()
	_incorrect_indices.clear()
	var sorted_indices := _sorted_slot_indices()
	for slot_order in sorted_indices.size():
		var character_index: int = sorted_indices[slot_order]
		var slot: CryptoSlot = _slots[character_index]
		if LetterNormalizer.matches(slot.text, solution[character_index]):
			slot.set_letter(solution[character_index])
			UIFeedback.pop(slot, slot_order * SUCCESS_LETTER_STAGGER, CORRECT_POP_SCALE, CORRECT_FLASH_COLOR, CORRECT_COLOR)
		else:
			slot.modulate = INCORRECT_COLOR
			UIFeedback.shake(slot)
			_incorrect_indices[character_index] = true
	_update_fix_errors_button()
	if not _incorrect_indices.is_empty():
		UIFeedback.appear(fix_errors_button, 0.0)
		return
	_clear_selection()
	_locked = true
	keyboard.set_enabled(false)
	var success_duration := sorted_indices.size() * SUCCESS_LETTER_STAGGER + UIFeedback.POP_DURATION
	if _puzzle_index == _crypto_data.phrases.size() - 1:
		UIFeedback.spawn_confetti(self, size / 2.0)
		await get_tree().create_timer(success_duration + COMPLETED_DELAY).timeout
		_advance()
		return
	validate_button.show()
	UIFeedback.appear(validate_button, success_duration)
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
