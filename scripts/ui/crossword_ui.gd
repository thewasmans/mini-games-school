class_name CrosswordUI
extends MiniGameUI
## Mots croisés : clic sur une case pour choisir un mot, saisie au clavier,
## vérification dès que le mot est complet.

var _data: CrosswordData
var _cells := {}                   # Vector2i -> CrosswordCell
var _words: Array[Dictionary] = []  # { entry, cells: Array[Vector2i], done }
var _selected := -1
var _cursor := 0
var _last_clicked := Vector2i(-1, -1)
var _show_hints := false
var _autofilling := false

var _clue_panel: PanelContainer
var _clue_number: Label
var _clue_dir: Label
var _clue_text: Label
var _clue_answer: Label
var _grid_area: Control


func setup(data: MiniGameData) -> void:
	_data = data as CrosswordData
	if not _data.is_generated():
		push_warning("Grille non générée pour « %s » : régénère-la dans l'onglet Crossword." % _data.theme_title)
		CrosswordGenerator.generate(_data)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# Panneau « Indice » : cadre bleu titré, intérieur bleu nuit (comme les panneaux « Clue »).
	_clue_panel = PanelContainer.new()
	var sb := UIStyle.frame_box()
	sb.content_margin_top = 8
	sb.content_margin_bottom = 14
	_clue_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_clue_panel)
	var frame_box := VBoxContainer.new()
	frame_box.add_theme_constant_override("separation", 6)
	_clue_panel.add_child(frame_box)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 12)
	frame_box.add_child(head)
	head.add_child(UIStyle.label("Indice", 32, Color.WHITE, 10))
	var dir_pill := UIStyle.pill("", UIStyle.PANEL_DARK, 22)
	_clue_dir = dir_pill.get_child(0)
	head.add_child(dir_pill)
	var inner := PanelContainer.new()
	inner.add_theme_stylebox_override("panel", UIStyle.inner_box())
	frame_box.add_child(inner)
	var clue_row := HBoxContainer.new()
	clue_row.add_theme_constant_override("separation", 12)
	inner.add_child(clue_row)
	_clue_number = UIStyle.label("1.", 30, UIStyle.YELLOW, 8)
	_clue_number.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	clue_row.add_child(_clue_number)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = SIZE_EXPAND_FILL
	clue_row.add_child(text_col)
	var clue_box := text_col
	_clue_text = UIStyle.label("", 28)
	_clue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_clue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_clue_text.custom_minimum_size = Vector2(0, 76)
	clue_box.add_child(_clue_text)
	_clue_answer = UIStyle.label("", 22, UIStyle.YELLOW, 6)
	_clue_answer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_clue_answer.visible = false
	clue_box.add_child(_clue_answer)

	# Plateau translucide sous la grille
	_grid_area = Panel.new()
	var board := UIStyle.box(Color(0.06, 0.12, 0.4, 0.55), 24, 0, 2, Color(0.6, 0.8, 1.0, 0.35))
	_grid_area.add_theme_stylebox_override("panel", board)
	_grid_area.size_flags_vertical = SIZE_EXPAND_FILL
	_grid_area.resized.connect(_layout_grid)
	root.add_child(_grid_area)

	var keyboard := OnScreenKeyboard.new(68)
	keyboard.letter_pressed.connect(_type)
	keyboard.backspace_pressed.connect(_backspace)
	root.add_child(keyboard)

	_build_grid()
	_select_word(_next_open(-1))


func _build_grid() -> void:
	for e in _data.get_placed_entries():
		var cells: Array[Vector2i] = []
		var dir := Vector2i(1, 0) if e.horizontal else Vector2i(0, 1)
		for k in e.answer.length():
			var p := Vector2i(e.x, e.y) + dir * k
			cells.append(p)
			var cell: CrosswordCell = _cells.get(p)
			if cell == null:
				cell = CrosswordCell.new()
				cell.solution = e.answer[k]
				cell.clicked.connect(_on_cell_clicked.bind(p))
				_grid_area.add_child(cell)
				_cells[p] = cell
			cell.words.append(_words.size())
			if k == 0:
				cell.number = e.number
		_words.append({"entry": e, "cells": cells, "done": false})


