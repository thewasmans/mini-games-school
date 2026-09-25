class_name CrosswordGenerator
extends RefCounted

const MAX_ATTEMPTS := 100

static func generate(clues: Array[WordData]) -> Array[CrosswordWordPlacement]:
	var best_placements: Array[CrosswordWordPlacement] = []
	var best_unplaced: Array[WordData] = []
	if clues.is_empty():
		return best_placements
	var ordered_clues: Array[WordData] = clues.duplicate()
	ordered_clues.sort_custom(func(a: WordData, b: WordData) -> bool: return a.word.length() > b.word.length())
	for attempt in MAX_ATTEMPTS:
		var unplaced: Array[WordData] = []
		var placements := _place_connected_words(ordered_clues, unplaced)
		if attempt == 0 or unplaced.size() < best_unplaced.size():
			best_placements = placements
			best_unplaced = unplaced
		if best_unplaced.is_empty():
			break
		ordered_clues.shuffle()
	for word_data in best_unplaced:
		best_placements.append(_find_fallback_placement(word_data, best_placements))
	return best_placements

static func _place_connected_words(ordered_clues: Array[WordData], unplaced: Array[WordData]) -> Array[CrosswordWordPlacement]:
	var placements: Array[CrosswordWordPlacement] = [CrosswordWordPlacement.new(ordered_clues[0], Vector2i.ZERO, true)]
	unplaced.append_array(ordered_clues.slice(1))
	var has_progress := true
	while has_progress and not unplaced.is_empty():
		has_progress = false
		for word_data in unplaced.duplicate():
			var placement := _find_crossing_placement(word_data, placements)
			if placement == null:
				continue
			placements.append(placement)
			unplaced.erase(word_data)
			has_progress = true
	return placements

static func _find_crossing_placement(word_data: WordData, placements: Array[CrosswordWordPlacement]) -> CrosswordWordPlacement:
	var letters := _build_letter_grid(placements)
	var horizontal_cells := _build_direction_cells(placements, true)
	var vertical_cells := _build_direction_cells(placements, false)
	for existing in placements:
		for existing_index in existing.word_data.word.length():
			var existing_letter := existing.word_data.word[existing_index]
			var cell := existing.cell_position(existing_index)
			for letter_index in word_data.word.length():
				if word_data.word[letter_index] != existing_letter:
					continue
				var is_horizontal := not existing.is_horizontal
				var start: Vector2i
				if is_horizontal:
					start = cell - Vector2i(letter_index, 0)
				else:
					start = cell - Vector2i(0, letter_index)
				var candidate := CrosswordWordPlacement.new(word_data, start, is_horizontal)
				var same_direction_cells := horizontal_cells if is_horizontal else vertical_cells
				if _is_valid_placement(candidate, letters, same_direction_cells):
					return candidate
	return null

static func _is_valid_placement(candidate: CrosswordWordPlacement, letters: Dictionary, same_direction_cells: Dictionary) -> bool:
	var word := candidate.word_data.word
	if letters.has(candidate.cell_position(-1)) or letters.has(candidate.cell_position(word.length())):
		return false
	var side_offset := Vector2i(0, 1) if candidate.is_horizontal else Vector2i(1, 0)
	for letter_index in word.length():
		var cell := candidate.cell_position(letter_index)
		if letters.has(cell):
			if letters[cell] != word[letter_index] or same_direction_cells.has(cell):
				return false
		elif letters.has(cell + side_offset) or letters.has(cell - side_offset):
			return false
	return true

static func _build_letter_grid(placements: Array[CrosswordWordPlacement]) -> Dictionary:
	var letters := {}
	for placement in placements:
		for letter_index in placement.word_data.word.length():
			letters[placement.cell_position(letter_index)] = placement.word_data.word[letter_index]
	return letters

static func _build_direction_cells(placements: Array[CrosswordWordPlacement], is_horizontal: bool) -> Dictionary:
	var cells := {}
	for placement in placements:
		if placement.is_horizontal != is_horizontal:
			continue
		for letter_index in placement.word_data.word.length():
			cells[placement.cell_position(letter_index)] = true
	return cells

static func _find_fallback_placement(word_data: WordData, placements: Array[CrosswordWordPlacement]) -> CrosswordWordPlacement:
	var max_row := 0
	for existing in placements:
		for existing_index in existing.word_data.word.length():
			max_row = max(max_row, existing.cell_position(existing_index).y)
	return CrosswordWordPlacement.new(word_data, Vector2i(0, max_row + 2), true)
