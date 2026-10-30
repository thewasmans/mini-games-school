extends GdUnitTestSuite

const GAME_DATA_PATH := "res://data/game_data.tres"
const MINI_GAME_PREFABS_PATH := "res://content/prefabs/ui/mini_games/mini_game_prefabs.tres"

var _game_data: GameData


func before() -> void:
	_game_data = load(GAME_DATA_PATH)


func _levels_by_location() -> Dictionary[String, LevelData]:
	var levels: Dictionary[String, LevelData] = {}
	for study_level in GameData.STUDY_NAMES.size():
		for school_year in GameData.YEARS_PER_STUDY:
			var year := _game_data.get_year(study_level, school_year)
			if year == null:
				continue
			for subject in year.subjects:
				for level_index in subject.levels.size():
					levels["%s %s level %d" % [year.name, subject.name, level_index + 1]] = subject.levels[level_index]
	return levels


func _subjects() -> Array[SubjectData]:
	var subjects: Array[SubjectData] = []
	for study_level in GameData.STUDY_NAMES.size():
		for school_year in GameData.YEARS_PER_STUDY:
			var year := _game_data.get_year(study_level, school_year)
			if year != null:
				subjects.append_array(year.subjects)
	return subjects


func _item_count(mini_game: MiniGameData) -> int:
	if mini_game is CryptoData:
		return mini_game.sentences.size()
	if mini_game is MemoData:
		return mini_game.questions.size()
	return (mini_game as CrosswordData).entries.size()


func _mini_games() -> Array[MiniGameData]:
	var mini_games: Array[MiniGameData] = []
	for level in _levels_by_location().values():
		if level != null and level.mini_game != null:
			mini_games.append(level.mini_game)
	return mini_games


func test_game_data_contains_levels() -> void:
	assert_array(_mini_games()).is_not_empty()


func test_every_level_has_a_mini_game() -> void:
	var empty_levels: Array[String] = []
	var levels := _levels_by_location()
	for location in levels:
		if levels[location] == null or levels[location].mini_game == null:
			empty_levels.append(location)
	assert_array(empty_levels).is_empty()


func test_every_mini_game_type_has_a_prefab() -> void:
	var prefabs: MiniGamePrefabs = load(MINI_GAME_PREFABS_PATH)
	var missing: Array[String] = []
	for mini_game in _mini_games():
		if prefabs.prefab_for(mini_game) == null:
			missing.append(mini_game.resource_path)
	assert_array(missing).is_empty()


func test_crossword_grids_are_generated_without_conflicts() -> void:
	var broken: Array[String] = []
	for mini_game in _mini_games():
		if mini_game is CrosswordData and (not mini_game.is_generated() or not CrosswordGenerator.analyze(mini_game).conflicts.is_empty()):
			broken.append(mini_game.resource_path)
	assert_array(broken).is_empty()


func test_quiz_questions_have_a_valid_answer() -> void:
	var broken: Array[String] = []
	for mini_game in _mini_games():
		if mini_game is MemoData:
			for question in mini_game.questions:
				if question.correct_index < 0 or question.correct_index >= question.answers.size():
					broken.append("%s : %s" % [mini_game.resource_path, question.question])
	assert_array(broken).is_empty()


func test_cryptogram_sentences_are_not_empty() -> void:
	var broken: Array[String] = []
	for mini_game in _mini_games():
		if mini_game is CryptoData and (mini_game.sentences.is_empty() or mini_game.sentences.any(func(sentence: CryptoSentence) -> bool: return sentence.sentence.strip_edges().is_empty())):
			broken.append(mini_game.resource_path)
	assert_array(broken).is_empty()


func test_every_subject_starts_with_a_cryptogram() -> void:
	var broken: Array[String] = []
	for subject in _subjects():
		if not subject.levels.is_empty() and not subject.levels[0].mini_game is CryptoData:
			broken.append(subject.name)
	assert_array(broken).is_empty()


func test_first_levels_are_short() -> void:
	var broken: Array[String] = []
	for subject in _subjects():
		for level_index in mini(3, subject.levels.size()):
			if _item_count(subject.levels[level_index].mini_game) > 4:
				broken.append("%s level %d" % [subject.name, level_index + 1])
	assert_array(broken).is_empty()


func test_mini_game_types_alternate() -> void:
	var broken: Array[String] = []
	for subject in _subjects():
		for level_index in range(2, subject.levels.size()):
			var kinds := [level_index - 2, level_index - 1, level_index].map(func(index: int) -> String: return subject.levels[index].mini_game.get_kind_id())
			if kinds[0] == kinds[1] and kinds[1] == kinds[2]:
				broken.append("%s levels %d à %d" % [subject.name, level_index - 1, level_index + 1])
	assert_array(broken).is_empty()


func test_every_subject_has_a_map_theme() -> void:
	var missing: Array[String] = []
	for subject in _subjects():
		if subject.map_theme == null:
			missing.append(subject.name)
	assert_array(missing).is_empty()
