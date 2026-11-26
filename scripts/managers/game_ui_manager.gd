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
	_game_ui.house_requested.connect(_on_house_requested)
	game_manager.house_manager.house_closed.connect(_on_house_closed)
	game_manager.house_manager.play_requested.connect(_on_house_play_requested)


func _on_level_requested(level_index: int) -> void:
	_game_ui.hide()
	_game_manager.level_manager.start_level(level_index)


func _on_house_requested() -> void:
	_game_ui.hide()
	background.hide()
	_game_manager.house_manager.open_house()


func _on_house_closed() -> void:
	background.show()
	_game_ui.show()
	_game_ui.show_current_menu()


func _on_house_play_requested(subject_key: Vector3i, level_index: int) -> void:
	background.show()
	_game_ui.show()
	if game_data.get_subject(subject_key.x, subject_key.y, subject_key.z) == null:
		_game_ui.show_current_menu()
		return
	if level_index >= 0:
		game_state.select_study_level(subject_key.x)
		game_state.select_school_year(subject_key.y)
		game_state.select_subject(subject_key.z)
		game_state.select_level(level_index)
	_game_ui.open_subject_levels(subject_key)


func _on_level_closed() -> void:
	_game_ui.show()
	_game_ui.show_levels_menu()
