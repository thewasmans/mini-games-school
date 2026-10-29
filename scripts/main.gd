class_name Main
extends Control

@export var game_manager: GameManager
@export var debug_helper_prefab: PackedScene


func _ready() -> void:
	game_manager.initialize()
	if OS.has_feature("editor"):
		var debug_helper := debug_helper_prefab.instantiate() as DebugHelper
		add_child(debug_helper)
		debug_helper.initialize(game_manager)
