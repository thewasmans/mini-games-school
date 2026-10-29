class_name MemoCheat
extends MiniGameCheat


func hint_text() -> String:
	var memo := ui as MemoUI
	if memo._data == null or memo._index >= memo._data.questions.size():
		return ""
	var question := memo._data.questions[memo._index]
	return question.answers[question.correct_index]


func autofill() -> void:
	var memo := ui as MemoUI
	while _running():
		var question_index := memo._index
		await _wait(STEP_INTERVAL)
		if not _running():
			return
		if memo._index == question_index and not memo._locked:
			memo._on_answer(memo._data.questions[question_index].correct_index)
		await _wait(memo.next_question_delay + STEP_INTERVAL)
