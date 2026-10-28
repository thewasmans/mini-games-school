class_name GameUI
extends Control
## Menus et navigation :
## Menu principal -> Niveau d'études -> Année -> Matière -> Grille des levels -> Level.
## Chaque écran est reconstruit à l'affichage, pour que jauges et cadenas soient à jour.

const GAME_TITLE := "RÉVISIONS"
const GAME_SUBTITLE := "Mots croisés • Quiz • Cryptogrammes"
const STUDY_BACKGROUNDS: Array[Array] = [
	[Color("3a7bea"), Color("142a7a")],
	[Color("1fa38a"), Color("0b3360")],
	[Color("8a4fe0"), Color("2a1470")],
]

var _bg: AnimatedBackground
var _holder: Control
var _current: Control
var _nav: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = UIStyle.theme()
	_bg = AnimatedBackground.new()
	add_child(_bg)
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_holder.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_holder)
	if OS.has_feature("editor"):
		add_child(DebugHelper.new())
	go_to({"screen": "main"})


func go_to(entry: Dictionary) -> void:
	_nav.append(entry)
	_show(entry, true)


func go_back() -> void:
	if _nav.size() <= 1:
		return
	_nav.pop_back()
	_show(_nav.back(), false)


func _data() -> GameData:
	return GameManager.data


func _show(entry: Dictionary, forward: bool) -> void:
	var screen: Control
	var study: int = entry.get("study", -1)
	if study >= 0:
		_bg.set_colors(STUDY_BACKGROUNDS[study][0], STUDY_BACKGROUNDS[study][1])
	else:
		_bg.set_colors(Color("2f6fe0"), Color("12206a"))
	match entry.screen:
		"main":
			screen = _build_main_menu()
		"credits":
			screen = _build_credits()
		"study":
			screen = _build_study_menu()
		"year":
			screen = _build_year_menu(study)
		"subject":
			screen = _build_subject_menu(study, entry.year)
		"grid":
			screen = _build_level_grid(study, entry.year, entry.subject)
		"level":
			screen = _build_level(study, entry.year, entry.subject, entry.index)
	_swap(screen, forward)


