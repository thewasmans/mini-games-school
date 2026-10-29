class_name MiniGamePrefabs
extends Resource

@export var prefabs: Dictionary[Script, PackedScene] = {}


func prefab_for(mini_game_data: MiniGameData) -> PackedScene:
	return prefabs.get(mini_game_data.get_script())
