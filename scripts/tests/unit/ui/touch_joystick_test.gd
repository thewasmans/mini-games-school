extends GdUnitTestSuite


func _joystick() -> TouchJoystick:
	var joystick := auto_free(TouchJoystick.new()) as TouchJoystick
	joystick.size = Vector2(260, 260)
	add_child(joystick)
	return joystick


func test_pushing_to_the_edge_gives_a_full_direction() -> void:
	var joystick := _joystick()
	joystick._update_knob(joystick.size / 2 + Vector2(joystick.radius * 3, 0))
	assert_that(joystick.direction).is_equal(Vector2(1, 0))


func test_small_moves_stay_in_the_dead_zone() -> void:
	var joystick := _joystick()
	joystick._update_knob(joystick.size / 2 + Vector2(joystick.radius * joystick.dead_zone * 0.5, 0))
	assert_that(joystick.direction).is_equal(Vector2.ZERO)


func test_releasing_recenters_the_stick() -> void:
	var joystick := _joystick()
	joystick._update_knob(joystick.size / 2 + Vector2(0, -joystick.radius))
	monitor_signals(joystick, false)
	joystick.release()
	assert_that(joystick.direction).is_equal(Vector2.ZERO)
	@warning_ignore("redundant_await")
	await assert_signal(joystick).is_emitted("moved", Vector2.ZERO)
