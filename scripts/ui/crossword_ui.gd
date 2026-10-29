class_name CrosswordUI
extends MiniGameUI

var _data: CrosswordData
var _cells := {}
var _words: Array[Dictionary] = []
var _selected := -1
var _cursor := 0
var _last_clicked := Vector2i(-1, -1)
@export var clue_panel: TitledPanel
@export var clue_number_label: Label
@export var clue_direction_pill: Pill
@export var clue_text_label: Label
@export var grid_area: Control
@export var keyboard: OnScreenKeyboard
@export var cell_prefab: PackedScene

@export_group("Réglages")
## Taille maximale d'une case de la grille, en pixels.
@export var max_cell_size := 86.0
## Marge entre le bord du plateau et la grille, en pixels.
@export var grid_padding := 12.0


func _ready() -> void:
	grid_area.resized.connect(_layout_grid)
	keyboard.letter_pressed.connect(_type)
	keyboard.backspace_pressed.connect(_backspace)


func initialize(mini_game_data: MiniGameData) -> void:
	_data = mini_game_data as CrosswordData
	if not _data.is_generated():
		push_warning("Grille non générée pour « %s » : régénère-la dans l'onglet Crossword." % _data.theme_title)
		CrosswordGenerator.generate(_data)
	_build_grid()
	_layout_grid()
	progress_changed.emit(0, _words.size())
	_select_word(_next_open(-1))
	for p: Vector2i in _cells:
		var cell: CrosswordCell = _cells[p]
		cell.modulate.a = 0
		var tw := cell.create_tween()
		tw.tween_interval(0.15 + (p.x + p.y) * 0.03)
		tw.tween_callback(cell.celebrate)
		tw.parallel().tween_property(cell, "modulate:a", 1.0, 0.15)


func _build_grid() -> void:
	for e in _data.get_placed_entries():
		var cells: Array[Vector2i] = []
		var dir := Vector2i(1, 0) if e.horizontal else Vector2i(0, 1)
		for k in e.answer.length():
			var p := Vector2i(e.x, e.y) + dir * k
			cells.append(p)
			var cell: CrosswordCell = _cells.get(p)
			if cell == null:
				cell = cell_prefab.instantiate() as CrosswordCell
				cell.solution = e.answer[k]
				cell.clicked.connect(_on_cell_clicked.bind(p))
				grid_area.add_child(cell)
				_cells[p] = cell
			cell.words.append(_words.size())
			if k == 0:
				cell.number = e.number
		_words.append({"entry": e, "cells": cells, "done": false})


func _layout_grid() -> void:
	if _data == null or _data.grid_width <= 0:
		return
	var pad := grid_padding
	var avail := grid_area.size - Vector2(pad, pad) * 2
	var cs := floorf(minf(avail.x / _data.grid_width, avail.y / _data.grid_height))
	cs = minf(cs, max_cell_size)
	var gap := maxf(2.0, cs * 0.07)
	var origin := Vector2(pad, pad) + (avail - Vector2(_data.grid_width, _data.grid_height) * cs) / 2
	for p: Vector2i in _cells:
		var cell: CrosswordCell = _cells[p]
		cell.position = origin + Vector2(p) * cs + Vector2(gap, gap) / 2
		cell.size = Vector2(cs - gap, cs - gap)
		cell.pivot_offset = cell.size / 2


func _on_cell_clicked(p: Vector2i) -> void:
	if is_completed:
		return
	var cell: CrosswordCell = _cells[p]
	if _selected in cell.words and p == _last_clicked and cell.words.size() > 1:
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
	clue_number_label.text = "%d." % e.number
	clue_direction_pill.text = "→  HORIZONTAL" if e.horizontal else "↓  VERTICAL"
	clue_text_label.text = e.clue
	if changed:
		UIFeedback.punch(clue_panel, 0.04, 0.35)
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
	if _selected >= 0 and not _words[_selected].done:
		var cells: Array[Vector2i] = _words[_selected].cells
		for i in cells.size():
			var cell: CrosswordCell = _cells[cells[i]]
			cell.highlight = CrosswordCell.Highlight.CURSOR if i == _cursor else CrosswordCell.Highlight.WORD
	for p: Vector2i in _cells:
		(_cells[p] as CrosswordCell).refresh()


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
	if is_completed:
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
	if is_completed or _selected < 0 or _words[_selected].done:
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
	progress_changed.emit(_done_count(), _words.size())
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
	for p: Vector2i in _cells:
		(_cells[p] as CrosswordCell).celebrate(0.35 + (p.x + p.y) * 0.05)
	await _wait(0.6 + (_data.grid_width + _data.grid_height) * 0.05)
	if is_inside_tree():
		_finish()
