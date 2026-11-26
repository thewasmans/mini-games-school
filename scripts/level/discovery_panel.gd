class_name DiscoveryPanel
extends Control

signal closed

@export var points_label: Label
@export var objects_title: Label
@export var rows_container: VBoxContainer
@export var continue_button: JuicyButton
@export var row_prefab: PackedScene

@export_group("Réglages")
## Délai entre l'animation de deux jauges d'objets, en secondes.
@export var row_delay := 0.35

var rows: Array[DiscoveryRow] = []


func _ready() -> void:
	continue_button.pressed.connect(closed.emit)


func initialize(gained_points: int, action_points: int, progress: Array[Dictionary]) -> void:
	points_label.visible = gained_points > 0
	points_label.text = "+%d points d'action  (%d au total)" % [gained_points, action_points]
	objects_title.visible = not progress.is_empty()
	for entry in progress:
		var item: HousingItemData = entry.item
		var row := row_prefab.instantiate() as DiscoveryRow
		rows_container.add_child(row)
		row.initialize(item.title if not item.title.is_empty() else item.word, entry.before, entry.after, entry.size)
		rows.append(row)
	UIFeedback.pop_in(continue_button, 0.2)
	_play_rows()


func _play_rows() -> void:
	for row in rows:
		await get_tree().create_timer(row_delay).timeout
		if not is_inside_tree():
			return
		row.play()
