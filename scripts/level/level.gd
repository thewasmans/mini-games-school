class_name Level
extends Control

@export var mini_game_label: Label
@export var mini_game_container: Control
@export var crossword_prefab: PackedScene

var level_index: int
var level_data: LevelData

func initialize(_level_index: int, _level_data: LevelData) -> void:
	level_index = _level_index
	level_data = _level_data
	if level_data.mini_games.is_empty():
		mini_game_label.text = "Level %d - Aucun mini-jeu" % (level_index + 1)
		return
	var mini_game := level_data.mini_games[0]
	if mini_game is CrosswordData:
		mini_game_label.hide()
		var crossword := crossword_prefab.instantiate() as CrosswordUI
		mini_game_container.add_child(crossword)
		crossword.initialize(mini_game)
	else:
		mini_game_label.text = "Level %d - %s" % [level_index + 1, mini_game.get_script().get_global_name()]
