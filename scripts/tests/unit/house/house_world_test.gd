extends GdUnitTestSuite

var _key := TestData.housing_subject_key()


func _world(items: Array[HousingItemData], open := true) -> HouseWorld:
	var words: Array[String] = []
	for item in items:
		words.append(item.word)
	var state := TestData.housing_state([words], items, Vector2i(4, 4))
	var word_points: Dictionary[String, int] = {}
	for word in words:
		word_points[word] = 10
	state.record_encounters(_key, 0, word_points)
	state.action_points = 10
	var world := auto_free(HouseWorld.new()) as HouseWorld
	var open_keys: Array[Vector3i] = []
	if open:
		open_keys.append(_key)
	world.build(state, open_keys)
	return world


func _origin(world: HouseWorld) -> Vector3:
	return world.room_of(_key).origin


func test_the_hall_comes_first_then_one_room_per_subject() -> void:
	var world := _world([TestData.housing_item("MOLE")])
	assert_int(world.rooms.size()).is_equal(2)
	assert_that(world.rooms[0].key).is_equal(HouseWorld.HALL_KEY)
	assert_that(world.rooms[1].key).is_equal(_key)
	assert_bool(world.rooms[0].open).is_true()
	assert_bool(world.rooms[1].open).is_true()


func test_a_room_is_closed_until_its_subject_is_open() -> void:
	var world := _world([TestData.housing_item("MOLE")], false)
	assert_bool(world.room_of(_key).open).is_false()


func test_a_position_belongs_to_the_room_around_it() -> void:
	var world := _world([TestData.housing_item("MOLE")])
	assert_that(world.room_at(Vector3(1, 0, 1)).key).is_equal(HouseWorld.HALL_KEY)
	assert_that(world.room_at(_origin(world) + Vector3(1, 0, 1)).key).is_equal(_key)
	assert_bool(world.room_at(Vector3(-5, 0, 1)).is_empty()).is_true()


func test_the_kid_spawns_inside_the_requested_room() -> void:
	var world := _world([TestData.housing_item("MOLE")])
	assert_that(world.room_at(world.spawn_position(_key)).key).is_equal(_key)
	assert_that(world.room_at(world.spawn_position(Vector3i(9, 9, 9))).key).is_equal(HouseWorld.HALL_KEY)


func test_the_target_cell_is_centered_on_the_footprint() -> void:
	var small := TestData.housing_item("MOLE")
	var big := TestData.housing_item("AQUEUSE", Vector2i(2, 2))
	var world := _world([small, big])
	var room := world.room_of(_key)
	assert_that(world.target_cell(room, small, _origin(world) + Vector3(1.5, 0, 2.5))).is_equal(Vector2i(1, 2))
	assert_that(world.target_cell(room, big, _origin(world) + Vector3(2.0, 0, 3.0))).is_equal(Vector2i(1, 2))


func test_wall_items_target_the_back_wall_only_when_close() -> void:
	var portrait := TestData.housing_item("AVOGADRO", Vector2i.ONE, HousingItemData.Slot.WALL)
	var world := _world([portrait])
	var room := world.room_of(_key)
	assert_that(world.target_cell(room, portrait, _origin(world) + Vector3(2.5, 0, 1.0))).is_equal(Vector2i(2, 0))
	assert_bool(world.target_cell(room, portrait, _origin(world) + Vector3(2.5, 0, 3.5)).x < 0).is_true()


func test_item_positions_depend_on_the_slot() -> void:
	var table := TestData.housing_item("AQUEUSE", Vector2i(2, 2))
	var portrait := TestData.housing_item("AVOGADRO", Vector2i.ONE, HousingItemData.Slot.WALL)
	var chandelier := TestData.housing_item("TERNAIRE", Vector2i.ONE, HousingItemData.Slot.CEILING)
	var world := _world([table, portrait, chandelier])
	var room := world.room_of(_key)
	assert_that(world.item_position(room, table, Vector2i(1, 1))).is_equal(_origin(world) + Vector3(2, 0, 2))
	assert_float(world.item_position(room, portrait, Vector2i(1, 0)).y).is_equal(HouseWorld.WALL_BASE)
	assert_float(world.item_position(room, chandelier, Vector2i(1, 1)).y).is_equal(HouseWorld.CEILING_HEIGHT)


func test_a_placed_item_is_found_in_front_of_the_kid() -> void:
	var table := TestData.housing_item("AQUEUSE", Vector2i(2, 1))
	var world := _world([table])
	var state: HousingState = world._housing_state
	state.place_item(_key, table, Vector2i(1, 1))
	world.refresh_room(_key)
	var room := world.room_of(_key)
	assert_object(world.item_at(room, _origin(world) + Vector3(2.5, 0, 1.5))).is_same(table)
	assert_object(world.item_at(room, _origin(world) + Vector3(0.5, 0, 0.5))).is_null()
	assert_object(world.item_at(world.room_of(HouseWorld.HALL_KEY), Vector3(1, 0, 1))).is_null()


func test_a_damaged_zone_is_found_until_renovated() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var words: Array[String] = ["DENSITE"]
	var state := TestData.housing_state([words], [lamp], Vector2i(4, 4))
	var renovation := HousingRenovationData.new()
	renovation.cells = [Vector2i(0, 0)] as Array[Vector2i]
	renovation.cost = 2
	state.catalog.room(_key).renovations.append(renovation)
	state.action_points = 5
	var world := auto_free(HouseWorld.new()) as HouseWorld
	world.build(state, [_key] as Array[Vector3i])
	var room := world.room_of(_key)
	assert_int(world.renovation_at(room, _origin(world) + Vector3(0.5, 0, 0.5))).is_equal(0)
	assert_int(world.renovation_at(room, _origin(world) + Vector3(2.5, 0, 2.5))).is_equal(-1)
	state.renovate(_key, 0)
	assert_int(world.renovation_at(room, _origin(world) + Vector3(0.5, 0, 0.5))).is_equal(-1)
