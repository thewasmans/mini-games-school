@abstract
class_name Manager
extends Node

var game_state: GameState:
	get:
		return _game_manager.game_state

var game_data: GameData:
	get:
		return _game_manager.game_data
var _game_manager:GameManager

func initialize(game_manager:GameManager):
	_game_manager = game_manager
