class_name ChoiceEntryUI
extends VBoxContainer

signal pressed

@export var button: JuicyButton
@export var gauge: JuicyProgressBar
@export var coming_soon_label: Label

@export_group("Réglages")
## Couleur du bouton quand le choix n'a encore aucun level.
@export var unavailable_color := Color("8a93a6")
## Délai avant que la jauge se remplisse, en secondes.
@export var gauge_delay := 0.35

var _available_color: Color


func _ready() -> void:
	_available_color = button.color
	button.pressed.connect(pressed.emit)


func set_color(color: Color) -> void:
	_available_color = color
	button.color = color


func set_progress(completed_count: int, total_count: int) -> void:
	var available := total_count > 0
	button.disabled = not available
	button.color = _available_color if available else unavailable_color
	button.sparkles = available
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND if available else CURSOR_FORBIDDEN
	coming_soon_label.visible = not available
	gauge.visible = available
	if not available:
		return
	gauge.fill_color = _available_color.lightened(0.15)
	gauge.text = "%d / %d levels" % [completed_count, total_count]
	gauge.set_value(0.0, false)
	await get_tree().create_timer(gauge_delay).timeout
	if is_inside_tree():
		gauge.set_value(completed_count / float(total_count))