func _swap(screen: Control, forward: bool) -> void:
	var dir := 1.0 if forward else -1.0
	var old := _current
	_current = screen
	_holder.add_child(screen)
	screen.modulate.a = 0.0
	screen.position.x = 90.0 * dir
	var tw := screen.create_tween().set_parallel()
	tw.tween_property(screen, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(screen, "modulate:a", 1.0, 0.25)
	if old != null:
		UIFeedback.disable_input(old)
		var out := old.create_tween().set_parallel()
		out.tween_property(old, "position:x", -90.0 * dir, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		out.tween_property(old, "modulate:a", 0.0, 0.2)
		out.chain().tween_callback(old.queue_free)
		Sfx.play("whoosh")


# --- Briques communes ------------------------------------------------------

## Écran standard : bouton retour + bannière de titre, puis un corps vertical.
func _screen(title: String, back := true, color := UIStyle.BLUE) -> Array[Control]:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	root.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	margin.add_child(col)
	if back or title != "":
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 14)
		col.add_child(header)
		if back:
			var b := JuicyButton.new("", UIStyle.BLUE)
			b.icon_kind = "back"
			b.custom_minimum_size = Vector2(84, 84)
			b.size_flags_vertical = SIZE_SHRINK_CENTER
			b.pressed.connect(go_back)
			header.add_child(b)
		var banner := UIStyle.banner(title, color, 38)
		banner.size_flags_horizontal = SIZE_EXPAND_FILL
		header.add_child(banner)
		if back:
			# Contrepoids pour garder le titre centré
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(84, 0)
			header.add_child(spacer)
		UIFeedback.pop_in(banner, 0.05, 0.7)
	var body := VBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	col.add_child(body)
	return [root, body]


func _gauge(progress: Vector2i, color: Color, height := 30.0) -> JuicyProgressBar:
	var g := JuicyProgressBar.new(color, height)
	g.text = "%d / %d levels" % [progress.x, progress.y]
	g.set_value(0.0, false)
	var target := progress.x / float(maxi(progress.y, 1))
	g.ready.connect(func() -> void:
		await get_tree().create_timer(0.35).timeout
		if is_instance_valid(g):
			g.set_value(target))
	return g


func _soon_label() -> Label:
	var l := UIStyle.label("Bientôt disponible", 24, Color("c8d2ff"), 7)
	return l


## Bouton de menu + jauge (ou « Bientôt disponible » s'il n'y a aucun level).
func _menu_entry(text: String, color: Color, progress: Vector2i, on_press: Callable, height := 120.0, font_size := 44) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	var b := JuicyButton.new(text, color, font_size)
	b.custom_minimum_size = Vector2(0, height)
	box.add_child(b)
	if progress.y == 0:
		b.disabled = true
		b.color = UIStyle.GREY
		b.mouse_default_cursor_shape = CURSOR_FORBIDDEN
		box.add_child(_soon_label())
	else:
		b.pressed.connect(on_press)
		box.add_child(_gauge(progress, color.lightened(0.15)))
	return box


func _valid_levels(subject: SubjectData) -> Array[LevelData]:
	var out: Array[LevelData] = []
	if subject != null:
		for level in subject.levels:
			if level != null and level.mini_game != null:
				out.append(level)
	return out


# --- Menu principal --------------------------------------------------------

func _build_main_menu() -> Control:
	var parts := _screen("", false)
	var body: VBoxContainer = parts[1]
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 26)

	var logo := VBoxContainer.new()
	logo.add_theme_constant_override("separation", 6)
	body.add_child(logo)
	var title := UIStyle.label(GAME_TITLE, 104, UIStyle.YELLOW, 22)
	title.add_theme_constant_override("shadow_offset_y", 8)
	logo.add_child(title)
	var sub := UIStyle.pill(GAME_SUBTITLE, UIStyle.PANEL_DARK, 26)
	sub.size_flags_horizontal = SIZE_SHRINK_CENTER
	logo.add_child(sub)
	UIFeedback.pop_in(logo, 0.1, 0.3)
	title.ready.connect(func() -> void:
		await get_tree().create_timer(0.7).timeout
		if is_instance_valid(title):
			var tw := title.create_tween().set_loops()
			tw.tween_property(title, "rotation", 0.03, 1.4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(title, "rotation", -0.03, 1.4).set_trans(Tween.TRANS_SINE))

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 26)
	cards.custom_minimum_size = Vector2(0, 230)
	body.add_child(cards)
	var card_defs := [["AB", "Mots croisés", UIStyle.GOLD], ["?", "Quiz", UIStyle.PURPLE], ["A_C", "Crypto", UIStyle.GREEN]]
	for i in card_defs.size():
		var card := _game_card(card_defs[i][0], card_defs[i][1], card_defs[i][2], (i - 1) * 0.12)
		cards.add_child(card)
		UIFeedback.pop_in(card, 0.25 + i * 0.1, 0.2)

	var play := JuicyButton.new("PLAY", UIStyle.ORANGE, 70)
	play.custom_minimum_size = Vector2(420, 150)
	play.size_flags_horizontal = SIZE_SHRINK_CENTER
	play.sound = "pop"
	play.set_shine(true)
	play.pressed.connect(func() -> void: go_to({"screen": "study"}))
	body.add_child(play)
	UIFeedback.pop_in(play, 0.5, 0.3)
	play.ready.connect(func() -> void:
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(play):
			UIFeedback.breathe(play, 0.05, 1.2))

	var credits := JuicyButton.new("CRÉDITS", UIStyle.BLUE, 34)
	credits.custom_minimum_size = Vector2(300, 90)
	credits.size_flags_horizontal = SIZE_SHRINK_CENTER
	credits.pressed.connect(func() -> void: go_to({"screen": "credits"}))
	body.add_child(credits)
	UIFeedback.pop_in(credits, 0.6, 0.5)
	return parts[0]


