@tool
class_name StarRating
extends Control

@export_group("Réglages")
## Nombre d'étoiles remplies, décimales comprises (aperçu dans l'éditeur ; le jeu le remplace).
@export_range(0.0, 3.0, 0.1) var value := 3.0:
	set(new_value):
		value = new_value
		queue_redraw()
## Nombre d'étoiles affichées.
@export var star_count := 3:
	set(new_value):
		star_count = new_value
		queue_redraw()
## Couleur de la partie remplie d'une étoile.
@export var fill_color := UIStyle.YELLOW
## Couleur de la partie vide d'une étoile.
@export var empty_color := Color(0.05, 0.08, 0.25, 0.55)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := minf(size.x / star_count, size.y)
	var left := (size.x - side * star_count) / 2.0
	for star_index in star_count:
		var center := Vector2(left + side * (star_index + 0.5), size.y / 2.0)
		UIDraw.rating_star(self, center, side * 0.44, clampf(value - star_index, 0.0, 1.0), fill_color, empty_color)