func _layout_grid() -> void:
	if _data.grid_width <= 0:
		return
	var pad := 12.0
	var avail := _grid_area.size - Vector2(pad, pad) * 2
	var cs := floorf(minf(avail.x / _data.grid_width, avail.y / _data.grid_height))
	cs = minf(cs, 86.0)
	var gap := maxf(2.0, cs * 0.07)
	var origin := Vector2(pad, pad) + (avail - Vector2(_data.grid_width, _data.grid_height) * cs) / 2
	for p: Vector2i in _cells:
		var cell: CrosswordCell = _cells[p]
		cell.position = origin + Vector2(p) * cs + Vector2(gap, gap) / 2
		cell.size = Vector2(cs - gap, cs - gap)
		cell.pivot_offset = cell.size / 2


func _ready() -> void:
	super()
	for p: Vector2i in _cells:
		var cell: CrosswordCell = _cells[p]
		cell.modulate.a = 0
		var tw := cell.create_tween()
		tw.tween_interval(0.15 + (p.x + p.y) * 0.03)
		tw.tween_callback(cell.celebrate)
		tw.parallel().tween_property(cell, "modulate:a", 1.0, 0.15)


# --- Sélection -------------------------------------------------------------

func _on_cell_clicked(p: Vector2i) -> void:
	if is_completed:
		return
	var cell: CrosswordCell = _cells[p]
	if _selected in cell.words and p == _last_clicked and cell.words.size() > 1:
		# Deuxième clic sur un croisement : on passe à l'autre mot.
		var other := cell.words[0] if cell.words[1] == _selected else cell.words[1]
		_select_word(other, p)
	elif _selected in cell.words:
		_cursor = _words[_selected].cells.find(p)
	else:
		var choice := cell.words[0]
		for w in cell.words:
			if not _words[w].done:
				choice = w
				break
		_select_word(choice, p)
	_last_clicked = p
	Sfx.play("click", 1.3)
	UIFeedback.punch(cell, 0.12)
	_refresh()


func _select_word(index: int, at := Vector2i(-1, -1)) -> void:
	if index < 0:
		return
	var changed := index != _selected
	_selected = index
	var w := _words[index]
	var cells: Array[Vector2i] = w.cells
	_cursor = cells.find(at) if at in cells else _first_empty(w)
	var e: CrosswordEntry = w.entry
	_clue_number.text = "%d." % e.number
	_clue_dir.text = "→  HORIZONTAL" if e.horizontal else "↓  VERTICAL"
	_clue_text.text = e.clue
	_clue_answer.text = "Réponse : " + e.answer
	_clue_answer.visible = _show_hints
	if changed:
		UIFeedback.punch(_clue_panel, 0.04, 0.35)
	_refresh()


func _first_empty(w: Dictionary) -> int:
	var cells: Array[Vector2i] = w.cells
	for i in cells.size():
		var cell: CrosswordCell = _cells[cells[i]]
		if cell.letter == "" and not cell.validated:
			return i
	return maxi(0, _skip_locked(cells, 0, 1))


func _next_open(after: int) -> int:
	for k in _words.size():
		var i := (after + 1 + k) % _words.size()
		if not _words[i].done:
			return i
	return -1


func _skip_locked(cells: Array[Vector2i], from: int, step: int) -> int:
	var i := from
	while i >= 0 and i < cells.size():
		if not (_cells[cells[i]] as CrosswordCell).validated:
			return i
		i += step
	return -1


func _refresh() -> void:
	for p: Vector2i in _cells:
		var cell: CrosswordCell = _cells[p]
		cell.highlight = CrosswordCell.Highlight.NONE
		cell.hint = _show_hints
	if _selected >= 0 and not _words[_selected].done:
		var cells: Array[Vector2i] = _words[_selected].cells
		for i in cells.size():
			var cell: CrosswordCell = _cells[cells[i]]
			cell.highlight = CrosswordCell.Highlight.CURSOR if i == _cursor else CrosswordCell.Highlight.WORD
	for p: Vector2i in _cells:
		(_cells[p] as CrosswordCell).refresh()


# --- Saisie ----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if is_completed or not is_visible_in_tree():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_BACKSPACE:
		_backspace()
	elif key.keycode == KEY_TAB or key.keycode == KEY_ENTER:
		_select_word(_next_open(_selected))
	elif key.unicode > 0 and TextUtil.is_letter(String.chr(key.unicode)):
		_type(TextUtil.normalize_char(String.chr(key.unicode)))
	else:
		return
	get_viewport().set_input_as_handled()


