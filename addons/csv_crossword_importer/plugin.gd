@tool
extends EditorPlugin

const MENU_ITEM_TEXT := "Importer un mot croisé (CSV)..."

var _csv_file_dialog: EditorFileDialog
var _save_file_dialog: EditorFileDialog
var _pending_crossword_data: CrosswordData

func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_TEXT, _on_import_csv_pressed)

func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_TEXT)
	if _csv_file_dialog != null:
		_csv_file_dialog.queue_free()
	if _save_file_dialog != null:
		_save_file_dialog.queue_free()

func _on_import_csv_pressed() -> void:
	if _csv_file_dialog == null:
		_csv_file_dialog = EditorFileDialog.new()
		_csv_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_csv_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		_csv_file_dialog.add_filter("*.csv", "Fichier CSV")
		_csv_file_dialog.file_selected.connect(_on_csv_selected)
		EditorInterface.get_base_control().add_child(_csv_file_dialog)
	_csv_file_dialog.popup_centered_ratio(0.5)

func _on_csv_selected(path: String) -> void:
	var crossword_data := _build_crossword_data(path)
	if crossword_data == null:
		return
	_pending_crossword_data = crossword_data
	if _save_file_dialog == null:
		_save_file_dialog = EditorFileDialog.new()
		_save_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		_save_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_save_file_dialog.add_filter("*.tres", "Ressource Godot")
		_save_file_dialog.file_selected.connect(_on_save_path_selected)
		EditorInterface.get_base_control().add_child(_save_file_dialog)
	_save_file_dialog.current_path = "res://data/%s.tres" % path.get_file().get_basename()
	_save_file_dialog.popup_centered_ratio(0.5)

func _build_crossword_data(csv_path: String) -> CrosswordData:
	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir le fichier CSV : %s" % csv_path)
		return null
	var clues: Array[WordData] = []
	var is_first_line := true
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() < 2:
			continue
		var word_text := line[0].strip_edges()
		if is_first_line:
			is_first_line = false
			if word_text.to_lower() in ["word", "mot"]:
				continue
		if word_text.is_empty():
			continue
		var word_data := WordData.new()
		word_data.word = word_text
		word_data.hint = line[1].strip_edges()
		clues.append(word_data)
	file.close()
	var crossword_data := CrosswordData.new()
	crossword_data.clues = clues
	return crossword_data

func _on_save_path_selected(path: String) -> void:
	var error := ResourceSaver.save(_pending_crossword_data, path)
	if error != OK:
		push_error("Erreur lors de la sauvegarde de la ressource (%d) : %s" % [error, path])
		return
	EditorInterface.get_resource_filesystem().scan()
