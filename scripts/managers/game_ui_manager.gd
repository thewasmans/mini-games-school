class_name GameUIManager
extends Manager

@export var game_ui_prefab: PackedScene
@export var root_scene: Node
var _game_ui:GameUI

func initialize(game_manager:GameManager):
	super.initialize(game_manager)
	_game_ui = game_ui_prefab.instantiate()
	_game_ui.initialize(game_manager)
	root_scene.add_child(_game_ui)
