extends GdUnitTestSuite


func test_every_word_is_placed() -> void:
	var crossword := TestData.crossword(["NOYAU", "CELLULE", "MEMBRANE", "ORGANITE"])
	CrosswordGenerator.generate(crossword)
	assert_int(crossword.get_placed_entries().size()).is_equal(4)
	assert_bool(crossword.is_generated()).is_true()


func test_crossing_words_share_the_same_letter() -> void:
	var crossword := TestData.crossword(["NOYAU", "CELLULE", "MEMBRANE", "ORGANITE", "VACUOLE"])
	CrosswordGenerator.generate(crossword)
	assert_array(CrosswordGenerator.analyze(crossword).conflicts).is_empty()


func test_answers_are_normalized_without_accents_or_spaces() -> void:
	var crossword := TestData.crossword(["Éléphant", "Pôle nord"])
	CrosswordGenerator.generate(crossword)
	var answers: Array[String] = []
	for entry in crossword.entries:
		answers.append(entry.answer)
	assert_array(answers).contains_exactly_in_any_order(["ELEPHANT", "POLENORD"])


func test_words_are_numbered_from_one() -> void:
	var crossword := TestData.crossword(["NOYAU", "CELLULE", "MEMBRANE"])
	CrosswordGenerator.generate(crossword)
	var numbers: Array[int] = []
	for entry in crossword.get_placed_entries():
		numbers.append(entry.number)
	assert_array(numbers).contains([1])
	assert_bool(numbers.all(func(number: int) -> bool: return number >= 1)).is_true()
