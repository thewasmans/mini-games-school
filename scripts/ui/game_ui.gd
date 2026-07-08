class_name GameUI
extends Control

@export var menu_levels: MenuLevelsUI
@export var button_level_prefab: PackedScene

var _game_manager:GameManager
var _level_buttons: Array[ButtonLevelUI] = []

func initialize(game_manager:GameManager):
	$MenuLevelsUI.hide()
	_game_manager = game_manager
	_game_manager.game_state.level_unlocked.connect(_on_level_unlocked)
	_game_manager.game_state.current_level_changed.connect(_on_current_level_changed)
	var columns := menu_levels.grid_container.columns
	var levels := _game_manager.game_data.levels
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
				_add_level_button(level_index)
	menu_levels.grid_container.resized.connect(_on_levels_container_resized, CONNECT_ONE_SHOT)
	_on_levels_container_resized()
	_level_buttons[_game_manager.game_state.current_level].set_current(true)

func _add_level_button(level_index: int) -> void:
	var button_level := button_level_prefab.instantiate() as ButtonLevelUI
	button_level.initialize(level_index, _game_manager.game_state.is_level_unlocked(level_index))
	button_level.selected.connect(_on_level_selected)
	_level_buttons[level_index] = button_level
	menu_levels.grid_container.add_child(button_level)

func _on_level_unlocked(level_index: int) -> void:
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

func _on_play_button_pressed() -> void:
	$MenuLevelsUI.show()
