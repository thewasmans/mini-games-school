class_name CrosswordCheat
extends MiniGameCheat


func hint_text() -> String:
	var crossword := ui as CrosswordUI
	if crossword._selected < 0:
		return ""
	var entry: CrosswordEntry = crossword._words[crossword._selected].entry
	return entry.answer


func autofill() -> void:
	var crossword := ui as CrosswordUI
	for word_index in crossword._words.size():
		if not _running():
			return
		if crossword._words[word_index].done:
			continue
		crossword._select_word(word_index)
		var cells: Array[Vector2i] = crossword._words[word_index].cells
		for cell_index in cells.size():
			var cell: CrosswordCell = crossword._cells[cells[cell_index]]
			if cell.validated:
				continue
			crossword._cursor = cell_index
			crossword._type(cell.solution)
			await _wait(CHAR_INTERVAL)
			if not _running():
				return
		await _wait(STEP_INTERVAL)
