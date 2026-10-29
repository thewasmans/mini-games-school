class_name CryptoUI
extends MiniGameUI

var _data: CryptoData
var _index := 0
var _cells: Array[CryptoCell] = []
var _hidden: Array[int] = []
var _cursor := -1
var _solved := false

@export var hint_label: Label
@export var counter_pill: Pill
@export var sentence_panel: MenuPanel
@export var flow: HFlowContainer
@export var fix_button: JuicyButton
@export var next_button: JuicyButton
@export var keyboard: OnScreenKeyboard
@export var cell_prefab: PackedScene

@export_group("Réglages")
## Taille d'une case de lettre, pour les phrases courtes.
@export var cell_size := Vector2(46, 60)
## Taille d'une case de lettre, pour les phrases de plus de 45 caractères.
@export var small_cell_size := Vector2(38, 52)


func _ready() -> void:
	keyboard.letter_pressed.connect(_type)
	keyboard.backspace_pressed.connect(_backspace)
	fix_button.pressed.connect(_fix_errors)
	next_button.pressed.connect(_next_sentence)


func initialize(mini_game_data: MiniGameData) -> void:
	_data = mini_game_data as CryptoData
	progress_changed.emit(0, _data.sentences.size())
	_load_sentence(0)


func _load_sentence(i: int) -> void:
	_index = i
	_solved = false
	var s := _data.sentences[i]
	var text := s.sentence.strip_edges()
	counter_pill.text = "Phrase %d / %d" % [i + 1, _data.sentences.size()]
	hint_label.text = s.hint
	fix_button.visible = false
	next_button.visible = false

	for child in flow.get_children():
		child.queue_free()
	_cells.clear()
	var letter_size := cell_size if text.length() <= 45 else small_cell_size
	var word_box: HBoxContainer = null
	var candidates: Array[int] = []
	for k in text.length():
		var ch := text[k]
		if ch == " ":
			_cells.append(null)
			word_box = null
			continue
		if word_box == null:
			word_box = HBoxContainer.new()
			word_box.add_theme_constant_override("separation", 4)
			flow.add_child(word_box)
		var cell := cell_prefab.instantiate() as CryptoCell
		cell.setup(ch, letter_size if TextUtil.is_letter(ch) else Vector2(letter_size.x * 0.5, letter_size.y))
		if TextUtil.is_letter(ch):
			candidates.append(k)
		else:
			cell.state = CryptoCell.State.SYMBOL
		cell.clicked.connect(_on_cell_clicked.bind(k))
		word_box.add_child(cell)
		_cells.append(cell)

	candidates.shuffle()
	var count := clampi(roundi(candidates.size() * _data.hidden_ratio), 1, candidates.size())
	_hidden.assign(candidates.slice(0, count))
	_hidden.sort()
	for k in _hidden:
		_cells[k].state = CryptoCell.State.EMPTY
	_cursor = 0
	_refresh()

	var n := 0
	for cell in _cells:
		if cell != null:
			UIFeedback.pop_in(cell, 0.05 + n * 0.015, 0.3)
			n += 1


func _refresh() -> void:
	for k in _cells.size():
		var cell := _cells[k]
		if cell == null:
			continue
		cell.is_cursor = _cursor >= 0 and _cursor < _hidden.size() and _hidden[_cursor] == k and not _solved
		cell.refresh()


func _editable(k: int) -> bool:
	var st := _cells[k].state
	return st == CryptoCell.State.EMPTY or st == CryptoCell.State.FILLED or st == CryptoCell.State.WRONG


func _on_cell_clicked(k: int) -> void:
	if _solved or not k in _hidden or not _editable(k):
		return
	_cursor = _hidden.find(k)
	if _cells[k].state == CryptoCell.State.WRONG:
		_cells[k].state = CryptoCell.State.FILLED
	Sfx.play("click", 1.3)
	UIFeedback.punch(_cells[k], 0.15)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _solved or is_completed or not is_visible_in_tree():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_BACKSPACE:
		_backspace()
	elif key.unicode > 0 and TextUtil.is_letter(String.chr(key.unicode)):
		_type(TextUtil.normalize_char(String.chr(key.unicode)))
	else:
		return
	get_viewport().set_input_as_handled()


func _type(letter: String) -> void:
	if _solved or _cursor < 0 or _cursor >= _hidden.size():
		return
	var cell := _cells[_hidden[_cursor]]
	cell.typed = letter
	cell.state = CryptoCell.State.FILLED
	UIFeedback.punch(cell, 0.22, 0.3)
	_cursor = _next_empty(_cursor)
	_refresh()
	if _cursor == -1:
		_check()


func _next_empty(from: int) -> int:
	for step in range(1, _hidden.size() + 1):
		var i := (from + step) % _hidden.size()
		if _cells[_hidden[i]].state == CryptoCell.State.EMPTY:
			return i
	return -1


func _backspace() -> void:
	if _solved or _cursor < 0:
		return
	var cell := _cells[_hidden[_cursor]]
	if cell.state == CryptoCell.State.FILLED or cell.state == CryptoCell.State.WRONG:
		cell.typed = ""
		cell.state = CryptoCell.State.EMPTY
	else:
		var i := _cursor - 1
		while i >= 0 and not _editable(_hidden[i]):
			i -= 1
		if i < 0:
			return
		_cursor = i
		var prev := _cells[_hidden[i]]
		prev.typed = ""
		prev.state = CryptoCell.State.EMPTY
	Sfx.play("type", 0.8)
	_refresh()


func _check() -> void:
	var wrong := 0
	for n in _hidden.size():
		var cell := _cells[_hidden[n]]
		if cell.state == CryptoCell.State.CORRECT:
			continue
		if TextUtil.normalize_char(cell.typed) == TextUtil.normalize_char(cell.original):
			cell.state = CryptoCell.State.CORRECT
			UIFeedback.punch(cell, 0.25, 0.5)
		else:
			cell.state = CryptoCell.State.WRONG
			cell.shake()
			wrong += 1
	_refresh()
	if wrong > 0:
		Sfx.play("error")
		fix_button.visible = true
		UIFeedback.pop_in(fix_button)
		return

	_solved = true
	_refresh()
	Sfx.play("good")
	UIFeedback.punch(sentence_panel, 0.04, 0.5)
	Confetti.sparkle(self, sentence_panel.global_position + sentence_panel.size / 2, 30)
	progress_changed.emit(_index + 1, _data.sentences.size())
	next_button.visible = true
	UIFeedback.pop_in(next_button)


func _fix_errors() -> void:
	var first := -1
	for n in _hidden.size():
		var cell := _cells[_hidden[n]]
		if cell.state == CryptoCell.State.WRONG:
			cell.typed = ""
			cell.state = CryptoCell.State.EMPTY
			if first == -1:
				first = n
	_cursor = first
	fix_button.visible = false
	_refresh()


func _next_sentence() -> void:
	if not _solved or is_completed:
		return
	next_button.visible = false
	if _index + 1 >= _data.sentences.size():
		_finish()
		return
	var tw := create_tween()
	tw.tween_property(flow, "modulate:a", 0.0, 0.2)
	await tw.finished
	if not is_inside_tree():
		return
	flow.modulate.a = 1.0
	Sfx.play("whoosh")
	_load_sentence(_index + 1)
