class_name GameUI
extends Control

@export var levels_container: GridContainer
@export var button_level_prefab: PackedScene

var _game_manager:GameManager

func initialize(game_manager:GameManager):
	_game_manager = game_manager
	var columns := levels_container.columns
	var levels := _game_manager.game_data.levels
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
				levels_container.add_child(Control.new())
			else:
				_add_level_button(level_index)

func _add_level_button(level_index: int) -> void:
	var button_level := button_level_prefab.instantiate() as ButtonLevelUI
	button_level.initialize(level_index + 1)
	levels_container.add_child(button_level)