func _game_card(glyph: String, caption: String, color: Color, tilt: float) -> Control:
	var card := PanelContainer.new()
	var sb := UIStyle.box(color, 24, 10, 4, color.darkened(0.45))
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 8)
	sb.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(170, 200)
	card.rotation = tilt
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	var g := UIStyle.label(glyph, 72, Color.WHITE, 14)
	g.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(g)
	box.add_child(UIStyle.label(caption, 24, Color.WHITE, 7))
	card.ready.connect(func() -> void:
		card.pivot_offset = card.size / 2
		var tw := card.create_tween().set_loops()
		tw.tween_property(card, "rotation", tilt + 0.06, 1.3 + absf(tilt)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(card, "rotation", tilt - 0.06, 1.3 + absf(tilt)).set_trans(Tween.TRANS_SINE))
	return card


# --- Crédits ---------------------------------------------------------------

func _build_credits() -> Control:
	var parts := _screen("CRÉDITS")
	var body: VBoxContainer = parts[1]
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)

	var credits := _data().credits
	if credits == null:
		list.add_child(UIStyle.label("Aucun crédit renseigné.", 30))
		return parts[0]

	var contributors := PanelContainer.new()
	list.add_child(contributors)
	var cbox := VBoxContainer.new()
	cbox.add_theme_constant_override("separation", 10)
	contributors.add_child(cbox)
	cbox.add_child(UIStyle.label("Contributeurs", 36, UIStyle.YELLOW, 10))
	for i in credits.contributors.size():
		var l := UIStyle.label(credits.contributors[i], 26)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cbox.add_child(l)
		UIFeedback.pop_in(l, 0.15 + i * 0.07, 0.5)

	list.add_child(UIStyle.label("Partenaires", 36, UIStyle.YELLOW, 10))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	list.add_child(grid)
	for i in credits.partner_names.size():
		var tile := PanelContainer.new()
		var sb := UIStyle.box(Color.WHITE, 22, 8, 3, Color("aab4d9"))
		sb.set_content_margin_all(14)
		tile.add_theme_stylebox_override("panel", sb)
		tile.custom_minimum_size = Vector2(0, 170)
		tile.size_flags_horizontal = SIZE_EXPAND_FILL
		var logo: Texture2D = credits.partner_logos[i] if i < credits.partner_logos.size() else null
		if logo != null:
			var tr := TextureRect.new()
			tr.texture = logo
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tile.add_child(tr)
		else:
			var l := UIStyle.label(credits.partner_names[i], 28, UIStyle.INK, 0)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tile.add_child(l)
		tile.tooltip_text = credits.partner_names[i]
		grid.add_child(tile)
		UIFeedback.pop_in(tile, 0.3 + i * 0.08, 0.4)
	return parts[0]


# --- Niveau d'études -------------------------------------------------------

func _build_study_menu() -> Control:
	var parts := _screen("MENU JOUER")
	var body: VBoxContainer = parts[1]
	body.add_theme_constant_override("separation", 26)
	var ask := UIStyle.banner("Choisis ton niveau d'études !", UIStyle.PANEL_DARK, 34)
	(ask.get_child(0) as Label).add_theme_color_override("font_color", UIStyle.YELLOW)
	body.add_child(ask)
	UIFeedback.pop_in(ask, 0.1, 0.6)
	for s in GameData.STUDY_NAMES.size():
		var entry := _menu_entry(GameData.STUDY_NAMES[s], UIStyle.STUDY_COLORS[s], GameManager.study_progress(s),
			_open_study.bind(s), 140.0, 52)
		body.add_child(entry)
		UIFeedback.pop_in(entry, 0.2 + s * 0.1, 0.5)
	return parts[0]


func _open_study(study: int) -> void:
	var years := _data().get_existing_years(study)
	if years.size() == 1:
		go_to({"screen": "subject", "study": study, "year": years[0]})
	else:
		go_to({"screen": "year", "study": study})


# --- Année -----------------------------------------------------------------

func _build_year_menu(study: int) -> Control:
	var color := UIStyle.STUDY_COLORS[study]
	var parts := _screen(GameData.STUDY_NAMES[study], true, color)
	var body: VBoxContainer = parts[1]
	body.add_child(UIStyle.label("Choisis ton année", 34))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 22)
	body.add_child(grid)
	for i in GameData.YEARS_PER_STUDY:
		var year := _data().get_year(study, i)
		var total := year.count_levels() if year != null else 0
		var done := 0
		if year != null:
			for s in year.subjects.size():
				done += GameState.completed_count(GameState.make_key(study, i, s))
		var entry := _menu_entry(_data().get_year_name(study, i), color, Vector2i(done, total),
			func() -> void: go_to({"screen": "subject", "study": study, "year": i}), 120.0, 46)
		grid.add_child(entry)
		UIFeedback.pop_in(entry, 0.1 + i * 0.06, 0.5)
	return parts[0]


# --- Matière ---------------------------------------------------------------

