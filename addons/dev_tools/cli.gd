extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var err := OK
	match args[0] if not args.is_empty() else "":
		"theme":
			err = ThemeBuilder.run()
		_:
			push_error("Usage : -- theme")
			err = ERR_INVALID_PARAMETER
	quit(0 if err == OK else 1)
