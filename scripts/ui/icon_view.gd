class_name IconView
extends Control
## Affiche une icône vectorielle de UIDraw.

var icon := ""


func _init(icon_: String, side := 40.0) -> void:
	icon = icon_
	custom_minimum_size = Vector2(side, side)
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	UIDraw.icon(self, icon, size / 2, minf(size.x, size.y))
