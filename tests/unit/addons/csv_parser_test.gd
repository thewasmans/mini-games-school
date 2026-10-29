extends GdUnitTestSuite

const CSV_PATH := "user://gdunit_parser_test.csv"


func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CSV_PATH))


func _parse(content: String) -> Dictionary:
	var file := FileAccess.open(CSV_PATH, FileAccess.WRITE)
	file.store_string(content)
	file.close()
	return CsvMiniGameParser.parse(CSV_PATH)


func test_crossword_header_gives_crossword_data() -> void:
	var result := _parse("mot;définition\nNoyau;Centre de la cellule\nVacuole;Réserve d'eau\n")
	assert_bool(result.ok).is_true()
	assert_object(result.resource).is_instanceof(CrosswordData)
	assert_int((result.resource as CrosswordData).entries.size()).is_equal(2)


func test_quiz_header_gives_memo_data_with_the_right_answer() -> void:
	var result := _parse("question;réponse 1;réponse 2;réponse 3;réponse 4;bonne réponse\nRéserve d'eau ?;Noyau;Membrane;Vacuole;Paroi;Vacuole\n")
	assert_bool(result.ok).is_true()
	var memo := result.resource as MemoData
	assert_object(memo).is_not_null()
	assert_int(memo.questions[0].correct_index).is_equal(2)


func test_sentence_header_gives_crypto_data() -> void:
	var result := _parse("phrase;indice\nLa cellule est vivante.;Unité du vivant\n")
	assert_bool(result.ok).is_true()
	assert_object(result.resource).is_instanceof(CryptoData)


func test_title_comes_from_the_file_name() -> void:
	var result := _parse("mot;définition\nNoyau;Centre\n")
	assert_str((result.resource as MiniGameData).theme_title).is_equal("Gdunit parser test")


func test_empty_file_is_an_error() -> void:
	var result := _parse("\n\n")
	assert_bool(result.ok).is_false()
	assert_str(result.error).is_not_empty()
