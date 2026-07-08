class_name CrosswordUI
extends Control

const CELL_SIZE := Vector2(40, 40)
const NORMAL_COLOR := Color.WHITE
const SELECTED_COLOR := Color(0.7, 0.85, 1.0)
const CURRENT_COLOR := Color(1.0, 0.8, 0.3)
const HOVER_COLOR := Color(0.88, 0.94, 1.0)

@export var grid_container: GridContainer
@export var hint_label: Label
@export var input: LineEdit

var _cells: Dictionary = {}
var _cell_backgrounds: Dictionary = {}
var _cell_placements: Dictionary = {}
var _placement_attempts: Dictionary = {}
var _selected_placement: CrosswordWordPlacement

func initialize(crossword_data: CrosswordData) -> void:
	var placements := CrosswordGenerator.generate(crossword_data.clues)
	_render_grid(placements)
	input.text_changed.connect(_on_word_input_changed)

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
	var background := StyleBoxFlat.new()
	background.bg_color = NORMAL_COLOR
	cell.add_theme_stylebox_override("normal", background)
	cell.add_theme_stylebox_override("hover", background)
	cell.add_theme_stylebox_override("pressed", background)
	cell.add_theme_color_override("font_color", Color.BLACK)
	cell.add_theme_color_override("font_hover_color", Color.BLACK)
	cell.pressed.connect(_on_cell_pressed.bind(pos))
	cell.mouse_entered.connect(_on_cell_mouse_entered.bind(pos))
	cell.mouse_exited.connect(_on_cell_mouse_exited.bind(pos))
	_cells[pos] = cell
	_cell_backgrounds[pos] = background
	return cell

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
	_update_word_cells(attempt)
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
			_cell_backgrounds[pos].bg_color = color

func _clear_selection_color() -> void:
	if _selected_placement == null:
		return
	_set_word_color(_selected_placement, NORMAL_COLOR)

func _update_current_cell_color(current_index: int) -> void:
	for letter_index in _selected_placement.word_data.word.length():
		var pos := _selected_placement.cell_position(letter_index)
		if not _cell_backgrounds.has(pos):
			continue
		_cell_backgrounds[pos].bg_color = CURRENT_COLOR if letter_index == current_index else SELECTED_COLOR

func _update_word_cells(new_text: String) -> void:
	var word := _selected_placement.word_data.word
	for letter_index in word.length():
		var pos := _selected_placement.cell_position(letter_index)
		if not _cells.has(pos):
			continue
		_cells[pos].text = new_text[letter_index].to_upper() if letter_index < new_text.length() else ""

func _on_word_input_changed(new_text: String) -> void:
	if _selected_placement == null:
		return
	_update_word_cells(new_text)
	_update_current_cell_color(new_text.length())
	if new_text.length() == _selected_placement.word_data.word.length():
		_validate_word(new_text)

func _validate_word(submitted_text: String) -> void:
	if submitted_text.strip_edges().to_upper() != _selected_placement.word_data.word:
		input.text = ""
		_update_word_cells("")
		_update_current_cell_color(0)
		return
	_placement_attempts[_selected_placement] = _selected_placement.word_data.word
	_clear_selection_color()
	_selected_placement = null
	hint_label.text = ""
	input.text = ""
