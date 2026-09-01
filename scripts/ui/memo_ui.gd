class_name MemoUI
extends Control

signal completed

const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const NEXT_DELAY := 0.6
const CHOICE_MIN_SIZE := Vector2(0, 56)
const CHOICE_FONT_SIZE := 15

@export var question_label: Label
@export var image_rect: TextureRect
@export var choices_container: Container

var _questions: Array[MemoQuestionData] = []
var _question_index: int = 0
var _choice_buttons: Array[Button] = []
var _choices_grid: GridContainer

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
	image_rect.visible = question_data.image != null
	for choice_index in question_data.choices.size():
		_choices_grid_node().add_child(_create_choice_button(question_data.choices[choice_index], choice_index))

func _choices_grid_node() -> GridContainer:
	if _choices_grid == null:
		_choices_grid = GridContainer.new()
		_choices_grid.columns = 2
		_choices_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_choices_grid.add_theme_constant_override("h_separation", 10)
		_choices_grid.add_theme_constant_override("v_separation", 10)
		choices_container.add_child(_choices_grid)
	return _choices_grid

func _create_choice_button(choice_text: String, choice_index: int) -> Button:
	var button := Button.new()
	button.text = choice_text
	button.custom_minimum_size = CHOICE_MIN_SIZE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = true
	button.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
	button.pressed.connect(_on_choice_pressed.bind(choice_index))
	_choice_buttons.append(button)
	return button

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
