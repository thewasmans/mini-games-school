class_name HouseManager
extends Manager

signal house_closed
signal play_requested(subject_key: Vector3i, level_index: int)

@export var house_root: Node
@export var house_prefab: PackedScene

var house: House


func open_house() -> void:
	if house != null:
		return
	house = house_prefab.instantiate() as House
	house_root.add_child(house)
	house.initialize(game_state, housing_state, game_data, game_state.current_subject_key)
	house.closed.connect(_on_house_closed)
	house.play_requested.connect(_on_play_requested)


func _on_house_closed() -> void:
	_free_house()
	house_closed.emit()


func _on_play_requested(subject_key: Vector3i, level_index: int) -> void:
	_free_house()
	play_requested.emit(subject_key, level_index)


func _free_house() -> void:
	house.queue_free()
	house = null
