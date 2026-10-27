class_name GameUI
extends Control

const STUDY_LEVEL_BUTTON_MIN_SIZE := Vector2(360, 90)
const STUDY_LEVEL_BUTTON_FONT_SIZE := 40
const STUDY_LEVEL_PROGRESS_HEIGHT := 28
const STUDY_LEVEL_ENTRY_SEPARATION := 8

@export var menu_start: MenuStartUI
@export var menu_study_levels: MenuStudyLevelsUI
@export var menu_subjects: MenuSubjectsUI
@export var menu_levels: MenuLevelsUI
@export var menu_credits: MenuCreditsUI
@export var button_level_prefab: PackedScene

var _game_manager: GameManager
var _level_buttons: Array[ButtonLevelUI] = []
var _study_level_progress_bars: Array[ProgressBar] = []

func initialize(game_manager: GameManager) -> void:
	_game_manager = game_manager
	menu_study_levels.hide()
	menu_subjects.hide()
	menu_levels.hide()
	menu_credits.hide()
	menu_start.play_pressed.connect(_on_play_button_pressed)
	menu_start.credits_pressed.connect(_on_credits_button_pressed)
	menu_study_levels.back_pressed.connect(_on_menu_study_levels_back)
	menu_subjects.back_pressed.connect(_on_menu_subjects_back)
	menu_levels.back_pressed.connect(_on_menu_levels_back)
	menu_credits.back_pressed.connect(_on_menu_credits_back)
	_game_manager.game_state.level_unlocked.connect(_on_level_unlocked)
	_game_manager.game_state.current_level_changed.connect(_on_current_level_changed)
	_populate_study_levels()

func _populate_study_levels() -> void:
	var study_levels := _game_manager.game_data.study_levels
	for study_level_index in study_levels.size():
		var entry := VBoxContainer.new()
		entry.add_theme_constant_override("separation", STUDY_LEVEL_ENTRY_SEPARATION)
		var button := _create_choice_button(study_levels[study_level_index].name)
		button.pressed.connect(_on_study_level_selected.bind(study_level_index))
		entry.add_child(button)
		var progress_bar := ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(STUDY_LEVEL_BUTTON_MIN_SIZE.x, STUDY_LEVEL_PROGRESS_HEIGHT)
		entry.add_child(progress_bar)
		_study_level_progress_bars.append(progress_bar)
		menu_study_levels.buttons_container.add_child(entry)

func _show_study_levels_menu() -> void:
	var game_state := _game_manager.game_state
	for study_level_index in _study_level_progress_bars.size():
		var progress_bar := _study_level_progress_bars[study_level_index]
		progress_bar.max_value = maxi(1, game_state.level_count(study_level_index))
		progress_bar.value = game_state.completed_level_count(study_level_index)
	menu_study_levels.show()

func _populate_subjects(study_level_index: int) -> void:
	for child in menu_subjects.buttons_container.get_children():
		child.queue_free()
	var study_level := _game_manager.game_data.study_levels[study_level_index]
	menu_subjects.title_label.text = study_level.name
	var subjects := study_level.subjects
	for subject_index in subjects.size():
		var button := _create_choice_button(subjects[subject_index].name)
		button.pressed.connect(_on_subject_selected.bind(subject_index))
		menu_subjects.buttons_container.add_child(button)

func _create_choice_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = STUDY_LEVEL_BUTTON_MIN_SIZE
	button.add_theme_font_size_override("font_size", STUDY_LEVEL_BUTTON_FONT_SIZE)
	return button

func _on_play_button_pressed() -> void:
	_show_study_levels_menu()

func _on_credits_button_pressed() -> void:
	menu_credits.show()

func _on_menu_credits_back() -> void:
	menu_credits.hide()

func _on_menu_study_levels_back() -> void:
	menu_study_levels.hide()

func _on_study_level_selected(study_level_index: int) -> void:
	_game_manager.game_state.select_study_level(study_level_index)
	menu_study_levels.hide()
	_populate_subjects(study_level_index)
	menu_subjects.show()

func _on_menu_subjects_back() -> void:
	menu_subjects.hide()
	_show_study_levels_menu()

func _on_subject_selected(subject_index: int) -> void:
	_game_manager.game_state.select_subject(subject_index)
	var study_level := _game_manager.game_data.study_levels[_game_manager.game_state.current_study_level]
	menu_levels.title_label.text = "%s - %s" % [study_level.name, study_level.subjects[subject_index].name]
	menu_subjects.hide()
	_build_level_grid()
	menu_levels.show()

func _on_menu_levels_back() -> void:
	menu_levels.hide()
	menu_subjects.show()

func _build_level_grid() -> void:
	for child in menu_levels.grid_container.get_children():
		menu_levels.grid_container.remove_child(child)
		child.queue_free()
	var columns := menu_levels.grid_container.columns
	var game_state := _game_manager.game_state
	var levels := _game_manager.game_data.levels_of(game_state.current_study_level, game_state.current_subject)
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
		for _column in columns - row.size():
			row.append(-1)
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
	if menu_levels.grid_container.resized.is_connected(_on_levels_container_resized):
		menu_levels.grid_container.resized.disconnect(_on_levels_container_resized)
	menu_levels.grid_container.resized.connect(_on_levels_container_resized, CONNECT_ONE_SHOT)
	_on_levels_container_resized()
	if not _level_buttons.is_empty():
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
