class_name GameManager
extends Node

signal initialized

@export var game_data: GameData
@export var managers: Array[Manager] = []

var game_state: GameState
var housing_state: HousingState

var game_ui_manager: GameUIManager:
	get:
		return _manager_of_type(GameUIManager)

var level_manager: LevelManager:
	get:
		return _manager_of_type(LevelManager)

var house_manager: HouseManager:
	get:
		return _manager_of_type(HouseManager)


func initialize() -> void:
	game_state = GameState.new(game_data)
	housing_state = HousingState.new(HousingCatalog.new(game_data))
	for manager in managers:
		manager.initialize(self)
	initialized.emit()


func _manager_of_type(type: Script) -> Manager:
	for manager in managers:
		if is_instance_of(manager, type):
			return manager
	return null
