class_name Main
extends Node

@export var game_manager: GameManager

func _ready() -> void:
	game_manager.initialize()
	_spawn_debug_helper()

func _spawn_debug_helper() -> void:
	if not OS.has_feature("editor"):
		return
	add_child(DebugHelper.new())
