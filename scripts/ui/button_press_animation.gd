class_name ButtonPressAnimation
extends Node

@export_group("Réglages")
## Écrasement du bouton quand il est enfoncé (1, 1 = pas d'écrasement).
@export var press_scale := Vector2(0.92, 0.88)
## Grossissement au survol de la souris (1 = aucun).
@export var hover_scale := 1.04
## Son joué au clic (nom d'un son de Sfx : click, pop, type…). Vide = bouton silencieux.
@export var sound := "click"

var _button: BaseButton
var _tween: Tween


func _ready() -> void:
	_button = get_parent() as BaseButton
	_button.resized.connect(_center_pivot)
	_center_pivot()
	_button.button_down.connect(_animate.bind(press_scale, 0.08, Tween.TRANS_QUAD))
	_button.button_up.connect(_animate.bind(Vector2.ONE, 0.5, Tween.TRANS_ELASTIC))
	_button.mouse_entered.connect(_on_mouse_entered)
	_button.mouse_exited.connect(_animate.bind(Vector2.ONE, 0.25, Tween.TRANS_BACK))
	_button.pressed.connect(_on_pressed)


func _center_pivot() -> void:
	_button.pivot_offset = _button.size / 2


func _on_mouse_entered() -> void:
	if not _button.disabled:
		_animate(Vector2.ONE * hover_scale, 0.25, Tween.TRANS_BACK)


func _on_pressed() -> void:
	if not sound.is_empty():
		Sfx.play(sound)


func _animate(target: Vector2, duration: float, trans: Tween.TransitionType) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = _button.create_tween()
	_tween.tween_property(_button, "scale", target, duration).set_trans(trans).set_ease(Tween.EASE_OUT)
