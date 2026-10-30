class_name MemoUI
extends MiniGameUI

const LETTERS := "ABCD"

@export var question_card: FramePanel
@export var question_label: Label
@export var progress_ring: ProgressRing
@export var image_box: Control
@export var answer_buttons: Array[JuicyButton] = []
@export var default_image_prefab: PackedScene

@export_group("Réglages")
## Couleur de chaque bouton de réponse (A, B, C, D).
@export var answer_colors: Array[Color] = [Color("ffa62b"), Color("6bd85a"), Color("c06cf0"), Color("ffd84a")]
## Couleur d'une mauvaise réponse.
@export var wrong_color := Color("ff6b74")
## Couleur de la bonne réponse.
@export var right_color := Color("7be86a")
## Couleur d'une mauvaise réponse écartée par un indice.
@export var eliminated_color := Color("8a93a6")
## Temps pendant lequel la bonne réponse reste affichée avant la question suivante, en secondes.
@export var next_question_delay := 1.0

var _data: MemoData
var _index := 0
var _locked := false
var _t := 0.0


func _ready() -> void:
	for answer_index in answer_buttons.size():
		answer_buttons[answer_index].pressed.connect(_on_answer.bind(answer_index))


func initialize(mini_game_data: MiniGameData) -> void:
	_data = mini_game_data as MemoData
	answer_total = _data.questions.size()
	progress_changed.emit(0, _data.questions.size())
	_show_question(0)


func _process(delta: float) -> void:
	_t += delta
	if image_box.get_child_count() > 0:
		var image: Control = image_box.get_child(0)
		image.position.y = sin(_t * 1.5) * 6


func _show_question(question_index: int) -> void:
	_index = question_index
	_locked = false
	var question := _data.questions[question_index]
	progress_ring.set_progress(question_index + 1, _data.questions.size())
	question_label.text = question.question
	question_card.modulate.a = 1.0

	for child in image_box.get_children():
		child.queue_free()
	var image: Control
	if question.image != null:
		var texture_rect := TextureRect.new()
		texture_rect.texture = question.image
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image = texture_rect
	else:
		image = default_image_prefab.instantiate()
	image_box.add_child(image)
	image.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UIFeedback.pop_in(image, 0.1, 0.4)

	for answer_index in answer_buttons.size():
		var button := answer_buttons[answer_index]
		button.visible = answer_index < question.answers.size()
		if not button.visible:
			continue
		button.text = "%s. %s" % [LETTERS[answer_index], question.answers[answer_index]]
		button.color = answer_colors[answer_index]
		button.sparkles = false
		button.disabled = false
		UIFeedback.pop_in(button, 0.15 + answer_index * 0.07, 0.5)
	UIFeedback.pop_in(question_card, 0.0, 0.85)


func use_hint() -> bool:
	if _locked or is_completed:
		return false
	var question := _data.questions[_index]
	var wrong_buttons: Array[JuicyButton] = []
	for answer_index in answer_buttons.size():
		var button := answer_buttons[answer_index]
		if answer_index != question.correct_index and button.visible and not button.disabled:
			wrong_buttons.append(button)
	if wrong_buttons.is_empty():
		return false
	var eliminated := wrong_buttons.pick_random() as JuicyButton
	eliminated.color = eliminated_color
	eliminated.disabled = true
	_mark_hinted(_index)
	UIFeedback.punch(eliminated, 0.12, 0.4)
	Sfx.play("pop")
	return true


func _on_answer(answer_index: int) -> void:
	if _locked or is_completed:
		return
	var question := _data.questions[_index]
	var button := answer_buttons[answer_index]
	if answer_index != question.correct_index:
		button.color = wrong_color
		button.disabled = true
		UIFeedback.shake(button)
		Sfx.play("error")
		_make_mistake(_index)
		return

	_locked = true
	_answer_found(_index)
	button.color = right_color
	button.sparkles = true
	UIFeedback.punch(button, 0.15, 0.6)
	Sfx.play("good")
	Confetti.sparkle(self, button.global_position + button.size / 2, 22)
	UIFeedback.float_text(button, "Bravo !", Color.WHITE, 46)
	progress_changed.emit(_index + 1, _data.questions.size())
	await _wait(next_question_delay)
	if not is_inside_tree():
		return
	if _index + 1 >= _data.questions.size():
		_finish()
		return
	var tw := create_tween().set_parallel()
	for answer in answer_buttons:
		tw.tween_property(answer, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(question_card, "modulate:a", 0.0, 0.2)
	await tw.finished
	if is_inside_tree():
		Sfx.play("whoosh")
		_show_question(_index + 1)
