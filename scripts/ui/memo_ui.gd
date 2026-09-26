class_name MemoUI
extends Control

signal completed

const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const NEXT_DELAY := 0.6

@export var question_label: Label
@export var image_rect: TextureRect
@export var choice_buttons: Array[Button] = []

var _questions: Array[MemoQuestionData] = []
var _question_index: int = 0

func initialize(memo_data: MemoData) -> void:
	_questions = memo_data.questions
	for choice_index in choice_buttons.size():
		choice_buttons[choice_index].pressed.connect(_on_choice_pressed.bind(choice_index))
	_show_question()

func _show_question() -> void:
	var question_data := _questions[_question_index]
	question_label.text = question_data.question
	image_rect.texture = question_data.image
	image_rect.visible = question_data.image != null
	for choice_index in choice_buttons.size():
		var button := choice_buttons[choice_index]
		button.text = question_data.choices[choice_index]
		button.disabled = false
		button.modulate = Color.WHITE

func _on_choice_pressed(choice_index: int) -> void:
	var question_data := _questions[_question_index]
	if choice_index != question_data.correct_choice_index:
		var wrong_button := choice_buttons[choice_index]
		wrong_button.disabled = true
		wrong_button.modulate = INCORRECT_COLOR
		return
	for button in choice_buttons:
		button.disabled = true
	choice_buttons[question_data.correct_choice_index].modulate = CORRECT_COLOR
	_question_index += 1
	if _question_index >= _questions.size():
		completed.emit()
		return
	await get_tree().create_timer(NEXT_DELAY).timeout
	_show_question()
