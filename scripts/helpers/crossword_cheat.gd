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
		if ui._placement_attempts.get(placement, "") == placement.word_data.word:
			continue
		ui._select_placement(placement)
		ui._current_text = ""
		var word: String = placement.word_data.word
		for letter in word:
			ui._on_letter_pressed(LetterNormalizer.base_letter(letter))
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
