class_name MemoUI
extends Control

signal completed

const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const NEXT_DELAY := 0.6

@export var question_label: Label
@export var image_rect: TextureRect
@export var choices_container: Container

var _questions: Array[MemoQuestionData] = []
var _question_index: int = 0
var _choice_buttons: Array[Button] = []

func initialize(memo_data: MemoData) -> void:
	_questions = memo_data.questions
	_show_question()

func _show_question() -> void:
	for button in _choice_buttons:
		button.queue_free()
	_choice_buttons.clear()
	var question_data := _questions[_question_index]
	question_label.text = question_data.question
	image_rect.texture = question_data.image
	for choice_index in question_data.choices.size():
		var button := Button.new()
		button.text = question_data.choices[choice_index]
		button.pressed.connect(_on_choice_pressed.bind(choice_index))
		choices_container.add_child(button)
		_choice_buttons.append(button)

func _on_choice_pressed(choice_index: int) -> void:
	var question_data := _questions[_question_index]
	if choice_index != question_data.correct_choice_index:
		var wrong_button := _choice_buttons[choice_index]
		wrong_button.disabled = true
		wrong_button.modulate = INCORRECT_COLOR
		return
	for button in _choice_buttons:
		button.disabled = true
	_choice_buttons[question_data.correct_choice_index].modulate = CORRECT_COLOR
	_question_index += 1
	if _question_index >= _questions.size():
		completed.emit()
		return
	await get_tree().create_timer(NEXT_DELAY).timeout
	_show_question()
