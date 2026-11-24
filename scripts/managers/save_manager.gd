class_name SaveManager
extends Manager

const SAVE_PATH := "user://progress.json"
const SAVE_VERSION := 1
const VERSION_KEY := "version"
const SUBJECTS_KEY := "subjects"

func initialize(game_manager: GameManager) -> void:
	super.initialize(game_manager)
	game_state.load_save_data(_read_saved_subjects())
	game_state.progress_changed.connect(_write_save)

func _read_saved_subjects() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or int(parsed.get(VERSION_KEY, 0)) != SAVE_VERSION:
		push_warning("Sauvegarde illisible ou d'une autre version, progression remise à zéro : %s" % SAVE_PATH)
		return {}
	var subjects: Variant = parsed.get(SUBJECTS_KEY, {})
	return subjects if subjects is Dictionary else {}

func _write_save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'enregistrer la progression (%s) : %s" % [error_string(FileAccess.get_open_error()), SAVE_PATH])
		return
	file.store_string(JSON.stringify({VERSION_KEY: SAVE_VERSION, SUBJECTS_KEY: game_state.save_data()}))
	file.close()
