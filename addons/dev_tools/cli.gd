extends SceneTree
## Générateurs en ligne de commande :
##   godot --headless --path . --script res://addons/dev_tools/cli.gd -- theme
##   godot --headless --path . --script res://addons/dev_tools/cli.gd -- fake_data


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var err := OK
	match args[0] if not args.is_empty() else "":
		"theme":
			err = ThemeBuilder.run()
		"fake_data":
			err = FakeDataBuilder.run()
		_:
			push_error("Usage : -- theme | fake_data")
			err = ERR_INVALID_PARAMETER
	quit(0 if err == OK else 1)
