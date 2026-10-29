class_name TestData
extends RefCounted

const SECONDARY := 1
const FOURTH_YEAR := 3


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


static func crossword(words: Array[String]) -> CrosswordData:
	var crossword_data := CrosswordData.new()
	for word in words:
		var entry := CrosswordEntry.new()
		entry.word = word
		entry.clue = "Indice de " + word
		crossword_data.entries.append(entry)
	return crossword_data