func _build_subject_menu(study: int, year_index: int) -> Control:
	var parts := _screen("%s - %s" % [GameData.STUDY_NAMES[study], _data().get_year_name(study, year_index)], true, UIStyle.STUDY_COLORS[study])
	var body: VBoxContainer = parts[1]
	body.add_child(UIStyle.label("Choisis ta matière", 34))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 22)
	scroll.add_child(list)
	var year := _data().get_year(study, year_index)
	if year == null or year.subjects.is_empty():
		list.add_child(_soon_label())
		return parts[0]
	for i in year.subjects.size():
		var subject := year.subjects[i]
		if subject == null:
			continue
		var color := subject.color if subject.color.a > 0 else UIStyle.SUBJECT_COLORS[i % UIStyle.SUBJECT_COLORS.size()]
		var entry := _menu_entry(subject.name, color, GameManager.subject_progress(study, year_index, i),
			func() -> void: go_to({"screen": "grid", "study": study, "year": year_index, "subject": i}), 120.0, 44)
		list.add_child(entry)
		UIFeedback.pop_in(entry, 0.1 + i * 0.08, 0.5)
	return parts[0]


# --- Grille des levels -----------------------------------------------------

func _build_level_grid(study: int, year_index: int, subject_index: int) -> Control:
	var subject := _data().get_subject(study, year_index, subject_index)
	var key := GameState.make_key(study, year_index, subject_index)
	var levels := _valid_levels(subject)
	var parts := _screen(subject.name, true, UIStyle.STUDY_COLORS[study])
	var body: VBoxContainer = parts[1]
	var info := UIStyle.pill("%s - %s   •   %d / %d" % [GameData.STUDY_NAMES[study], _data().get_year_name(study, year_index),
		GameState.completed_count(key), levels.size()], UIStyle.PANEL_DARK, 24)
	info.size_flags_horizontal = SIZE_SHRINK_CENTER
	body.add_child(info)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var path := LevelPath.new(levels, key)
	scroll.add_child(path)
	scroll.resized.connect(func() -> void: path.fit_height(scroll.size.y))
	path.level_pressed.connect(func(i: int) -> void:
		if not GameState.is_unlocked(key, i):
			Sfx.play("locked")
			UIFeedback.shake(path.nodes[i], 10.0, 0.35)
			return
		Sfx.play("pop")
		GameState.select(key, i)
		go_to({"screen": "level", "study": study, "year": year_index, "subject": subject_index, "index": i}))

	var pending := GameState.pending_unlock
	var unlock_index: int = pending.get("index", -1) if pending.get("key", "") == key else -1
	if unlock_index >= 0:
		GameState.pending_unlock = {}
		path.nodes[unlock_index].state = LevelNode.State.LOCKED
		path.unlock_index = unlock_index
		path.unlock_glow = 0.0
	# Centre la vue sur le level en cours, puis joue l'animation de déblocage.
	scroll.ready.connect(func() -> void:
		await get_tree().process_frame
		await get_tree().process_frame
		if not is_instance_valid(scroll):
			return
		var focus := unlock_index if unlock_index >= 0 else GameState.get_selected(key)
		focus = clampi(focus, 0, maxi(levels.size() - 1, 0))
		if levels.size() > 0:
			scroll.scroll_vertical = int(path.node_center(focus).y - scroll.size.y / 2)
		if unlock_index >= 0:
			await get_tree().create_timer(0.3).timeout
			if is_instance_valid(path):
				path.play_unlock(unlock_index))
	return parts[0]


# --- Level -----------------------------------------------------------------

func _build_level(study: int, year_index: int, subject_index: int, index: int) -> Control:
	var subject := _data().get_subject(study, year_index, subject_index)
	var levels := _valid_levels(subject)
	var level := levels[index]
	var key := GameState.make_key(study, year_index, subject_index)
	var parts: Array[String] = [GameData.STUDY_NAMES[study], _data().get_year_name(study, year_index), subject.name]
	if level.mini_game.theme_title.strip_edges() != "":
		parts.append(level.mini_game.theme_title)
	var screen := LevelScreen.new(level, " - ".join(PackedStringArray(parts)))
	screen.exited.connect(go_back)
	screen.validated.connect(func() -> void:
		GameState.complete_level(key, index, levels.size())
		go_back())
	return screen
