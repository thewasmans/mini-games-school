extends GdUnitTestSuite


func test_an_unknown_word_has_no_model() -> void:
	assert_object(ChemistryModels.build("INCONNU")).is_null()


func test_a_known_word_builds_a_model() -> void:
	var model := auto_free(ChemistryModels.build("MOLE")) as Node3D
	assert_object(model).is_not_null()
	assert_int(model.get_child_count()).is_greater(0)


func test_chandeliers_have_one_atom_per_element() -> void:
	var binary := auto_free(ChemistryModels.build("BINAIRE")) as Node3D
	var quaternary := auto_free(ChemistryModels.build("QUATERNAIRE")) as Node3D
	assert_int(quaternary.get_child_count() - binary.get_child_count()).is_equal(4)


func test_items_without_model_get_a_generic_shape() -> void:
	var item := TestData.housing_item("INCONNU")
	var model := auto_free(HouseModels.item(item)) as Node3D
	assert_int(model.get_child_count()).is_greater(0)
