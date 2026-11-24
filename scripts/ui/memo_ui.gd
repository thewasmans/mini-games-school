class_name MemoUI
extends Control

signal completed
signal progress_changed(completed_count: int, total_count: int)

const CORRECT_COLOR := Color(0.5, 1.0, 0.5)
const INCORRECT_COLOR := Color(1.0, 0.5, 0.5)
const NEXT_DELAY := 0.6
const CORRECT_FLASH_COLOR := Color(1.5, 1.9, 1.5)
const CORRECT_POP_SCALE := 1.15
const APPEAR_STAGGER := 0.06
const COMPLETED_DELAY := 0.8
const QUESTION_FRAME_MIN_HEIGHT := 110.0
const QUESTION_FRAME_MAX_HEIGHT := 240.0
const QUESTION_MIN_FONT_SIZE := 16
const QUESTION_FONT_STEP := 2

@export var question_frame: Control
@export var question_label: Label
@export var image_rect: TextureRect
@export var choice_buttons: Array[Button] = []

var _questions: Array[MemoQuestionData] = []
var _question_index: int = 0
var _default_image: Texture2D
var _question_font_size: int

func initialize(memo_data: MemoData) -> void:
	_questions = memo_data.questions
	_default_image = image_rect.texture
	_question_font_size = question_label.get_theme_font_size("font_size")
	question_label.resized.connect(_fit_question)
	progress_changed.emit(_question_index, _questions.size())
	for choice_index in choice_buttons.size():
		choice_buttons[choice_index].pressed.connect(_on_choice_pressed.bind(choice_index))
	_show_question()

func _show_question() -> void:
	var question_data := _questions[_question_index]
	question_label.text = question_data.question
	_fit_question()
	image_rect.texture = question_data.image if question_data.image != null else _default_image
	for choice_index in choice_buttons.size():
		var button := choice_buttons[choice_index]
		button.text = question_data.choices[choice_index]
		button.disabled = false
		button.modulate = Color.WHITE
		UIFeedback.appear(button, choice_index * APPEAR_STAGGER)
	UIFeedback.appear(question_label, 0.0)

func _fit_question() -> void:
	var text_width := question_label.size.x
	if text_width <= 0.0:
		return
	var font := question_label.get_theme_font("font")
	var vertical_padding := question_frame.size.y - question_label.size.y
	var font_size := _question_font_size
	var text_height := _question_text_height(font, text_width, font_size)
	while text_height + vertical_padding > QUESTION_FRAME_MAX_HEIGHT and font_size > QUESTION_MIN_FONT_SIZE:
		font_size -= QUESTION_FONT_STEP
		text_height = _question_text_height(font, text_width, font_size)
	question_label.add_theme_font_size_override("font_size", font_size)
	question_frame.custom_minimum_size.y = clampf(text_height + vertical_padding, QUESTION_FRAME_MIN_HEIGHT, QUESTION_FRAME_MAX_HEIGHT)

func _question_text_height(font: Font, text_width: float, font_size: int) -> float:
	return font.get_multiline_string_size(question_label.text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size).y

func _on_choice_pressed(choice_index: int) -> void:
	var question_data := _questions[_question_index]
	if choice_index != question_data.correct_choice_index:
		var wrong_button := choice_buttons[choice_index]
		wrong_button.disabled = true
		wrong_button.modulate = INCORRECT_COLOR
		UIFeedback.shake(wrong_button)
		return
	for button in choice_buttons:
		button.disabled = true
	UIFeedback.pop(choice_buttons[question_data.correct_choice_index], 0.0, CORRECT_POP_SCALE, CORRECT_FLASH_COLOR, CORRECT_COLOR)
	_question_index += 1
	progress_changed.emit(_question_index, _questions.size())
	if _question_index >= _questions.size():
		UIFeedback.spawn_confetti(self, size / 2.0)
		await get_tree().create_timer(UIFeedback.POP_DURATION + COMPLETED_DELAY).timeout
		completed.emit()
		return
	await get_tree().create_timer(NEXT_DELAY).timeout
	_show_question()
