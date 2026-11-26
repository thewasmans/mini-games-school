extends GdUnitTestSuite


func test_accents_are_removed_and_letters_uppercased() -> void:
	assert_str(TextUtil.normalize_char("é")).is_equal("E")
	assert_str(TextUtil.normalize_char("ç")).is_equal("C")
	assert_str(TextUtil.normalize_char("a")).is_equal("A")


func test_letters_and_digits_are_letters_but_not_punctuation() -> void:
	assert_bool(TextUtil.is_letter("à")).is_true()
	assert_bool(TextUtil.is_letter("7")).is_true()
	assert_bool(TextUtil.is_letter("'")).is_false()
	assert_bool(TextUtil.is_letter(" ")).is_false()


func test_answer_keeps_only_letters_and_expands_ligatures() -> void:
	assert_str(TextUtil.to_answer("Cœur d'œuf")).is_equal("COEURDOEUF")
	assert_str(TextUtil.to_answer("Pôle Nord")).is_equal("POLENORD")


func test_words_of_an_empty_text_are_empty() -> void:
	assert_int(TextUtil.words("").size()).is_equal(0)
	assert_int(TextUtil.words(" , !").size()).is_equal(0)


func test_words_keep_digits_and_ligatures_inside_a_word() -> void:
	assert_array(Array(TextUtil.words("H2O et nœud"))).contains_exactly(["H2O", "ET", "NOEUD"])


func test_word_spans_cover_the_last_word() -> void:
	assert_array(TextUtil.word_spans("ab cd")).contains_exactly([Vector2i(0, 2), Vector2i(3, 5)])
	assert_str(TextUtil.word_at("ab cd", 4)).is_equal("CD")
