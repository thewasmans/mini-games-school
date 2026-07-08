class_name Level
extends Control

@export var mini_game_label: Label
@export var mini_game_container: Control
@export var crossword_prefab: PackedScene
@export var validate_button: Button
@export var back_button: Button

var level_index: int
var level_data: LevelData
var _game_manager: GameManager

func initialize(_level_index: int, _level_data: LevelData, game_manager: GameManager) -> void:
	level_index = _level_index
	level_data = _level_data
	_game_manager = game_manager
	validate_button.hide()
	validate_button.pressed.connect(_on_validate_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	if level_data.mini_games.is_empty():
		mini_game_label.text = "Level %d - Aucun mini-jeu" % (level_index + 1)
		return
	var mini_game := level_data.mini_games[0]
	if mini_game is CrosswordData:
		mini_game_label.hide()
		var crossword := crossword_prefab.instantiate() as CrosswordUI
		mini_game_container.add_child(crossword)
		crossword.completed.connect(_on_mini_game_completed)
		crossword.initialize(mini_game)
	else:
		mini_game_label.text = "Level %d - %s" % [level_index + 1, mini_game.get_script().get_global_name()]

func _on_mini_game_completed() -> void:
	validate_button.show()

func _on_validate_button_pressed() -> void:
	_game_manager.game_state.complete_level(level_index)
	_game_manager.game_ui_manager.show_menu()
	queue_free()

func _on_back_button_pressed() -> void:
	_game_manager.game_ui_manager.show_menu()
	queue_free()
