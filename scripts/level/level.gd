class_name LevelScreen
extends Control
## Écran d'un level : titre, barre de progression commune, mini-jeu, bouton Valider.

signal validated
signal exited

var _level: LevelData
var _title := ""
var _progress: JuicyProgressBar
var _validate: JuicyButton
var _game: MiniGameUI
var _done := false


func _init(level: LevelData, title: String) -> void:
	_level = level
	_title = title


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var bar := TopBar.new(true)
	bar.back_pressed.connect(func() -> void: exited.emit())
	root.add_child(bar)
	var banner := TitleBanner.create(_title, UIStyle.BLUE, 27)
	banner.size_flags_horizontal = SIZE_SHRINK_CENTER
	banner.custom_minimum_size = Vector2(560, 0)
	root.add_child(banner)

	_progress = JuicyProgressBar.new(UIStyle.GREEN, 34)
	_progress.stripes = true
	root.add_child(_progress)

	_game = MiniGameUI.create(_level.mini_game)
	if _game == null:
		root.add_child(UIStyle.label("Mini-jeu introuvable pour ce level.", 30))
	else:
		_game.progress_changed.connect(func(r: float) -> void: _progress.set_value(r))
		_game.completed.connect(_on_completed)
		root.add_child(_game)

	_validate = JuicyButton.new("VALIDER", Color("5fd35a"), 46)
	_validate.icon_left = "check"
	_validate.icon_right = "star"
	_validate.sparkles = true
	_validate.custom_minimum_size = Vector2(0, 110)
	_validate.sound = "pop"
	_validate.visible = false
	_validate.pressed.connect(_on_validate)
	root.add_child(_validate)


func _on_completed() -> void:
	_show_victory()
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	_validate.visible = true
	_validate.set_shine(true)
	UIFeedback.pop_in(_validate, 0.0, 0.3)
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		UIFeedback.breathe(_validate, 0.04, 1.0)
	if GameManager.debug_auto_validate:
		await get_tree().create_timer(0.6).timeout
		if is_inside_tree():
			_on_validate()


func _on_validate() -> void:
	if _done:
		return
	_done = true
	validated.emit()


## Bandeau « BRAVO ! » avec rayons tournants.
func _show_victory() -> void:
	var banner := VictoryBanner.new()
	add_child(banner)


class VictoryBanner extends Control:
	var _t := 0.0
	var _scale := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		var tw := create_tween()
		tw.tween_method(_set_scale, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.0)
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(queue_free)

	func _set_scale(v: float) -> void:
		_scale = v

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size / 2 + Vector2(0, -60)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.15, 0.45 * _scale))
		for i in 16:
			var a := _t * 0.8 + TAU * i / 16.0
			var r := 520.0 * _scale
			draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a), sin(a)) * r, c + Vector2(cos(a + 0.18), sin(a + 0.18)) * r]),
				Color(1, 0.9, 0.4, 0.18))
		draw_set_transform(c, sin(_t * 3.0) * 0.04, Vector2.ONE * _scale)
		var ribbon := UIStyle.box(UIStyle.RED, 18, 10, 4, Color("8a1020"))
		draw_style_box(ribbon, Rect2(-260, -70, 520, 140))
		UIStyle.draw_text(self, "BRAVO !", Vector2(0, -6), 84, UIStyle.YELLOW, 18)
		for k in 3:
			var sx := (k - 1) * 90.0
			var sy := -120.0 + absi(k - 1) * 20.0
			draw_colored_polygon(UIStyle.star(Vector2(sx, sy), 44 if k == 1 else 34, 18 if k == 1 else 14), Color("8a5a00"))
			draw_colored_polygon(UIStyle.star(Vector2(sx, sy - 4), 40 if k == 1 else 30, 16 if k == 1 else 12), UIStyle.YELLOW)
