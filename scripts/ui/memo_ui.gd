class_name MemoUI
extends MiniGameUI
## Quiz : une question, une image et 4 réponses. Une mauvaise réponse se désactive,
## la bonne fait passer à la question suivante.

const ANSWER_COLORS: Array[Color] = [Color("ffa62b"), Color("6bd85a"), Color("c06cf0"), Color("ffd84a")]
const ANSWER_BOTTOMS: Array[Color] = [Color("f07412"), Color("2fa83e"), Color("8a3fd0"), Color("f0a400")]
const LETTERS := "ABCD"

var _data: MemoData
var _index := 0
var _locked := false

var _card: PanelContainer
var _ring: ProgressRing
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

	# Carte de question : texte à gauche, anneau de progression à droite.
	_card = PanelContainer.new()
	var sb := UIStyle.frame_box()
	sb.set_content_margin_all(22)
	sb.content_margin_bottom = 28
	_card.add_theme_stylebox_override("panel", sb)
	root.add_child(_card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 8)
	_card.add_child(card_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card_box.add_child(row)
	_question = UIStyle.label("", 34)
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.size_flags_horizontal = SIZE_EXPAND_FILL
	_question.custom_minimum_size = Vector2(0, 110)
	row.add_child(_question)
	_ring = ProgressRing.new()
	_ring.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(_ring)
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
		var b := JuicyButton.new("", ANSWER_COLORS[k], 28)
		b.color_bottom = ANSWER_BOTTOMS[k]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.padding = 20
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
	_ring.set_progress(i + 1, _data.questions.size())
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
		b.color_bottom = ANSWER_BOTTOMS[k]
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
		b.color = Color("ff6b74")
		b.color_bottom = Color("d42a38")
		b.disabled = true
		UIFeedback.shake(b)
		Sfx.play("error")
		return

	_locked = true
	b.color = Color("7be86a")
	b.color_bottom = Color("22a83a")
	b.sparkles = true
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


## Anneau de progression (question n / total), façon minuteur.
class ProgressRing extends Control:
	var _value := 0.0
	var _shown := 0.0
	var _text := ""

	func _init() -> void:
		custom_minimum_size = Vector2(118, 118)

	func set_progress(current: int, total: int) -> void:
		_text = "%d/%d" % [current, total]
		_value = current / float(maxi(total, 1))
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			_shown = v
			queue_redraw(), _shown, _value, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	func _draw() -> void:
		var c := size / 2
		var r := minf(size.x, size.y) / 2 - 8
		draw_circle(c, r + 6, Color("0f1d52"))
		draw_circle(c, r - 8, Color("13235e"))
		draw_arc(c, r - 1, 0, TAU, 48, Color(1, 1, 1, 0.12), 12, true)
		var start := -PI / 2
		var steps := 24
		for i in steps:
			var t0 := float(i) / steps * _shown
			var t1 := float(i + 1) / steps * _shown
			var col := Color("ffd23f").lerp(Color("ff5fa8"), t0).lerp(Color("4fb6ff"), maxf(0, t0 - 0.5))
			draw_arc(c, r - 1, start + TAU * t0, start + TAU * t1 + 0.01, 4, col, 12, true)
		UIStyle.draw_text(self, _text, c, int(r * 0.62), Color("ffe066"), 8)
