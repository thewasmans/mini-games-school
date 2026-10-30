@tool
class_name StarGauge
extends Control

signal star_reached(star_index: int)

@export var bar: JuicyProgressBar

@export_group("Réglages")
## Position de chaque étoile sur la jauge, de 0 à 1 (aperçu dans l'éditeur ; le level le remplace).
@export var thresholds: Array[float] = [0.3, 0.6, 0.9]:
	set(new_value):
		thresholds = new_value
		queue_redraw()
## Rayon d'une étoile, par rapport à la hauteur du composant.
@export_range(0.2, 0.6) var star_radius := 0.46
## Couleur d'une étoile remportée.
@export var fill_color := UIStyle.YELLOW
## Couleur d'une étoile que la jauge n'a pas encore atteinte.
@export var empty_color := Color(0.42, 0.48, 0.72, 1)
## Agrandissement d'une étoile au moment où la jauge l'atteint.
@export var reach_punch := 0.6
## Durée de l'agrandissement d'une étoile atteinte, en secondes.
@export var reach_duration := 0.45

var reached_count := 0
var _punch_times: Array[float] = []


func _ready() -> void:
	set_process(not Engine.is_editor_hint())


func initialize(thresholds_: Array[float]) -> void:
	thresholds = thresholds_
	reached_count = 0
	_punch_times.clear()
	bar.set_value(0.0, false)
	queue_redraw()


func set_value(value: float) -> void:
	bar.set_value(value)


func _process(delta: float) -> void:
	while reached_count < thresholds.size() and bar.shown_value >= thresholds[reached_count] - 0.0001:
		_punch_times.append(reach_duration)
		reached_count += 1
		star_reached.emit(reached_count - 1)
	for star_index in _punch_times.size():
		_punch_times[star_index] = maxf(_punch_times[star_index] - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var radius := size.y * star_radius
	for star_index in thresholds.size():
		var center := Vector2(bar.position.x + 4 + (bar.size.x - 8) * thresholds[star_index], bar.position.y + bar.size.y / 2)
		var reached := star_index < reached_count
		var punch := 0.0
		if star_index < _punch_times.size():
			punch = sin(_punch_times[star_index] / reach_duration * PI) * reach_punch
		UIDraw.rating_star(self, center, radius * (1.0 + punch), 1.0 if reached else 0.0, fill_color, empty_color)
