class_name TopBar
extends HBoxContainer

signal back_pressed

@export var back_button: JuicyButton
@export var stars_pill: StarsPill
@export var sound_button: JuicyButton

@export_group("Réglages")
## Affiche le bouton retour en haut à gauche. Décoché, sa place reste vide pour garder la pastille centrée.
@export var show_back := true


func _ready() -> void:
	back_button.modulate.a = 1.0 if show_back else 0.0
	back_button.disabled = not show_back
	back_button.mouse_filter = MOUSE_FILTER_STOP if show_back else MOUSE_FILTER_IGNORE
	_update_sound_icon()


func set_progress(progress: Vector2i) -> void:
	stars_pill.set_progress(progress)


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _on_sound_button_pressed() -> void:
	Sfx.muted = not Sfx.muted
	_update_sound_icon()
	UIFeedback.float_text(sound_button, "Son coupé" if Sfx.muted else "Son activé", Color.WHITE, 26)


func _update_sound_icon() -> void:
	sound_button.icon_kind = "sound_off" if Sfx.muted else "gear"
