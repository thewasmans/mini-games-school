extends Node
## Charge GameData et porte les réglages du helper de test (F1).

signal debug_changed

const GAME_DATA_PATH := "res://data/game_data.tres"

var data: GameData

var debug_auto_fill := false
var debug_auto_validate := false
var debug_show_hints := false


func initialize() -> void:
	data = load(GAME_DATA_PATH) as GameData
	if data == null:
		push_error("Impossible de charger %s" % GAME_DATA_PATH)
		data = GameData.new()
	GameState.reset()


func set_debug(auto_fill: bool, auto_validate: bool, show_hints: bool, unlock_all: bool) -> void:
	debug_auto_fill = auto_fill
	debug_auto_validate = auto_validate
	debug_show_hints = show_hints
	GameState.unlock_all = unlock_all
	debug_changed.emit()


## Levels terminés / levels disponibles, toutes années et matières confondues.
func study_progress(study: int) -> Vector2i:
	var done := 0
	for y in GameData.YEARS_PER_STUDY:
		var year := data.get_year(study, y)
		if year == null:
			continue
		for s in year.subjects.size():
			done += GameState.completed_count(GameState.make_key(study, y, s))
	return Vector2i(done, data.count_study_levels(study))


func subject_progress(study: int, year: int, subject: int) -> Vector2i:
	var s := data.get_subject(study, year, subject)
	var total := s.count_levels() if s != null else 0
	return Vector2i(GameState.completed_count(GameState.make_key(study, year, subject)), total)
