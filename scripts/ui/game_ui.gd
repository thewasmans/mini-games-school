class_name GameUI
extends Control

const STUDY_LEVEL_BUTTON_MIN_SIZE := Vector2(360, 90)
const STUDY_LEVEL_BUTTON_FONT_SIZE := 40

@export var menu_study_levels: MenuStudyLevelsUI
@export var menu_levels: MenuLevelsUI
@export var button_level_prefab: PackedScene

var _game_manager: GameManager
var _level_buttons: Array[ButtonLevelUI] = []

func initialize(game_manager: GameManager) -> void:
	_game_manager = game_manager
	menu_study_levels.hide()
	menu_levels.hide()
	menu_study_levels.back_pressed.connect(_on_menu_study_levels_back)
	menu_levels.back_pressed.connect(_on_menu_levels_back)
	_game_manager.game_state.level_unlocked.connect(_on_level_unlocked)
	_game_manager.game_state.current_level_changed.connect(_on_current_level_changed)
	_populate_study_levels()

func _populate_study_levels() -> void:
	var study_levels := _game_manager.game_data.study_levels
	for study_level_index in study_levels.size():
		var button := Button.new()
		button.text = study_levels[study_level_index].name
		button.custom_minimum_size = STUDY_LEVEL_BUTTON_MIN_SIZE
		button.add_theme_font_size_override("font_size", STUDY_LEVEL_BUTTON_FONT_SIZE)
		button.pressed.connect(_on_study_level_selected.bind(study_level_index))
		menu_study_levels.buttons_container.add_child(button)

func _on_play_button_pressed() -> void:
	menu_study_levels.show()

func _on_menu_study_levels_back() -> void:
	menu_study_levels.hide()

func _on_study_level_selected(study_level_index: int) -> void:
	_game_manager.game_state.select_study_level(study_level_index)
	menu_study_levels.hide()
	_build_level_grid(study_level_index)
	menu_levels.show()

func _on_menu_levels_back() -> void:
	menu_levels.hide()
	menu_study_levels.show()

func _build_level_grid(study_level_index: int) -> void:
	for child in menu_levels.grid_container.get_children():
		child.queue_free()
	var columns := menu_levels.grid_container.columns
	var levels := _game_manager.game_data.study_levels[study_level_index].levels
	_level_buttons.resize(levels.size())
	var rows: Array[Array] = []
	var index := 0
	var content_row := 0
	while index < levels.size():
		var row_size: int = min(columns, levels.size() - index)
		var row_level_indices := range(index, index + row_size)
		var is_reversed := content_row % 2 == 1
		if is_reversed:
			row_level_indices.reverse()
		var row: Array[int] = []
		if is_reversed:
			for _column in columns - row_size:
				row.append(-1)
		for level_index in row_level_indices:
			row.append(level_index)
		rows.append(row)
		index += row_size
		var connector_on_right := content_row % 2 == 0
		content_row += 1
		if index < levels.size():
			var connector_row: Array[int] = []
			if connector_on_right:
				for _column in columns - 1:
					connector_row.append(-1)
				connector_row.append(index)
			else:
				connector_row.append(index)
				for _column in columns - 1:
					connector_row.append(-1)
			rows.append(connector_row)
			index += 1
	rows.reverse()
	for r in rows.size():
		var render_row: Array = rows[r]
		for c in render_row.size():
			var level_index: int = render_row[c]
			if level_index == -1:
				menu_levels.grid_container.add_child(Control.new())
			else:
				_add_level_button(level_index, study_level_index)
	if menu_levels.grid_container.resized.is_connected(_on_levels_container_resized):
		menu_levels.grid_container.resized.disconnect(_on_levels_container_resized)
	menu_levels.grid_container.resized.connect(_on_levels_container_resized, CONNECT_ONE_SHOT)
	_on_levels_container_resized()
	if not _level_buttons.is_empty():
		_level_buttons[_game_manager.game_state.current_level].set_current(true)

func _add_level_button(level_index: int, study_level_index: int) -> void:
	var button_level := button_level_prefab.instantiate() as ButtonLevelUI
	button_level.initialize(level_index, _game_manager.game_state.is_level_unlocked(study_level_index, level_index))
	button_level.selected.connect(_on_level_selected)
	_level_buttons[level_index] = button_level
	menu_levels.grid_container.add_child(button_level)

func _on_level_unlocked(study_level_index: int, level_index: int) -> void:
	if study_level_index != _game_manager.game_state.current_study_level:
		return
	_level_buttons[level_index].set_unlocked(true)

func _on_current_level_changed(level_index: int) -> void:
	for button_level in _level_buttons:
		button_level.set_current(false)
	_level_buttons[level_index].set_current(true)

func _on_level_selected(level_index: int) -> void:
	_game_manager.game_state.select_level(level_index)
	hide()
	_game_manager.level_manager.start_level(level_index)

func _on_levels_container_resized() -> void:
	menu_levels.scrol_container.scroll_vertical = 999999999
