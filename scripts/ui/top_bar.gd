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
	center.add_child(_stars_pill())

	var gear := JuicyButton.new("", UIStyle.BLUE)
	gear.icon_kind = "sound_off" if Sfx.muted else "gear"
	gear.custom_minimum_size = BUTTON_SIZE
	gear.tooltip_text = "Son"
	gear.pressed.connect(func() -> void:
		Sfx.muted = not Sfx.muted
		gear.icon_kind = "sound_off" if Sfx.muted else "gear"
		UIFeedback.float_text(gear, "Son coupé" if Sfx.muted else "Son activé", Color.WHITE, 26))
	add_child(gear)


## Pilule centrale : ⭐ levels terminés / levels disponibles.
func _stars_pill() -> PanelContainer:
	var progress := GameManager.total_progress()
	var pill := UIStyle.panel(&"PillStars")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	row.add_child(IconView.new("star", 50))
	var inner := UIStyle.panel(&"PillStarsInner")
	inner.add_child(UIStyle.label("%d / %d" % [progress.x, progress.y], 30, Color.WHITE, 8))
	row.add_child(inner)
	return pill
