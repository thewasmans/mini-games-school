class_name CrosswordGenerator
extends RefCounted

static func generate(clues: Array[WordData]) -> Array[CrosswordWordPlacement]:
	var placements: Array[CrosswordWordPlacement] = []
	if clues.is_empty():
		return placements
	var sorted_clues := clues.duplicate()
	sorted_clues.sort_custom(func(a: WordData, b: WordData) -> bool: return a.word.length() > b.word.length())
	placements.append(CrosswordWordPlacement.new(sorted_clues[0], Vector2i.ZERO, true))
	for i in range(1, sorted_clues.size()):
		var word_data: WordData = sorted_clues[i]
		var placement := _find_crossing_placement(word_data, placements)
		if placement == null:
			placement = _find_fallback_placement(word_data, placements)
		placements.append(placement)
	return placements

static func _find_crossing_placement(word_data: WordData, placements: Array[CrosswordWordPlacement]) -> CrosswordWordPlacement:
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
				if _is_valid_placement(candidate, placements):
					return candidate
	return null

static func _is_valid_placement(candidate: CrosswordWordPlacement, placements: Array[CrosswordWordPlacement]) -> bool:
	for letter_index in candidate.word_data.word.length():
		var cell := candidate.cell_position(letter_index)
		var letter := candidate.word_data.word[letter_index]
		for existing in placements:
			for existing_index in existing.word_data.word.length():
				if existing.cell_position(existing_index) == cell and existing.word_data.word[existing_index] != letter:
					return false
	return true

static func _find_fallback_placement(word_data: WordData, placements: Array[CrosswordWordPlacement]) -> CrosswordWordPlacement:
	var max_row := 0
	for existing in placements:
		for existing_index in existing.word_data.word.length():
			max_row = max(max_row, existing.cell_position(existing_index).y)
	return CrosswordWordPlacement.new(word_data, Vector2i(0, max_row + 2), true)
