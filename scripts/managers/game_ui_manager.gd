class_name GameUIManager
extends Manager

@export var game_ui_prefab: PackedScene
@export var root_scene: Node
@export var background: AnimatedBackground

var _game_ui: GameUI


func initialize(game_manager: GameManager) -> void:
	super.initialize(game_manager)
	_game_ui = game_ui_prefab.instantiate()
	root_scene.add_child(_game_ui)
	_game_ui.initialize(game_manager)
	_game_ui.level_requested.connect(_on_level_requested)
	_game_ui.study_level_shown.connect(background.set_study_level)
	game_manager.level_manager.level_closed.connect(_on_level_closed)


func _on_level_requested(level_index: int) -> void:
	_game_ui.hide()
	_game_manager.level_manager.start_level(level_index)


func _on_level_closed() -> void:
	_game_ui.show()
	_game_ui.show_levels_menu()
