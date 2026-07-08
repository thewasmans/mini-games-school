class_name GameUI
extends Control

@export var levels_container: GridContainer
@export var button_level_prefab: PackedScene

var _game_manager:GameManager

func initialize(game_manager:GameManager):
	_game_manager = game_manager
	for level_index in _game_manager.game_data.levels.size():
		var button_level := button_level_prefab.instantiate() as ButtonLevelUI
		button_level.initialize(level_index + 1)
		levels_container.add_child(button_level)
