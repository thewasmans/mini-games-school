class_name MemoUI
extends MiniGameUI
## Quiz : une question, une image et 4 réponses. Une mauvaise réponse se désactive,
## la bonne fait passer à la question suivante.

const ANSWER_COLORS: Array[Color] = [Color("ff9f1c"), Color("4cc44a"), Color("b05ce0"), Color("f2b705")]
const LETTERS := "ABCD"

var _data: MemoData
var _index := 0
var _locked := false

var _card: PanelContainer
var _counter: Label
var _question: Label
var _hint: Label
var _image_box: Control
var _answers_grid: GridContainer
var _answers: Array[JuicyButton] = []
var _t := 0.0


func setup(data: MiniGameData) -> void:
	_data = data as MemoData
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	_card = PanelContainer.new()
	root.add_child(_card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 8)
	_card.add_child(card_box)
	var counter_pill := UIStyle.pill("", UIStyle.PANEL_DARK, 22)
	counter_pill.size_flags_horizontal = SIZE_SHRINK_BEGIN
	_counter = counter_pill.get_child(0)
	card_box.add_child(counter_pill)
	_question = UIStyle.label("", 32)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.custom_minimum_size = Vector2(0, 90)
	card_box.add_child(_question)
	_hint = UIStyle.label("", 22, UIStyle.YELLOW, 6)
	_hint.visible = false
	card_box.add_child(_hint)

	_image_box = Control.new()
	_image_box.size_flags_vertical = SIZE_EXPAND_FILL
	_image_box.custom_minimum_size = Vector2(0, 220)
	root.add_child(_image_box)

	_answers_grid = GridContainer.new()
	_answers_grid.columns = 2
	_answers_grid.add_theme_constant_override("h_separation", 14)
	_answers_grid.add_theme_constant_override("v_separation", 14)
	root.add_child(_answers_grid)
	for k in 4:
		var b := JuicyButton.new("", ANSWER_COLORS[k], 26)
		b.custom_minimum_size = Vector2(0, 130)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.sound = ""
		b.pressed.connect(_on_answer.bind(k))
		_answers_grid.add_child(b)
		_answers.append(b)


func _ready() -> void:
	super()
	_show_question(0)


func _process(delta: float) -> void:
	_t += delta
	if _image_box.get_child_count() > 0:
		var img: Control = _image_box.get_child(0)
		img.position.y = sin(_t * 1.5) * 6


func _show_question(i: int) -> void:
	_index = i
	_locked = false
	var q := _data.questions[i]
	_counter.text = "Question %d / %d" % [i + 1, _data.questions.size()]
	_question.text = q.question
	_hint.text = "Réponse : %s. %s" % [LETTERS[q.correct_index], q.answers[q.correct_index] if q.correct_index < q.answers.size() else "?"]
	_hint.visible = GameManager.debug_show_hints

	for child in _image_box.get_children():
		child.queue_free()
	var img: Control
	if q.image != null:
		var tr := TextureRect.new()
		tr.texture = q.image
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img = tr
	else:
		img = DefaultQuizImage.new()
	img.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_image_box.add_child(img)
	UIFeedback.pop_in(img, 0.1, 0.4)

	for k in 4:
		var b := _answers[k]
		b.visible = k < q.answers.size()
		if not b.visible:
			continue
		b.text = "%s. %s" % [LETTERS[k], q.answers[k]]
		b.color = ANSWER_COLORS[k]
		b.disabled = false
		UIFeedback.pop_in(b, 0.15 + k * 0.07, 0.5)
	UIFeedback.pop_in(_card, 0.0, 0.85)

	if GameManager.debug_auto_fill:
		debug_autofill()


func _on_answer(k: int) -> void:
	if _locked or is_completed:
		return
	var q := _data.questions[_index]
	var b := _answers[k]
	if k != q.correct_index:
		b.color = UIStyle.RED
		b.disabled = true
		UIFeedback.shake(b)
		Sfx.play("error")
		return

	_locked = true
	b.color = Color("2ecc40")
	UIFeedback.punch(b, 0.15, 0.6)
	Sfx.play("good")
	Confetti.sparkle(self, b.global_position + b.size / 2, 22)
	UIFeedback.float_text(b, "Bravo !", Color.WHITE, 46)
	progress_changed.emit((_index + 1) / float(_data.questions.size()))
	await _wait(1.0)
	if not is_inside_tree():
		return
	if _index + 1 >= _data.questions.size():
		_finish()
		return
	# Les réponses s'envolent, la question suivante arrive.
	var tw := create_tween().set_parallel()
	for a in _answers:
		tw.tween_property(a, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(_card, "modulate:a", 0.0, 0.2)
	await tw.finished
	if is_inside_tree():
		Sfx.play("whoosh")
		_show_question(_index + 1)


func set_show_hints(on: bool) -> void:
	if _hint:
		_hint.visible = on


func debug_autofill() -> void:
	var i := _index
	await _wait(0.6)
	if is_inside_tree() and i == _index and not _locked:
		_on_answer(_data.questions[i].correct_index)
