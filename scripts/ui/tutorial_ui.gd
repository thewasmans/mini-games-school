class_name TutorialUI
extends Control

@export var slides: Array[TutorialSlideData] = []
@export var image_rect: TextureRect
@export var text_label: Label
@export var next_button: Button

var _slide_index := 0

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	_show_slide(0)

func _show_slide(index: int) -> void:
	_slide_index = index
	var slide := slides[_slide_index]
	image_rect.texture = slide.image
	text_label.text = slide.text
	next_button.text = "Suivant" if _slide_index < slides.size() - 1 else "Compris !"

func _on_next_pressed() -> void:
	if _slide_index < slides.size() - 1:
		_show_slide(_slide_index + 1)
	else:
		queue_free()
