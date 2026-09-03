class_name CryptoCheat
extends MiniGameCheat

func hint_text() -> String:
	if ui._puzzle == null:
		return ""
	return ui._puzzle.solution()

func autofill() -> void:
	while _running() and ui._puzzle_index < ui._crypto_data.phrases.size():
		var current_index: int = ui._puzzle_index
		var solution: String = ui._puzzle.solution()
		for character_index in ui._sorted_slot_indices():
			var slot: LineEdit = ui._slots[character_index]
			slot.text = solution[character_index]
			ui._on_slot_text_changed(slot.text, character_index)
			await _wait(CHAR_INTERVAL)
			if not _running():
				return
		var guard := 0
		while _running() and ui._puzzle_index == current_index and guard < 600:
			await ui.get_tree().process_frame
			guard += 1
		if not _running():
			return
		await _wait(STEP_INTERVAL)
