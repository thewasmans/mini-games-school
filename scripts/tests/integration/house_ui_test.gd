extends GdUnitTestSuite

const INVENTORY_ROW := "res://content/prefabs/ui/house/inventory_row.tscn"
const ITEM_SIGN := "res://content/prefabs/ui/house/item_sign.tscn"


func _row() -> InventoryRow:
	var row := auto_free(load(INVENTORY_ROW).instantiate()) as InventoryRow
	add_child(row)
	return row


func test_a_locked_item_is_a_mystery_with_its_levels() -> void:
	var row := _row()
	row.initialize(TestData.housing_item("MOLE"), Vector2i(10, 30), false, false, [0, 7] as Array[int])
	assert_str(row.title_label.text).is_equal("???")
	assert_str(row.status_label.text).contains("1, 8")
	assert_str(row.value_label.text).is_equal("10 / 30")
	assert_str(row.action_button.text).is_equal("JOUER")
	assert_bool(row.action_button.visible).is_true()


func test_an_unlocked_item_can_be_taken() -> void:
	var row := _row()
	var item := TestData.housing_item("MOLE")
	row.initialize(item, Vector2i(10, 10), true, false, [0] as Array[int])
	assert_str(row.title_label.text).is_equal(item.title)
	assert_str(row.action_button.text).is_equal("PRENDRE")
	monitor_signals(row, false)
	row.action_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(row).is_emitted("take_pressed", item)


func test_a_locked_item_asks_to_play() -> void:
	var row := _row()
	var item := TestData.housing_item("MOLE")
	row.initialize(item, Vector2i(0, 10), false, false, [2] as Array[int])
	monitor_signals(row, false)
	row.action_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(row).is_emitted("play_pressed", item)


func test_a_placed_item_has_no_action() -> void:
	var row := _row()
	row.initialize(TestData.housing_item("MOLE"), Vector2i(10, 10), true, true, [0] as Array[int])
	assert_bool(row.action_button.visible).is_false()


func test_an_item_absent_from_the_levels_cannot_be_played() -> void:
	var row := _row()
	row.initialize(TestData.housing_item("MOLE"), Vector2i(0, 0), false, false, [] as Array[int])
	assert_bool(row.action_button.visible).is_false()


func test_the_sign_hides_empty_texts() -> void:
	var item_sign := auto_free(load(ITEM_SIGN).instantiate()) as ItemSign
	add_child(item_sign)
	var item := TestData.housing_item("MOLE")
	item.description = "Unité de quantité de matière."
	item_sign.show_item(item)
	assert_bool(item_sign.visible).is_true()
	assert_str(item_sign.description_label.text).is_equal(item.description)
	assert_bool(item_sign.mnemonic_label.visible).is_false()
	monitor_signals(item_sign, false)
	item_sign.replay_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(item_sign).is_emitted("replay_requested", item)
