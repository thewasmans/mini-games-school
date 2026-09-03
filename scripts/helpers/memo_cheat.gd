class_name MemoCheat
extends MiniGameCheat

func hint_text() -> String:
	var lines: PackedStringArray = []
	var questions: Array = ui._questions
	for question_index in questions.size():
		var question_data = questions[question_index]
		var marker := ">" if question_index == ui._question_index else " "
		var answer = question_data.choices[question_data.correct_choice_index]
		lines.append("%s %s  ->  %s" % [marker, question_data.question, answer])
	return "\n".join(lines)

func autofill() -> void:
	while _alive() and ui._question_index < ui._questions.size():
		var current_index: int = ui._question_index
		await _wait(STEP_INTERVAL)
		if not _alive():
			return
		if ui._question_index != current_index:
			continue
		ui._on_choice_pressed(ui._questions[current_index].correct_choice_index)
		await _wait(MemoUI.NEXT_DELAY + STEP_INTERVAL)
