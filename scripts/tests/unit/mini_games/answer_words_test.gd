extends GdUnitTestSuite


func test_words_are_split_on_punctuation_and_normalized() -> void:
	assert_array(Array(TextUtil.words("L'eau aqueuse, stœchiométrie !"))).contains_exactly(["L", "EAU", "AQUEUSE", "STOECHIOMETRIE"])


func test_word_at_finds_the_word_around_a_letter() -> void:
	var text := "La mole est une unité"
	assert_str(TextUtil.word_at(text, 4)).is_equal("MOLE")
	assert_str(TextUtil.word_at(text, 2)).is_equal("")


func test_crossword_entry_gives_its_words_and_the_whole_answer() -> void:
	var entry := CrosswordEntry.new()
	entry.word = "nombre d'Avogadro"
	assert_array(Array(entry.answer_words())).contains(["AVOGADRO", "NOMBREDAVOGADRO"])


func test_memo_question_gives_the_question_and_the_correct_answer() -> void:
	var memo := TestData.memo_about(["la dilution"])
	memo.questions[0].answers = PackedStringArray(["Ajout de solvant", "Faux", "Faux", "Faux"])
	var words := Array(memo.answer_words())
	assert_array(words).contains(["DILUTION", "SOLVANT"])
	assert_array(words).not_contains(["FAUX"])


func test_crypto_data_gives_the_words_of_every_sentence() -> void:
	var crypto := TestData.crypto(["La mole", "Une densité"])
	assert_array(Array(crypto.answer_words())).contains(["MOLE", "DENSITE"])


func test_a_single_word_entry_is_not_listed_twice() -> void:
	var entry := CrosswordEntry.new()
	entry.word = "Mole"
	assert_array(Array(entry.answer_words())).contains_exactly(["MOLE"])


func test_memo_ignores_a_missing_correct_answer() -> void:
	var question := MemoQuestion.new()
	question.question = "La mole"
	question.answers = PackedStringArray(["Unité"])
	question.correct_index = 3
	assert_array(Array(question.answer_words())).contains_exactly(["LA", "MOLE"])


func test_crossword_data_gives_the_words_of_every_entry() -> void:
	var crossword := TestData.crossword(["mole", "densité"])
	assert_array(Array(crossword.answer_words())).contains_exactly(["MOLE", "DENSITE"])


func test_a_mini_game_without_answers_has_no_words() -> void:
	assert_int(MiniGameData.new().answer_words().size()).is_equal(0)
