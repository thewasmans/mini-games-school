@tool
extends Control

const CELL_SIZE := 36.0
const LETTER_FONT_SIZE := 18
const NUMBER_FONT_SIZE := 10
const CELL_COLOR := Color(0.93, 0.93, 0.93)
const ISOLATED_CELL_COLOR := Color(1.0, 0.75, 0.45)
const CONFLICT_CELL_COLOR := Color(1.0, 0.45, 0.45)
const BORDER_COLOR := Color(0.2, 0.2, 0.2)
const LETTER_COLOR := Color(0.1, 0.1, 0.1)
const NUMBER_COLOR := Color(0.4, 0.4, 0.4)
const EMPTY_CELL_COLOR := Color(1.0, 1.0, 1.0, 0.04)
const EMPTY_BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.12)
const HIGHLIGHTED_CELL_COLOR := Color(0.55, 0.78, 1.0)
const HIGHLIGHTED_BORDER_COLOR := Color(0.2, 0.55, 1.0)
const HIGHLIGHTED_BORDER_WIDTH := 3.0

var isolated_placements: Array[CrosswordWordPlacement] = []
var conflict_cells: Dictionary = {}
var show_full_grid := false:
	set(value):
		show_full_grid = value
		queue_redraw()
var highlighted_placement: CrosswordWordPlacement:
	set(value):
		highlighted_placement = value
		_highlighted_cells.clear()
		if highlighted_placement != null:
			for letter_index in highlighted_placement.word_data.word.length():
				_highlighted_cells[highlighted_placement.cell_position(letter_index)] = true
		queue_redraw()
var _letters: Dictionary = {}
var _isolated_cells: Dictionary = {}
var _start_numbers: Dictionary = {}
var _highlighted_cells: Dictionary = {}
var _origin := Vector2i.ZERO
var _grid_size := Vector2i.ZERO

func set_placements(placements: Array[CrosswordWordPlacement]) -> void:
	_letters.clear()
	_isolated_cells.clear()
	_start_numbers.clear()
	conflict_cells.clear()
	isolated_placements.clear()
	highlighted_placement = null
	var cell_placements := {}
	for index in placements.size():
		var placement := placements[index]
		if not _start_numbers.has(placement.start):
			_start_numbers[placement.start] = index + 1
		for letter_index in placement.word_data.word.length():
			var cell := placement.cell_position(letter_index)
			var letter := placement.word_data.word[letter_index]
			if _letters.has(cell) and _letters[cell] != letter:
				conflict_cells[cell] = true
			_letters[cell] = letter
			if not cell_placements.has(cell):
				cell_placements[cell] = []
			cell_placements[cell].append(placement)
	_find_isolated_placements(placements, cell_placements)
	_update_size()
	queue_redraw()

func _find_isolated_placements(placements: Array[CrosswordWordPlacement], cell_placements: Dictionary) -> void:
	var largest_group: Array[CrosswordWordPlacement] = []
	var visited := {}
	for placement in placements:
		if visited.has(placement):
			continue
		var group := _collect_connected_group(placement, cell_placements, visited)
		if group.size() > largest_group.size():
			largest_group = group
	for placement in placements:
		if placement in largest_group:
			continue
		isolated_placements.append(placement)
		for letter_index in placement.word_data.word.length():
			_isolated_cells[placement.cell_position(letter_index)] = true

func _collect_connected_group(first: CrosswordWordPlacement, cell_placements: Dictionary, visited: Dictionary) -> Array[CrosswordWordPlacement]:
	var group: Array[CrosswordWordPlacement] = []
	var pending: Array[CrosswordWordPlacement] = [first]
	visited[first] = true
	while not pending.is_empty():
		var placement: CrosswordWordPlacement = pending.pop_back()
		group.append(placement)
		for letter_index in placement.word_data.word.length():
			for neighbour in cell_placements[placement.cell_position(letter_index)]:
				if visited.has(neighbour):
					continue
				visited[neighbour] = true
				pending.append(neighbour)
	return group

func _update_size() -> void:
	if _letters.is_empty():
		_grid_size = Vector2i.ZERO
		custom_minimum_size = Vector2.ZERO
		return
	var cells: Array = _letters.keys()
	var min_cell: Vector2i = cells[0]
	var max_cell: Vector2i = cells[0]
	for cell in cells:
		min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
		max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
	_origin = min_cell
	_grid_size = max_cell - min_cell + Vector2i.ONE
	custom_minimum_size = Vector2(_grid_size) * CELL_SIZE

func _draw() -> void:
	var font := get_theme_default_font()
	var letter_baseline := (CELL_SIZE + font.get_ascent(LETTER_FONT_SIZE) - font.get_descent(LETTER_FONT_SIZE)) / 2.0
	if show_full_grid:
		_draw_empty_cells()
	for cell in _letters:
		var rect := _cell_rect(cell)
		draw_rect(rect, _cell_color(cell))
		draw_rect(rect, BORDER_COLOR, false, 1.0)
		draw_string(font, rect.position + Vector2(0, letter_baseline), _letters[cell], HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, LETTER_FONT_SIZE, LETTER_COLOR)
		if _start_numbers.has(cell):
			draw_string(font, rect.position + Vector2(2, font.get_ascent(NUMBER_FONT_SIZE) + 1), str(_start_numbers[cell]), HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, NUMBER_COLOR)
	if highlighted_placement != null:
		_draw_highlighted_border()

func _draw_empty_cells() -> void:
	for y in _grid_size.y:
		for x in _grid_size.x:
			var cell := _origin + Vector2i(x, y)
			if _letters.has(cell):
				continue
			var rect := _cell_rect(cell)
			draw_rect(rect, EMPTY_CELL_COLOR)
			draw_rect(rect, EMPTY_BORDER_COLOR, false, 1.0)

func _draw_highlighted_border() -> void:
	var last_cell := highlighted_placement.cell_position(highlighted_placement.word_data.word.length() - 1)
	var word_rect := _cell_rect(highlighted_placement.start).merge(_cell_rect(last_cell))
	draw_rect(word_rect, HIGHLIGHTED_BORDER_COLOR, false, HIGHLIGHTED_BORDER_WIDTH)

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell - _origin) * CELL_SIZE, Vector2.ONE * CELL_SIZE)

func _cell_color(cell: Vector2i) -> Color:
	if conflict_cells.has(cell):
		return CONFLICT_CELL_COLOR
	if _highlighted_cells.has(cell):
		return HIGHLIGHTED_CELL_COLOR
	if _isolated_cells.has(cell):
		return ISOLATED_CELL_COLOR
	return CELL_COLOR
