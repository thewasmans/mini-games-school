extends Node
class_name GameManager

signal initialized

@export var game_data: GameData
@export_category("Managers")
@export var save_manager: SaveManager
@export var game_ui_manager: GameUIManager
@export var level_manager: LevelManager

var game_state:GameState
var managers:Array[Manager]:
	get:
		return [save_manager, game_ui_manager, level_manager]

func initialize():
	game_state = GameState.new(game_data)
	for manager in managers:
		manager.initialize(self)
	initialized.emit()
