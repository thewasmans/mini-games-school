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
