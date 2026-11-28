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
const CHOICE_MIN_HEIGHT := 68.0
const CHOICE_MAX_HEIGHT := 104.0
const CHOICE_TEXT_PADDING := Vector2(4, 8)
const CHOICE_MIN_FONT_SIZE := 16

@export var question_frame: Control
@export var question_label: Label
@export var image_rect: TextureRect
@export var choice_buttons: Array[Button] = []

var _questions: Array[MemoQuestionData] = []
var _question_index: int = 0
var _default_image: Texture2D
var _question_font_size: int
var _choice_font_size: int

func initialize(memo_data: MemoData) -> void:
	_questions = memo_data.questions
	_default_image = image_rect.texture
	_question_font_size = question_label.get_theme_font_size("font_size")
	_choice_font_size = choice_buttons[0].get_theme_font_size("font_size")
	question_label.resized.connect(_fit_question)
	progress_changed.emit(_question_index, _questions.size())
	for choice_index in choice_buttons.size():
		var button := choice_buttons[choice_index]
		button.pressed.connect(_on_choice_pressed.bind(choice_index))
		button.resized.connect(_fit_choice.bind(button))
	_show_question()

func _show_question() -> void:
	var question_data := _questions[_question_index]
	question_label.text = question_data.question
	_fit_question()
	image_rect.texture = question_data.image if question_data.image != null else _default_image
	for choice_index in choice_buttons.size():
		var button := choice_buttons[choice_index]
		button.text = question_data.choices[choice_index]
		_fit_choice(button)
		button.disabled = false
		button.modulate = Color.WHITE
		UIFeedback.appear(button, choice_index * APPEAR_STAGGER)
	UIFeedback.appear(question_label, 0.0)

func _fit_question() -> void:
	var text_width := question_frame.size.x - question_label.offset_left + question_label.offset_right
	if text_width <= 0.0:
		return
	var font := question_label.get_theme_font("font")
	var vertical_padding := question_label.offset_top - question_label.offset_bottom
	var font_size := _question_font_size
	var text_height := _question_text_height(font, text_width, font_size)
	while text_height + vertical_padding > QUESTION_FRAME_MAX_HEIGHT and font_size > QUESTION_MIN_FONT_SIZE:
		font_size -= QUESTION_FONT_STEP
		text_height = _question_text_height(font, text_width, font_size)
	question_label.add_theme_font_size_override("font_size", font_size)
	question_frame.custom_minimum_size.y = clampf(text_height + vertical_padding, QUESTION_FRAME_MIN_HEIGHT, QUESTION_FRAME_MAX_HEIGHT)

func _fit_choice(button: Button) -> void:
	var style_margins := button.get_theme_stylebox("normal").get_minimum_size()
	var text_width := button.size.x - style_margins.x - CHOICE_TEXT_PADDING.x
	if text_width <= 0.0:
		return
	var font := button.get_theme_font("font")
	var vertical_padding := style_margins.y + CHOICE_TEXT_PADDING.y
	var font_size := _choice_font_size
	var text_height := font.get_multiline_string_size(button.text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size).y
	while text_height + vertical_padding > CHOICE_MAX_HEIGHT and font_size > CHOICE_MIN_FONT_SIZE:
		font_size -= 1
		text_height = font.get_multiline_string_size(button.text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size).y
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size.y = clampf(text_height + vertical_padding, CHOICE_MIN_HEIGHT, CHOICE_MAX_HEIGHT)

func _question_text_height(font: Font, text_width: float, font_size: int) -> float:
	var text_height := font.get_multiline_string_size(question_label.text, HORIZONTAL_ALIGNMENT_CENTER, text_width, font_size).y
	var line_count := roundi(text_height / font.get_height(font_size))
	return text_height + maxi(line_count - 1, 0) * question_label.get_theme_constant("line_spacing")

func _on_choice_pressed(choice_index: int) -> void:
	var question_data := _questions[_question_index]
	if choice_index != question_data.correct_choice_index:
		UIFeedback.play_lose(self)
		var wrong_button := choice_buttons[choice_index]
		wrong_button.disabled = true
		wrong_button.modulate = INCORRECT_COLOR
		UIFeedback.shake(wrong_button)
		return
	for button in choice_buttons:
		button.disabled = true
	UIFeedback.play_win(self)
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