func _type(letter: String) -> void:
	if is_completed or _autofilling:
		return
	if _selected < 0 or _words[_selected].done:
		_select_word(_next_open(_selected))
		if _selected < 0:
			return
	var w := _words[_selected]
	var cells: Array[Vector2i] = w.cells
	_cursor = _skip_locked(cells, _cursor, 1)
	if _cursor < 0:
		_cursor = _skip_locked(cells, 0, 1)
	var cell: CrosswordCell = _cells[cells[_cursor]]
	cell.letter = letter
	_clear_wrong(w)
	UIFeedback.punch(cell, 0.22, 0.3)
	var next := _skip_locked(cells, _cursor + 1, 1)
	if next != -1:
		_cursor = next
	_refresh()
	if _is_full(w):
		_check_word(_selected)


func _backspace() -> void:
	if is_completed or _selected < 0 or _words[_selected].done or _autofilling:
		return
	var w := _words[_selected]
	var cells: Array[Vector2i] = w.cells
	var cell: CrosswordCell = _cells[cells[_cursor]]
	if cell.letter != "" and not cell.validated:
		cell.letter = ""
	else:
		var prev := _skip_locked(cells, _cursor - 1, -1)
		if prev != -1:
			_cursor = prev
			(_cells[cells[prev]] as CrosswordCell).letter = ""
	_clear_wrong(w)
	_refresh()


func _clear_wrong(w: Dictionary) -> void:
	for p: Vector2i in w.cells:
		(_cells[p] as CrosswordCell).wrong = false


func _is_full(w: Dictionary) -> bool:
	for p: Vector2i in w.cells:
		if (_cells[p] as CrosswordCell).letter == "":
			return false
	return true


func _is_right(w: Dictionary) -> bool:
	for p: Vector2i in w.cells:
		var cell: CrosswordCell = _cells[p]
		if cell.letter != cell.solution:
			return false
	return true


# --- Vérification ----------------------------------------------------------

func _check_word(index: int) -> void:
	var w := _words[index]
	if not _is_right(w):
		for p: Vector2i in w.cells:
			var cell: CrosswordCell = _cells[p]
			cell.wrong = true
			cell.shake()
		Sfx.play("error")
		_refresh()
		return
	_validate_word(index)
	if _all_done():
		_on_grid_complete()
	elif _words[_selected].done:
		_select_word(_next_open(_selected))


func _validate_word(index: int) -> void:
	var w := _words[index]
	w.done = true
	var cells: Array[Vector2i] = w.cells
	for i in cells.size():
		var cell: CrosswordCell = _cells[cells[i]]
		cell.validated = true
		cell.wrong = false
		cell.celebrate(i * 0.05)
	Sfx.play("word")
	var mid: CrosswordCell = _cells[cells[cells.size() / 2]]
	Confetti.sparkle(self, mid.global_position + mid.size / 2, 14)
	progress_changed.emit(_done_count() / float(_words.size()))
	# Un mot croisé peut se retrouver complet et juste grâce à celui-ci.
	for p in cells:
		for other: int in (_cells[p] as CrosswordCell).words:
			var ow := _words[other]
			if not ow.done and _is_full(ow) and _is_right(ow):
				_validate_word(other)


func _done_count() -> int:
	var n := 0
	for w in _words:
		if w.done:
			n += 1
	return n


func _all_done() -> bool:
	return _done_count() == _words.size()


func _on_grid_complete() -> void:
	_selected = -1
	_refresh()
	# Vague diagonale sur toute la grille, puis confettis.
	for p: Vector2i in _cells:
		(_cells[p] as CrosswordCell).celebrate(0.35 + (p.x + p.y) * 0.05)
	await _wait(0.6 + (_data.grid_width + _data.grid_height) * 0.05)
	if is_inside_tree():
		_finish()


# --- Helper F1 -------------------------------------------------------------

func set_show_hints(on: bool) -> void:
	_show_hints = on
	if _clue_answer:
		_clue_answer.visible = on
	_refresh()


func debug_autofill() -> void:
	if _autofilling or is_completed:
		return
	_autofilling = true
	for i in _words.size():
		if _words[i].done:
			continue
		_select_word(i)
		for p: Vector2i in _words[i].cells:
			var cell: CrosswordCell = _cells[p]
			cell.letter = cell.solution
		_refresh()
		await _wait(0.12)
		if not is_inside_tree():
			return
		if not _words[i].done:
			_validate_word(i)
	_autofilling = false
	if _all_done():
		_on_grid_complete()
