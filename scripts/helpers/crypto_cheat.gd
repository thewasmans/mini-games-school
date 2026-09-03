class_name CryptoCheat
extends MiniGameCheat

func hint_text() -> String:
	var lines: PackedStringArray = []
	var phrases: Array = ui._crypto_data.phrases
	for phrase_index in phrases.size():
		var phrase_data = phrases[phrase_index]
		var marker := ">" if phrase_index == ui._puzzle_index else " "
		lines.append("%s %s  (%s)" % [marker, phrase_data.text, phrase_data.hint])
	return "\n".join(lines)

func autofill() -> void:
	while _alive() and ui._puzzle_index < ui._crypto_data.phrases.size():
		var current_index: int = ui._puzzle_index
		var solution: String = ui._puzzle.solution()
		for character_index in ui._sorted_slot_indices():
			var slot: LineEdit = ui._slots[character_index]
			slot.text = solution[character_index]
			ui._on_slot_text_changed(slot.text, character_index)
			await _wait(CHAR_INTERVAL)
			if not _alive():
				return
		var guard := 0
		while _alive() and ui._puzzle_index == current_index and guard < 600:
			await ui.get_tree().process_frame
			guard += 1
		if not _alive():
			return
		await _wait(STEP_INTERVAL)
