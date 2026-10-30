class_name MenuStartUI
extends MenuUI

signal play_pressed
signal credits_pressed

@export var logo: Control
@export var title_image: TextureRect
@export var hero: Control
@export var play_button: JuicyButton
@export var credits_button: JuicyButton

@export_group("Réglages")
## Inclinaison maximale du titre quand il se balance, en radians.
@export var title_wobble := 0.025
## Durée d'un balancement du titre, en secondes.
@export var title_wobble_duration := 1.5

var _intro_played := false


func _refresh() -> void:
	if _intro_played:
		return
	_intro_played = true
	UIFeedback.pop_in(logo, 0.1, 0.3)
	UIFeedback.pop_in(hero, 0.25, 0.4)
	UIFeedback.pop_in(play_button, 0.5, 0.3)
	UIFeedback.pop_in(credits_button, 0.6, 0.5)
	await get_tree().create_timer(0.7).timeout
	title_image.pivot_offset = title_image.size / 2
	var wobble := title_image.create_tween().set_loops()
	wobble.tween_property(title_image, "rotation", title_wobble, title_wobble_duration).set_trans(Tween.TRANS_SINE)
	wobble.tween_property(title_image, "rotation", -title_wobble, title_wobble_duration).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.4).timeout
	UIFeedback.breathe(play_button, 0.04, 1.3)


func _on_play_button_pressed() -> void:
	play_pressed.emit()


func _on_credits_button_pressed() -> void:
	credits_pressed.emit()
