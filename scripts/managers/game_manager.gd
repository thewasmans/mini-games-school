class_name GameManager
extends Node

signal initialized

@export var game_data: GameData
@export var managers: Array[Manager] = []

var game_state: GameState

var game_ui_manager: GameUIManager:
	get:
		return _manager_of_type(GameUIManager)

var level_manager: LevelManager:
	get:
		return _manager_of_type(LevelManager)


func initialize() -> void:
	game_state = GameState.new(game_data)
	for manager in managers:
		manager.initialize(self)
	initialized.emit()


func _manager_of_type(type: Script) -> Manager:
	for manager in managers:
		if is_instance_of(manager, type):
			return manager
	return null
