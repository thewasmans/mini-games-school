class_name CryptoUI
extends MiniGameUI
## Cryptogramme : retrouver les lettres cachées d'une phrase à l'aide d'un indice.

var _data: CryptoData
var _index := 0
var _cells: Array[CryptoCell] = []  # une case par caractère (null pour les espaces)
var _hidden: Array[int] = []         # index des caractères cachés, dans l'ordre
var _cursor := -1                     # position dans _hidden
var _solved := false
var _show_hints := false

var _counter: Label
var _hint_label: Label
var _answer_label: Label
var _sentence_panel: MenuPanel
var _flow: HFlowContainer
var _fix_button: JuicyButton
var _next_button: JuicyButton


func setup(data: MiniGameData) -> void:
	_data = data as CryptoData
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	# Panneau « Indice » : cadre bleu titré, intérieur bleu nuit.
	var hint_panel := TitledPanel.create("Indice")
	root.add_child(hint_panel)
	var counter_pill := Pill.create()
	_counter = counter_pill.label
	hint_panel.header.add_child(counter_pill)
	var hint_box := hint_panel.content
	_hint_label = UIStyle.label("", 28)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_box.add_child(_hint_label)
	_answer_label = UIStyle.label("", 22, UIStyle.YELLOW, 6)
	_answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_answer_label.visible = false
	hint_box.add_child(_answer_label)

	_sentence_panel = MenuPanel.create()
	_sentence_panel.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(_sentence_panel)
	var center := CenterContainer.new()
	center.size_flags_vertical = SIZE_EXPAND_FILL
	_sentence_panel.content.add_child(center)
	_flow = HFlowContainer.new()
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("h_separation", 22)
	_flow.add_theme_constant_override("v_separation", 14)
	_flow.custom_minimum_size = Vector2(620, 0)
	center.add_child(_flow)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.custom_minimum_size = Vector2(0, 96)
	root.add_child(buttons)
	_fix_button = JuicyButton.new("Corriger les erreurs", Color("ff6b74"), 30)
	_fix_button.custom_minimum_size = Vector2(420, 90)
	_fix_button.visible = false
	_fix_button.pressed.connect(_fix_errors)
	buttons.add_child(_fix_button)
	_next_button = JuicyButton.new("Valider", Color("6bd85a"), 34)
	_next_button.icon_right = "next"
	_next_button.sparkles = true
	_next_button.custom_minimum_size = Vector2(320, 90)
	_next_button.visible = false
	_next_button.set_shine(true)
	_next_button.pressed.connect(_next_sentence)
	buttons.add_child(_next_button)

	var keyboard := OnScreenKeyboard.create(68)
	keyboard.letter_pressed.connect(_type)
	keyboard.backspace_pressed.connect(_backspace)
	root.add_child(keyboard)


func _ready() -> void:
	super()
	_load_sentence(0)


func _load_sentence(i: int) -> void:
	_index = i
	_solved = false
	var s := _data.sentences[i]
	var text := s.sentence.strip_edges()
	_counter.text = "Phrase %d / %d" % [i + 1, _data.sentences.size()]
	_hint_label.text = s.hint
	_answer_label.text = "Réponse : " + text
	_answer_label.visible = _show_hints
	_fix_button.visible = false
	_next_button.visible = false

	for child in _flow.get_children():
		child.queue_free()
	_cells.clear()
	var cell_size := Vector2(46, 60) if text.length() <= 45 else Vector2(38, 52)
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
			_flow.add_child(word_box)
		var cell := CryptoCell.new(ch, cell_size if TextUtil.is_letter(ch) else Vector2(cell_size.x * 0.5, cell_size.y))
		if TextUtil.is_letter(ch):
			candidates.append(k)
		else:
			cell.state = CryptoCell.State.SYMBOL
		cell.clicked.connect(_on_cell_clicked.bind(k))
		word_box.add_child(cell)
		_cells.append(cell)

	# Lettres cachées tirées au hasard à chaque partie.
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
	if GameManager.debug_auto_fill:
		debug_autofill()


func _refresh() -> void:
	for k in _cells.size():
		var cell := _cells[k]
		if cell == null:
			continue
		cell.is_cursor = _cursor >= 0 and _cursor < _hidden.size() and _hidden[_cursor] == k and not _solved
		cell.hint = _show_hints
		cell.refresh()


func _editable(k: int) -> bool:
	var st := _cells[k].state
	return st == CryptoCell.State.EMPTY or st == CryptoCell.State.FILLED or st == CryptoCell.State.WRONG


# --- Saisie ----------------------------------------------------------------

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


## Prochaine case vide après `from` (en bouclant), -1 s'il n'y en a plus.
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


# --- Vérification ----------------------------------------------------------

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
		_fix_button.visible = true
		UIFeedback.pop_in(_fix_button)
		return

	_solved = true
	_refresh()
	Sfx.play("good")
	UIFeedback.punch(_sentence_panel, 0.04, 0.5)
	Confetti.sparkle(self, _sentence_panel.global_position + _sentence_panel.size / 2, 30)
	progress_changed.emit((_index + 1) / float(_data.sentences.size()))
	_next_button.visible = true
	UIFeedback.pop_in(_next_button)
	if GameManager.debug_auto_fill and GameManager.debug_auto_validate:
		await _wait(0.8)
		if is_inside_tree() and _next_button.visible:
			_next_sentence()


## Efface les lettres fausses et place le curseur sur la première.
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
	_fix_button.visible = false
	_refresh()


func _next_sentence() -> void:
	if not _solved or is_completed:
		return
	_next_button.visible = false
	if _index + 1 >= _data.sentences.size():
		_finish()
		return
	var tw := create_tween()
	tw.tween_property(_flow, "modulate:a", 0.0, 0.2)
	await tw.finished
	if not is_inside_tree():
		return
	_flow.modulate.a = 1.0
	Sfx.play("whoosh")
	_load_sentence(_index + 1)


# --- Helper F1 -------------------------------------------------------------

func set_show_hints(on: bool) -> void:
	_show_hints = on
	if _answer_label:
		_answer_label.visible = on
	_refresh()


func debug_autofill() -> void:
	var i := _index
	await _wait(0.5)
	if not is_inside_tree() or i != _index or _solved:
		return
	for k in _hidden:
		var cell := _cells[k]
		if cell.state != CryptoCell.State.CORRECT:
			cell.typed = TextUtil.normalize_char(cell.original)
			cell.state = CryptoCell.State.FILLED
	_cursor = -1
	_check()
