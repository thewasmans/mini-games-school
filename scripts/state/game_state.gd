extends Object
class_name GameState

var current_level: int
var current_mini_game: int

func _init(_game_data:GameData) -> void:
	current_level = 0
	current_mini_game = 0
