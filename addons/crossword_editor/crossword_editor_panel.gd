@tool
extends VBoxContainer

const CrosswordGridPreview := preload("res://addons/crossword_editor/crossword_grid_preview.gd")
const SETTINGS_SECTION := "crossword_editor"
const SETTINGS_LAST_PATH := "last_path"
const ISOLATED_TEXT_COLOR := Color(1.0, 0.7, 0.4)
const ERROR_TEXT_COLOR := Color(1.0, 0.45, 0.45)

var _crossword_data: CrosswordData
var _file_dialog: EditorFileDialog
var _path_label: Label
var _status_label: Label
var _regenerate_button: Button
var _grid_preview: CrosswordGridPreview
var _clue_list: ItemList

func _ready() -> void:
	size_flags_vertical = SIZE_EXPAND_FILL
	_build_toolbar()
	_build_body()
	_build_file_dialog()
	_open_last_crossword()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and is_visible_in_tree():
		_refresh()

func _build_toolbar() -> void:
	var toolbar := HBoxContainer.new()
	add_child(toolbar)
	var open_button := Button.new()
	open_button.text = "Ouvrir un mot croisé…"
	open_button.icon = _editor_icon("Load")
	open_button.pressed.connect(_on_open_pressed)
	toolbar.add_child(open_button)
	_regenerate_button = Button.new()
	_regenerate_button.text = "Régénérer la grille"
	_regenerate_button.icon = _editor_icon("Reload")
	_regenerate_button.pressed.connect(_on_regenerate_pressed)
	toolbar.add_child(_regenerate_button)
	_path_label = Label.new()
	_path_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	toolbar.add_child(_path_label)
	_status_label = Label.new()
	add_child(_status_label)

func _build_body() -> void:
	var split := HSplitContainer.new()
	split.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(split)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	split.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(center)
	_grid_preview = CrosswordGridPreview.new()
	center.add_child(_grid_preview)
	_clue_list = ItemList.new()
	_clue_list.custom_minimum_size.x = 360
	split.add_child(_clue_list)

func _build_file_dialog() -> void:
	_file_dialog = EditorFileDialog.new()
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_file_dialog.add_filter("*.tres, *.res", "Ressource")
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

func _open_last_crossword() -> void:
	var last_path: String = EditorInterface.get_editor_settings().get_project_metadata(SETTINGS_SECTION, SETTINGS_LAST_PATH, "")
	if ResourceLoader.exists(last_path):
		_on_file_selected(last_path)
	else:
		_refresh()

func _on_open_pressed() -> void:
	_file_dialog.popup_centered_ratio(0.5)

func _on_file_selected(path: String) -> void:
	var resource := load(path)
	if not resource is CrosswordData:
		_show_error("%s n'est pas une ressource CrosswordData." % path)
		return
	EditorInterface.get_editor_settings().set_project_metadata(SETTINGS_SECTION, SETTINGS_LAST_PATH, path)
	if _crossword_data != null:
		_crossword_data.changed.disconnect(_refresh)
	_crossword_data = resource
	_crossword_data.changed.connect(_refresh)
	_refresh()

func _on_regenerate_pressed() -> void:
	CrosswordGenerator.regenerate(_crossword_data)
	var error := ResourceSaver.save(_crossword_data)
	if error != OK:
		_show_error("Échec de l'enregistrement de %s (%s)." % [_crossword_data.resource_path, error_string(error)])
		return
	_refresh()

func _refresh() -> void:
	var has_data := _crossword_data != null
	_regenerate_button.disabled = not has_data
	_path_label.text = _crossword_data.resource_path if has_data else "Aucun mot croisé ouvert"
	_clue_list.clear()
	_status_label.remove_theme_color_override("font_color")
	if not has_data:
		_grid_preview.set_placements([])
		_status_label.text = ""
		return
	var placements := _crossword_data.build_placements()
	_grid_preview.set_placements(placements)
	for index in placements.size():
		var placement := placements[index]
		var arrow := "→" if placement.is_horizontal else "↓"
		var item_index := _clue_list.add_item("%d. %s %s (%d, %d) — %s" % [index + 1, arrow, placement.word_data.word, placement.start.x, placement.start.y, placement.word_data.hint])
		if placement in _grid_preview.isolated_placements:
			_clue_list.set_item_custom_fg_color(item_index, ISOLATED_TEXT_COLOR)
	_status_label.text = "%d mot(s) · %d isolé(s) · %d case(s) en conflit" % [placements.size(), _grid_preview.isolated_placements.size(), _grid_preview.conflict_cells.size()]

func _show_error(message: String) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", ERROR_TEXT_COLOR)

func _editor_icon(icon_name: String) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")
