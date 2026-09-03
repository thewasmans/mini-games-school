class_name CrosswordCheat
extends MiniGameCheat

func hint_text() -> String:
	var lines: PackedStringArray = []
	for placement in _placements():
		var direction := "H" if placement.is_horizontal else "V"
		lines.append("(%s) %s  =  %s" % [direction, placement.word_data.hint, placement.word_data.word])
	return "\n".join(lines)

func autofill() -> void:
	for placement in _placements():
		if not _alive():
			return
		if ui._placement_attempts.get(placement, "") == placement.word_data.word:
			continue
		ui._select_placement(placement)
		var word: String = placement.word_data.word
		for length in range(1, word.length() + 1):
			ui.input.text = word.substr(0, length)
			ui.input.caret_column = length
			ui._on_word_input_changed(ui.input.text)
			await _wait(CHAR_INTERVAL)
			if not _alive():
				return
		await _wait(STEP_INTERVAL)

func _placements() -> Array:
	var seen: Array = []
	for placement_group in ui._cell_placements.values():
		for placement in placement_group:
			if placement not in seen:
				seen.append(placement)
	return seen
