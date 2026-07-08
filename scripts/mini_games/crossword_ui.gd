class_name CrosswordUI
extends Control

const CELL_SIZE := Vector2(40, 40)

@export var grid_container: GridContainer
@export var clues_label: Label

func initialize(crossword_data: CrosswordData) -> void:
	var placements := CrosswordGenerator.generate(crossword_data.clues)
	_render_grid(placements)
	_render_clues(placements)

func _render_grid(placements: Array[CrosswordWordPlacement]) -> void:
	var cells: Dictionary = {}
	for placement in placements:
		for letter_index in placement.word_data.word.length():
			cells[placement.cell_position(letter_index)] = placement.word_data.word[letter_index]
	if cells.is_empty():
		return
	var positions: Array = cells.keys()
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
			if cells.has(pos):
				cell.text = cells[pos]
				cell.add_theme_color_override("font_color", Color.BLACK)
				var background := StyleBoxFlat.new()
				background.bg_color = Color.WHITE
				cell.add_theme_stylebox_override("normal", background)
			grid_container.add_child(cell)

func _render_clues(placements: Array[CrosswordWordPlacement]) -> void:
	var sorted_placements := placements.duplicate()
	sorted_placements.sort_custom(func(a: CrosswordWordPlacement, b: CrosswordWordPlacement) -> bool:
		if a.start.y != b.start.y:
			return a.start.y < b.start.y
		return a.start.x < b.start.x)
	var lines: Array[String] = []
	for i in sorted_placements.size():
		var placement: CrosswordWordPlacement = sorted_placements[i]
		var direction := "Horizontal" if placement.is_horizontal else "Vertical"
		lines.append("%d. (%s) %s" % [i + 1, direction, placement.word_data.hint])
	clues_label.text = "\n".join(lines)
