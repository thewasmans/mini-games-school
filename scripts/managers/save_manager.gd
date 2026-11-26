class_name SaveManager
extends Manager

const DEFAULT_SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2

static var save_path := DEFAULT_SAVE_PATH


func initialize(game_manager: GameManager) -> void:
	super.initialize(game_manager)
	load_game()
	game_state.progress_changed.connect(save_game)
	housing_state.changed.connect(save_game)


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		push_warning("Sauvegarde illisible, ignorée : %s" % save_path)
		return
	var save_data: Dictionary = data
	if int(save_data.get("version", 1)) < 2:
		game_state.load_save_data(save_data)
		return
	game_state.load_save_data(save_data.get("progress", {}))
	housing_state.load_save_data(save_data.get("housing", {}))


func save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'écrire la sauvegarde : %s" % save_path)
		return
	var data := {
		"version": SAVE_VERSION,
		"progress": game_state.to_save_data(),
		"housing": housing_state.to_save_data(),
	}
	file.store_string(JSON.stringify(data, "\t"))


static func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
