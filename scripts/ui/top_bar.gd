class_name TopBar
extends HBoxContainer
## Barre du haut commune : bouton retour (optionnel), compteur d'étoiles (levels terminés),
## bouton réglages (coupe / remet le son).

signal back_pressed

const BUTTON_SIZE := Vector2(80, 80)


func _init(show_back := true) -> void:
	add_theme_constant_override("separation", 14)
	if show_back:
		var back := JuicyButton.new("", UIStyle.BLUE)
		back.icon_kind = "back"
		back.custom_minimum_size = BUTTON_SIZE
		back.pressed.connect(func() -> void: back_pressed.emit())
		add_child(back)
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = BUTTON_SIZE
		add_child(spacer)

	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(center)
	center.add_child(StarsPill.create(GameManager.total_progress()))

	var gear := JuicyButton.new("", UIStyle.BLUE)
	gear.icon_kind = "sound_off" if Sfx.muted else "gear"
	gear.custom_minimum_size = BUTTON_SIZE
	gear.tooltip_text = "Son"
	gear.pressed.connect(func() -> void:
		Sfx.muted = not Sfx.muted
		gear.icon_kind = "sound_off" if Sfx.muted else "gear"
		UIFeedback.float_text(gear, "Son coupé" if Sfx.muted else "Son activé", Color.WHITE, 26))
	add_child(gear)
