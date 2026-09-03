class_name CrosswordUI
extends Control

signal completed

const CELL_SIZE := Vector2(40, 40)
const NORMAL_COLOR := Color.WHITE
const SELECTED_COLOR := Color(0.7, 0.85, 1.0)
const CURRENT_COLOR := Color(1.0, 0.8, 0.3)
const HOVER_COLOR := Color(0.88, 0.94, 1.0)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const TILE_LETTER_THEME := preload("res://content/theme/tile_letter/theme_tile_letter.tres")
const TILE_LETTER_VALIDATED_THEME := preload("res://content/theme/tile_letter/theme_tile_letter_validated.tres")

@export var grid_container: GridContainer
@export var hint_label: Label
@export var input: LineEdit

var _cells: Dictionary = {}
var _cell_backgrounds: Dictionary = {}
var _cell_placements: Dictionary = {}
var _placement_attempts: Dictionary = {}
var _selected_placement: CrosswordWordPlacement
var _word_count: int
var _solved_count: int = 0

func initialize(crossword_data: CrosswordData) -> void:
	var placements := CrosswordGenerator.generate(crossword_data.clues)
	_word_count = placements.size()
	_render_grid(placements)
	input.text_changed.connect(_on_word_input_changed)
	input.text_submitted.connect(_on_word_input_submitted)

func _render_grid(placements: Array[CrosswordWordPlacement]) -> void:
	var letter_positions: Dictionary = {}
	for placement in placements:
		for letter_index in placement.word_data.word.length():
			var pos := placement.cell_position(letter_index)
			letter_positions[pos] = true
			if not _cell_placements.has(pos):
				_cell_placements[pos] = []
			_cell_placements[pos].append(placement)
	if letter_positions.is_empty():
		return
	var positions: Array = letter_positions.keys()
	var min_x: int = positions[0].x
	var max_x: int = positions[0].x
	var min_y: int = positions[0].y
	var max_y: int = positions[0].y
	for pos in positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	grid_container.columns = max_x - min_x + 1
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var pos := Vector2i(x, y)
			if letter_positions.has(pos):
				grid_container.add_child(_create_cell(pos))
			else:
				var spacer := Control.new()
				spacer.custom_minimum_size = CELL_SIZE
				grid_container.add_child(spacer)

func _create_cell(pos: Vector2i) -> Button:
	var cell := Button.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.focus_mode = Control.FOCUS_NONE
	cell.theme = TILE_LETTER_THEME
	_apply_letter_color(cell)
	cell.pressed.connect(_on_cell_pressed.bind(pos))
	cell.mouse_entered.connect(_on_cell_mouse_entered.bind(pos))
	cell.mouse_exited.connect(_on_cell_mouse_exited.bind(pos))
	_cells[pos] = cell
	_cell_backgrounds[pos] = cell
	return cell

func _apply_letter_color(cell: Button) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		cell.add_theme_color_override(state, Color.WHITE)

func _on_cell_pressed(pos: Vector2i) -> void:
	var placements: Array = _cell_placements[pos]
	var next_placement: CrosswordWordPlacement = placements[0]
	if placements.size() > 1 and _selected_placement in placements:
		var current_index: int = placements.find(_selected_placement)
		next_placement = placements[(current_index + 1) % placements.size()]
	_select_placement(next_placement)

func _select_placement(placement: CrosswordWordPlacement) -> void:
	if _selected_placement != null:
		_placement_attempts[_selected_placement] = input.text
	_clear_selection_color()
	_selected_placement = placement
	input.max_length = placement.word_data.word.length()
	var attempt: String = _placement_attempts.get(placement, "")
	input.text = attempt
	input.caret_column = attempt.length()
	_update_word_cells(attempt, false)
	_update_current_cell_color(attempt.length())
	var direction := "Horizontal" if placement.is_horizontal else "Vertical"
	hint_label.text = "(%s) %s" % [direction, placement.word_data.hint]
	input.grab_focus()

func _on_cell_mouse_entered(pos: Vector2i) -> void:
	_set_word_color(_cell_placements[pos][0], HOVER_COLOR)

func _on_cell_mouse_exited(pos: Vector2i) -> void:
	var placement: CrosswordWordPlacement = _cell_placements[pos][0]
	if placement == _selected_placement:
		_update_current_cell_color(input.text.length())
	else:
		_set_word_color(placement, NORMAL_COLOR)

func _set_word_color(placement: CrosswordWordPlacement, color: Color) -> void:
	for letter_index in placement.word_data.word.length():
		var pos := placement.cell_position(letter_index)
		if _cell_backgrounds.has(pos):
			_cell_backgrounds[pos].modulate = color

func _clear_selection_color() -> void:
	if _selected_placement == null:
		return
	_set_word_color(_selected_placement, NORMAL_COLOR)

func _update_current_cell_color(current_index: int) -> void:
	for letter_index in _selected_placement.word_data.word.length():
		var pos := _selected_placement.cell_position(letter_index)
		if not _cell_backgrounds.has(pos):
			continue
		_cell_backgrounds[pos].modulate = CURRENT_COLOR if letter_index == current_index else SELECTED_COLOR

func _update_word_cells(new_text: String, animate: bool = true) -> void:
	var word := _selected_placement.word_data.word
	for letter_index in word.length():
		var pos := _selected_placement.cell_position(letter_index)
		if not _cells.has(pos):
			continue
		var cell: Button = _cells[pos]
		var letter := new_text[letter_index].to_upper() if letter_index < new_text.length() else ""
		if animate and letter != "" and cell.text != letter:
			_animate_letter(cell)
		cell.text = letter

func _animate_letter(cell: Control) -> void:
	if cell.has_meta("bounce_tween"):
		var previous_tween: Tween = cell.get_meta("bounce_tween")
		if previous_tween != null and previous_tween.is_valid():
			previous_tween.kill()
	cell.pivot_offset = CELL_SIZE / 2.0
	cell.scale = Vector2(0.4, 0.4)
	cell.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cell, "modulate:a", 1.0, .15)
	cell.set_meta("bounce_tween", tween)

func _on_word_input_changed(new_text: String) -> void:
	if _selected_placement == null:
		return
	_update_word_cells(new_text)
	_update_current_cell_color(new_text.length())
	if new_text.length() == _selected_placement.word_data.word.length():
		_validate_word(new_text)

func _on_word_input_submitted(_new_text: String) -> void:
	input.grab_focus()

func _validate_word(submitted_text: String) -> void:
	if submitted_text.strip_edges().to_upper() != _selected_placement.word_data.word:
		_set_word_color(_selected_placement, INCORRECT_COLOR)
		return
	_placement_attempts[_selected_placement] = _selected_placement.word_data.word
	_clear_selection_color()
	for letter_index in _selected_placement.word_data.word.length():
		var pos := _selected_placement.cell_position(letter_index)
		if _cells.has(pos):
			_cells[pos].theme = TILE_LETTER_VALIDATED_THEME
	_selected_placement = null
	hint_label.text = ""
	input.text = ""
	_solved_count += 1
	if _solved_count == _word_count:
		completed.emit()
