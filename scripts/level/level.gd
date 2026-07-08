class_name Level
extends Control

@export var mini_game_label: Label

var level_index: int
var level_data: LevelData

func initialize(_level_index: int, _level_data: LevelData) -> void:
	level_index = _level_index
	level_data = _level_data
	var mini_game_name := "Aucun mini-jeu"
	if level_data.mini_games.size() > 0:
		mini_game_name = level_data.mini_games[0].get_script().get_global_name()
	mini_game_label.text = "Level %d - %s" % [level_index + 1, mini_game_name]
