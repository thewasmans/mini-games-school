class_name CryptoCheat
extends MiniGameCheat


func hint_text() -> String:
	var crypto := ui as CryptoUI
	if crypto._data == null:
		return ""
	return crypto._data.sentences[crypto._index].sentence.strip_edges()


func autofill() -> void:
	var crypto := ui as CryptoUI
	while _running():
		var sentence_index := crypto._index
		if not crypto._solved:
			crypto._fix_errors()
			for hidden_index in crypto._hidden.size():
				var cell := crypto._cells[crypto._hidden[hidden_index]]
				if cell.state != CryptoCell.State.EMPTY:
					continue
				crypto._cursor = hidden_index
				crypto._type(TextUtil.normalize_char(cell.original))
				await _wait(CHAR_INTERVAL)
				if not _running():
					return
		await _wait(STEP_INTERVAL)
		if not _running():
			return
		if crypto._index == sentence_index and crypto.next_button.visible:
			crypto._next_sentence()
		while _running() and crypto._index == sentence_index:
			await ui.get_tree().process_frame
		await _wait(STEP_INTERVAL)
