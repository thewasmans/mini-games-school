class_name HouseInventory
extends Control

signal take_requested(item: HousingItemData)
signal play_requested(item: HousingItemData)

@export var panel: TitledPanel
@export var rows_container: VBoxContainer
@export var close_button: JuicyButton
@export var row_prefab: PackedScene


func _ready() -> void:
	close_button.pressed.connect(hide)


func show_room(subject_key: Vector3i, title: String, housing_state: HousingState) -> void:
	panel.title = title
	for child in rows_container.get_children():
		rows_container.remove_child(child)
		child.queue_free()
	var items := housing_state.catalog.items(subject_key)
	var sorted := items.duplicate()
	sorted.sort_custom(func(a: HousingItemData, b: HousingItemData) -> bool:
		return _rank(subject_key, a, housing_state) < _rank(subject_key, b, housing_state))
	for item: HousingItemData in sorted:
		var row := row_prefab.instantiate() as InventoryRow
		rows_container.add_child(row)
		row.initialize(item, housing_state.gauge(subject_key, item), housing_state.is_unlocked(subject_key, item),
			housing_state.is_placed(subject_key, item), housing_state.catalog.levels_with(item))
		row.take_pressed.connect(take_requested.emit)
		row.play_pressed.connect(play_requested.emit)
	show()
	UIFeedback.pop_in(panel, 0.0, 0.85)


func _rank(subject_key: Vector3i, item: HousingItemData, housing_state: HousingState) -> int:
	if housing_state.is_placed(subject_key, item):
		return 2
	return 0 if housing_state.is_unlocked(subject_key, item) else 1
