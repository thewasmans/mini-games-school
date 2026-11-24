class_name CrosswordUI
extends Control

signal completed
signal progress_changed(completed_count: int, total_count: int)

const CELL_SIZE := Vector2(40, 40)
const NORMAL_COLOR := Color.WHITE
const SELECTED_COLOR := Color(0.7, 0.85, 1.0)
const CURRENT_COLOR := Color(1.0, 0.8, 0.3)
const HOVER_COLOR := Color(0.88, 0.94, 1.0)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const SUCCESS_POP_SCALE := 1.35
const SUCCESS_FLASH_COLOR := Color(1.6, 1.6, 1.6)
const SUCCESS_LETTER_STAGGER := 0.05
const VICTORY_POP_SCALE := 1.25
const VICTORY_FLASH_COLOR := Color(1.5, 1.3, 0.6)
const VICTORY_WAVE_STAGGER := 0.04
const VICTORY_END_DELAY := 0.6

@export var grid_area: Control
@export var grid_container: GridContainer
@export var hint_frame: Control
@export var hint_label: Label
@export var previous_word_button: TextureButton
@export var next_word_button: TextureButton
@export var keyboard_panel: Control
@export var hint_line_scroll: ScrollContainer
@export var hint_line_label: Label
@export var keyboard: VirtualKeyboardUI
@export var tile_letter_theme: Theme
@export var tile_letter_validated_theme: Theme

var _cells: Dictionary = {}
var _cell_placements: Dictionary = {}
var _letters: Dictionary = {}
var _locked_cells: Dictionary = {}
var _solved_placements: Dictionary = {}
var _selected_placement: CrosswordWordPlacement
var _hovered_placement: CrosswordWordPlacement
var _cursor_index: int = 0
var _word_count: int
var _is_completed := false
var _default_hint: String
var _ordered_placements: Array[CrosswordWordPlacement] = []

func initialize(crossword_data: CrosswordData) -> void:
	var placements := crossword_data.build_placements()
	_word_count = placements.size()
	_default_hint = hint_label.text
	progress_changed.emit(0, _word_count)
	_render_grid(placements)
	grid_area.resized.connect(_fit_grid_to_area)
	grid_area.gui_input.connect(_on_grid_area_gui_input)
	grid_container.minimum_size_changed.connect(_fit_grid_to_area)
	_fit_grid_to_area()
	keyboard.letter_pressed.connect(_on_letter_pressed)
	keyboard.erase_pressed.connect(_on_erase_pressed)
	_ordered_placements = placements.duplicate()
	_ordered_placements.sort_custom(_is_before_in_reading_order)
	next_word_button.texture_normal = _mirrored(previous_word_button.texture_normal)
	previous_word_button.pressed.connect(_select_adjacent_word.bind(-1))
	next_word_button.pressed.connect(_select_adjacent_word.bind(1))
	_set_keyboard_shown(false)

func _is_before_in_reading_order(a: CrosswordWordPlacement, b: CrosswordWordPlacement) -> bool:
	if a.start.y != b.start.y:
		return a.start.y < b.start.y
	if a.start.x != b.start.x:
		return a.start.x < b.start.x
	return a.is_horizontal and not b.is_horizontal

