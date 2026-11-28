class_name CrosswordCheat
extends MiniGameCheat

func hint_text() -> String:
	var placement = ui._selected_placement
	if placement == null:
		return ""
	return placement.word_data.word

func autofill() -> void:
	for placement in _placements():
		if not _running():
			return
		if ui.is_placement_solved(placement):
			continue
		var word: String = placement.word_data.word
		var open_indices: Array[int] = []
		for letter_index in word.length():
			if not ui._locked_cells.has(placement.cell_position(letter_index)):
				open_indices.append(letter_index)
		if open_indices.is_empty():
			continue
		ui._select_placement(placement, placement.cell_position(open_indices[0]))
		for letter_index in open_indices:
			ui._on_letter_pressed(LetterNormalizer.base_letter(word[letter_index]))
			await _wait(CHAR_INTERVAL)
			if not _running():
				return
		await _wait(STEP_INTERVAL)

func _placements() -> Array:
	var seen: Array = []
	for placement_group in ui._cell_placements.values():
		for placement in placement_group:
			if placement not in seen:
				seen.append(placement)
	return seen
