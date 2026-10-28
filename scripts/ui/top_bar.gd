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
		back.radius = 20.0
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
	gear.radius = 20.0
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
	var pill := PanelContainer.new()
	var sb := UIStyle.box(Color("1f3a8f"), 30, 0, 3, Color("6fa8ff"))
	sb.shadow_color = Color(0.02, 0.05, 0.2, 0.4)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	row.add_child(IconView.new("star", 50))
	var inner := PanelContainer.new()
	var isb := UIStyle.box(Color("13235e"), 20)
	isb.content_margin_left = 18
	isb.content_margin_right = 18
	isb.content_margin_top = 2
	isb.content_margin_bottom = 4
	inner.add_theme_stylebox_override("panel", isb)
	inner.add_child(UIStyle.label("%d / %d" % [progress.x, progress.y], 30, Color.WHITE, 8))
	row.add_child(inner)
	return pill