func _mirrored(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	image.flip_x()
	return ImageTexture.create_from_image(image)

func _select_adjacent_word(step: int) -> void:
	var unsolved := _ordered_placements.filter(func(placement: CrosswordWordPlacement) -> bool: return not _solved_placements.has(placement))
	if unsolved.is_empty():
		return
	var current_index := unsolved.find(_selected_placement)
	var next_index := (0 if step > 0 else unsolved.size() - 1) if current_index == -1 else posmod(current_index + step, unsolved.size())
	var next_placement: CrosswordWordPlacement = unsolved[next_index]
	_select_placement(next_placement, next_placement.cell_position(_first_open_index(next_placement)))
	_set_keyboard_shown(false)

func _set_keyboard_shown(is_shown: bool) -> void:
	keyboard.set_enabled(is_shown and not _is_completed)
	keyboard_panel.visible = is_shown and not _is_completed
	hint_frame.visible = not is_shown and not _is_completed

func _set_hint(text: String) -> void:
	hint_label.text = text
	hint_line_label.text = text
	hint_line_scroll.scroll_horizontal = 0

func _on_grid_area_gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null and mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		_set_keyboard_shown(false)

func is_placement_solved(placement: CrosswordWordPlacement) -> bool:
	return _solved_placements.has(placement)

func _fit_grid_to_area() -> void:
	var grid_size := grid_container.get_combined_minimum_size()
	if grid_size.x <= 0.0 or grid_size.y <= 0.0:
		return
	grid_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	var fit_scale := minf(1.0, minf(grid_area.size.x / grid_size.x, grid_area.size.y / grid_size.y))
	grid_container.pivot_offset = grid_size / 2.0
	grid_container.scale = Vector2.ONE * fit_scale

func _clear_grid() -> void:
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()

func _render_grid(placements: Array[CrosswordWordPlacement]) -> void:
	_clear_grid()
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
				spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
				grid_container.add_child(spacer)

func _create_cell(pos: Vector2i) -> Button:
	var cell := Button.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.focus_mode = Control.FOCUS_NONE
	cell.theme = tile_letter_theme
	_apply_letter_color(cell)
	cell.pressed.connect(_on_cell_pressed.bind(pos))
	cell.mouse_entered.connect(_on_cell_mouse_entered.bind(pos))
	cell.mouse_exited.connect(_on_cell_mouse_exited.bind(pos))
	_cells[pos] = cell
	return cell

func _apply_letter_color(cell: Button) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		cell.add_theme_color_override(state, Color.WHITE)

func _on_cell_pressed(pos: Vector2i) -> void:
	var candidates := _unsolved_placements_at(pos)
	if candidates.is_empty():
		return
	if _selected_placement in candidates:
		if _cursor_position() == pos and candidates.size() > 1:
			var next_index := (candidates.find(_selected_placement) + 1) % candidates.size()
			_select_placement(candidates[next_index], pos)
			return
		_move_cursor_to(pos)
		return
	_select_placement(candidates[0], pos)

func _unsolved_placements_at(pos: Vector2i) -> Array:
	return _cell_placements[pos].filter(func(placement: CrosswordWordPlacement) -> bool: return not _solved_placements.has(placement))

func _select_placement(placement: CrosswordWordPlacement, pos: Vector2i) -> void:
	_selected_placement = placement
	_cursor_index = _index_in(placement, pos)
	if _locked_cells.has(_cursor_position()):
		_cursor_index = _first_open_index(placement)
	var direction := "Horizontal" if placement.is_horizontal else "Vertical"
	_set_hint("(%s) %s" % [direction, placement.word_data.hint])
	_set_keyboard_shown(true)
	_refresh_colors()

func _move_cursor_to(pos: Vector2i) -> void:
	_set_keyboard_shown(true)
	if _locked_cells.has(pos):
		return
	_cursor_index = _index_in(_selected_placement, pos)
	_refresh_colors()

func _index_in(placement: CrosswordWordPlacement, pos: Vector2i) -> int:
	for letter_index in placement.word_data.word.length():
		if placement.cell_position(letter_index) == pos:
			return letter_index
	return 0

func _first_open_index(placement: CrosswordWordPlacement) -> int:
	var first_unlocked_index := -1
	for letter_index in placement.word_data.word.length():
		var pos := placement.cell_position(letter_index)
		if _locked_cells.has(pos):
			continue
		if not _letters.has(pos):
			return letter_index
		if first_unlocked_index == -1:
			first_unlocked_index = letter_index
	return maxi(first_unlocked_index, 0)

func _next_open_index(from_index: int, step: int) -> int:
	var letter_index := from_index + step
	while letter_index >= 0 and letter_index < _selected_placement.word_data.word.length():
		if not _locked_cells.has(_selected_placement.cell_position(letter_index)):
			return letter_index
		letter_index += step
	return -1

func _cursor_position() -> Vector2i:
	return _selected_placement.cell_position(_cursor_index)

func _on_cell_mouse_entered(pos: Vector2i) -> void:
	var candidates := _unsolved_placements_at(pos)
	_hovered_placement = candidates[0] if not candidates.is_empty() else null
	_refresh_colors()

func _on_cell_mouse_exited(_pos: Vector2i) -> void:
	_hovered_placement = null
	_refresh_colors()

func _refresh_colors() -> void:
	for pos in _cells:
		_cells[pos].modulate = NORMAL_COLOR
	if _hovered_placement != null and _hovered_placement != _selected_placement:
		_set_word_color(_hovered_placement, HOVER_COLOR)
	if _selected_placement == null:
		return
	for letter_index in _selected_placement.word_data.word.length():
		var pos := _selected_placement.cell_position(letter_index)
		_cells[pos].modulate = CURRENT_COLOR if letter_index == _cursor_index else SELECTED_COLOR

func _set_word_color(placement: CrosswordWordPlacement, color: Color) -> void:
	for letter_index in placement.word_data.word.length():
		_cells[placement.cell_position(letter_index)].modulate = color

func _set_letter(pos: Vector2i, letter: String, animate: bool) -> void:
	if letter.is_empty():
		_letters.erase(pos)
	else:
		_letters[pos] = letter
	var cell: Button = _cells[pos]
	if animate and not letter.is_empty() and cell.text != letter:
		_animate_letter(cell)
	cell.text = letter

func _animate_letter(cell: Control) -> void:
	var tween := UIFeedback.create_tween_for(cell)
	cell.scale = Vector2(0.4, 0.4)
	cell.modulate.a = 0.0
	tween.set_parallel(true)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cell, "modulate:a", 1.0, .15)

