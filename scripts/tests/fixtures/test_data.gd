class_name TestData
extends RefCounted

const SECONDARY := 1
const FOURTH_YEAR := 3
const SAVE_PATH := "user://test_save.json"


static func use_empty_save() -> void:
	SaveManager.save_path = SAVE_PATH
	SaveManager.delete_save()


static func memo(question_count: int) -> MemoData:
	var memo_data := MemoData.new()
	memo_data.theme_title = "Quiz de test"
	for question_index in question_count:
		var question := MemoQuestion.new()
		question.question = "Question %d ?" % (question_index + 1)
		question.answers = PackedStringArray(["Bonne", "Mauvaise 1", "Mauvaise 2", "Mauvaise 3"])
		question.correct_index = 0
		memo_data.questions.append(question)
	return memo_data


static func subject(subject_name: String, level_count: int) -> SubjectData:
	var subject_data := SubjectData.new()
	subject_data.name = subject_name
	for level_index in level_count:
		var level := LevelData.new()
		level.mini_game = memo(1)
		subject_data.levels.append(level)
	return subject_data


static func game_data(level_counts_per_subject: Array[int]) -> GameData:
	var school_year := SchoolYearData.new()
	school_year.name = "S4"
	for subject_index in level_counts_per_subject.size():
		school_year.subjects.append(subject("Matière %d" % subject_index, level_counts_per_subject[subject_index]))
	var data := GameData.new()
	data.secondary_4 = school_year
	return data


static func game_state(level_counts_per_subject: Array[int]) -> GameState:
	var state := GameState.new(game_data(level_counts_per_subject))
	state.select_study_level(SECONDARY)
	state.select_school_year(FOURTH_YEAR)
	state.select_subject(0)
	return state


static func game_state_with_islands(level_count: int, bonus_island_interval: int) -> GameState:
	var state := game_state([level_count])
	state._current_subject_data().bonus_island_interval = bonus_island_interval
	return state


static func crypto(sentences: Array[String], hidden_ratio := 0.3) -> CryptoData:
	var crypto_data := CryptoData.new()
	crypto_data.theme_title = "Crypto de test"
	crypto_data.hidden_ratio = hidden_ratio
	for text in sentences:
		var sentence := CryptoSentence.new()
		sentence.sentence = text
		crypto_data.sentences.append(sentence)
	return crypto_data


static func crossword(words: Array[String]) -> CrosswordData:
	var crossword_data := CrosswordData.new()
	for word in words:
		var entry := CrosswordEntry.new()
		entry.word = word
		entry.clue = "Indice de " + word
		crossword_data.entries.append(entry)
	return crossword_data


static func memo_about(words: Array[String]) -> MemoData:
	var memo_data := memo(words.size())
	for index in words.size():
		memo_data.questions[index].question = "Que veut dire %s ?" % words[index]
	return memo_data


static func housing_item(word: String, footprint := Vector2i.ONE, slot := HousingItemData.Slot.FLOOR) -> HousingItemData:
	var item := HousingItemData.new()
	item.word = word
	item.title = word.capitalize()
	item.footprint = footprint
	item.slot = slot
	return item


static func housing_state(level_words: Array, items: Array[HousingItemData], grid_size := Vector2i(4, 4)) -> HousingState:
	var data := game_data([level_words.size()])
	var subject := data.secondary_4.subjects[0]
	for level_index in level_words.size():
		var words: Array[String] = []
		words.assign(level_words[level_index])
		subject.levels[level_index].mini_game = memo_about(words)
	var room := HousingRoomData.new()
	room.items = items
	room.grid_size = grid_size
	subject.housing_room = room
	return HousingState.new(HousingCatalog.new(data))


static func housing_subject_key() -> Vector3i:
	return Vector3i(SECONDARY, FOURTH_YEAR, 0)
