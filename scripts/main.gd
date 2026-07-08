class_name Main
extends Node

@export var game_manager: GameManager

func _ready() -> void:
	game_manager.initialize()