func _play_incorrect_feedback(placement: CrosswordWordPlacement) -> void:
	for letter_index in placement.word_data.word.length():
		UIFeedback.shake(_cells[placement.cell_position(letter_index)])

func _play_success_feedback(placement: CrosswordWordPlacement) -> void:
	for letter_index in placement.word_data.word.length():
		var cell: Control = _cells[placement.cell_position(letter_index)]
		UIFeedback.pop(cell, letter_index * SUCCESS_LETTER_STAGGER, SUCCESS_POP_SCALE, SUCCESS_FLASH_COLOR, NORMAL_COLOR)

func _play_victory_feedback() -> float:
	var positions: Array = _cells.keys()
	var min_diagonal: int = positions[0].x + positions[0].y
	var max_diagonal: int = min_diagonal
	for pos in positions:
		min_diagonal = mini(min_diagonal, pos.x + pos.y)
		max_diagonal = maxi(max_diagonal, pos.x + pos.y)
	for pos in positions:
		UIFeedback.pop(_cells[pos], (pos.x + pos.y - min_diagonal) * VICTORY_WAVE_STAGGER, VICTORY_POP_SCALE, VICTORY_FLASH_COLOR, NORMAL_COLOR)
	UIFeedback.spawn_confetti(self, UIFeedback.center_in(self, grid_area))
	return (max_diagonal - min_diagonal) * VICTORY_WAVE_STAGGER + UIFeedback.POP_DURATION + VICTORY_END_DELAY

func _on_letter_pressed(letter: String) -> void:
	if _selected_placement == null:
		return
	var pos := _cursor_position()
	if _locked_cells.has(pos):
		return
	_set_letter(pos, letter, true)
	var next_index := _next_open_index(_cursor_index, 1)
	if next_index != -1:
		_cursor_index = next_index
	_refresh_colors()
	_check_placement(_selected_placement)

func _on_erase_pressed() -> void:
	if _selected_placement == null:
		return
	var pos := _cursor_position()
	if _letters.has(pos) and not _locked_cells.has(pos):
		_set_letter(pos, "", false)
	else:
		var previous_index := _next_open_index(_cursor_index, -1)
		if previous_index == -1:
			return
		_cursor_index = previous_index
		_set_letter(_cursor_position(), "", false)
	_refresh_colors()

func _typed_word(placement: CrosswordWordPlacement) -> String:
	var typed := ""
	for letter_index in placement.word_data.word.length():
		var pos := placement.cell_position(letter_index)
		if not _letters.has(pos):
			return ""
		typed += _letters[pos]
	return typed

func _check_placement(placement: CrosswordWordPlacement) -> void:
	var typed := _typed_word(placement)
	if typed.is_empty():
		return
	if not LetterNormalizer.matches(typed, placement.word_data.word):
		_set_word_color(placement, INCORRECT_COLOR)
		_play_incorrect_feedback(placement)
		return
	_solve_placement(placement)
	_finish_if_completed()

func _solve_placement(placement: CrosswordWordPlacement) -> void:
	_solved_placements[placement] = true
	var word := placement.word_data.word
	for letter_index in word.length():
		var pos := placement.cell_position(letter_index)
		_set_letter(pos, word[letter_index].to_upper(), false)
		_locked_cells[pos] = true
		_cells[pos].theme = tile_letter_validated_theme
	if placement == _selected_placement:
		_selected_placement = null
		_set_hint(_default_hint)
		_set_keyboard_shown(false)
	_refresh_colors()
	_play_success_feedback(placement)
	progress_changed.emit(_solved_placements.size(), _word_count)
	_solve_words_completed_by_crossings()

func _solve_words_completed_by_crossings() -> void:
	for placements in _cell_placements.values():
		for placement: CrosswordWordPlacement in placements:
			if _solved_placements.has(placement):
				continue
			var typed := _typed_word(placement)
			if not typed.is_empty() and LetterNormalizer.matches(typed, placement.word_data.word):
				_solve_placement(placement)

func _finish_if_completed() -> void:
	if _is_completed or _solved_placements.size() < _word_count:
		return
	_is_completed = true
	_set_keyboard_shown(false)
	var victory_duration := _play_victory_feedback()
	await get_tree().create_timer(victory_duration).timeout
	completed.emit()
