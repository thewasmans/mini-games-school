class_name MemoCheat
extends MiniGameCheat

func hint_text() -> String:
	if ui._question_index >= ui._questions.size():
		return ""
	var question_data = ui._questions[ui._question_index]
	return "Réponse : %s" % question_data.choices[question_data.correct_choice_index]

func autofill() -> void:
	while _running() and ui._question_index < ui._questions.size():
		var current_index: int = ui._question_index
		await _wait(STEP_INTERVAL)
		if not _running():
			return
		if ui._question_index != current_index:
			continue
		ui._on_choice_pressed(ui._questions[current_index].correct_choice_index)
		await _wait(MemoUI.NEXT_DELAY + STEP_INTERVAL)
