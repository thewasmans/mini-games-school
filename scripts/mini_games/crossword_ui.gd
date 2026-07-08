class_name CrosswordUI
extends Control

const CELL_SIZE := Vector2(40, 40)

@export var grid_container: GridContainer
@export var clues_container: VBoxContainer

var _cells: Dictionary = {}

func initialize(crossword_data: CrosswordData) -> void:
	var placements := CrosswordGenerator.generate(crossword_data.clues)
	_render_grid(placements)
	_render_clues(placements)

func _render_grid(placements: Array[CrosswordWordPlacement]) -> void:
	var letter_positions: Dictionary = {}
	for placement in placements:
		for letter_index in placement.word_data.word.length():
			letter_positions[placement.cell_position(letter_index)] = true
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
			var cell := Label.new()
			cell.custom_minimum_size = CELL_SIZE
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if letter_positions.has(pos):
				var background := StyleBoxFlat.new()
				background.bg_color = Color.WHITE
				cell.add_theme_stylebox_override("normal", background)
				cell.add_theme_color_override("font_color", Color.BLACK)
				_cells[pos] = cell
			grid_container.add_child(cell)

func _render_clues(placements: Array[CrosswordWordPlacement]) -> void:
	var sorted_placements := placements.duplicate()
	sorted_placements.sort_custom(func(a: CrosswordWordPlacement, b: CrosswordWordPlacement) -> bool:
		if a.start.y != b.start.y:
			return a.start.y < b.start.y
		return a.start.x < b.start.x)
	for i in sorted_placements.size():
		_add_clue_row(sorted_placements[i], i + 1)

func _add_clue_row(placement: CrosswordWordPlacement, number: int) -> void:
	var direction := "Horizontal" if placement.is_horizontal else "Vertical"
	var row := HBoxContainer.new()
	var hint_label := Label.new()
	hint_label.text = "%d. (%s) %s" % [number, direction, placement.word_data.hint]
	hint_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(hint_label)
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "..."
	line_edit.custom_minimum_size = Vector2(120, 0)
	line_edit.text_changed.connect(_on_word_input_changed.bind(line_edit))
	line_edit.text_submitted.connect(_on_word_submitted.bind(placement, line_edit))
	row.add_child(line_edit)
	clues_container.add_child(row)

func _on_word_input_changed(_new_text: String, line_edit: LineEdit) -> void:
	line_edit.remove_theme_color_override("font_color")

func _on_word_submitted(submitted_text: String, placement: CrosswordWordPlacement, line_edit: LineEdit) -> void:
	if submitted_text.strip_edges().to_upper() == placement.word_data.word:
		_reveal_word(placement)
		line_edit.editable = false
		line_edit.add_theme_color_override("font_color", Color.GREEN)
	else:
		line_edit.add_theme_color_override("font_color", Color.RED)

func _reveal_word(placement: CrosswordWordPlacement) -> void:
	for letter_index in placement.word_data.word.length():
		var pos := placement.cell_position(letter_index)
		if _cells.has(pos):
			_cells[pos].text = placement.word_data.word[letter_index]
