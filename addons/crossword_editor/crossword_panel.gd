@tool
extends VBoxContainer
## Panneau de l'onglet Crossword : ouvrir, régénérer, inspecter la grille.

const CrosswordPreview := preload("res://addons/crossword_editor/crossword_preview.gd")

var _data: CrosswordData
var _path_label: Label
var _regen: Button
var _full: CheckBox
var _preview: CrosswordPreview
var _list: ItemList
var _status: Label
var _open_dialog: EditorFileDialog
var _placed: Array[CrosswordEntry] = []


func _init() -> void:
	var bar := HBoxContainer.new()
	add_child(bar)
	var open_btn := Button.new()
	open_btn.text = "Ouvrir un mot croisé…"
	open_btn.pressed.connect(func() -> void: _open_dialog.popup_file_dialog())
	bar.add_child(open_btn)
	_regen = Button.new()
	_regen.text = "Régénérer la grille"
	_regen.tooltip_text = "Recalcule la place des mots et enregistre la ressource."
	_regen.disabled = true
	_regen.pressed.connect(_regenerate)
	bar.add_child(_regen)
	_full = CheckBox.new()
	_full.text = "Grille complète"
	_full.toggled.connect(func(on: bool) -> void:
		_preview.full_grid = on
		_preview.queue_redraw())
	bar.add_child(_full)
	_path_label = Label.new()
	_path_label.text = "Glisse ici un mot croisé ou un level."
	_path_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_path_label.modulate = Color(1, 1, 1, 0.6)
	bar.add_child(_path_label)

	var split := HSplitContainer.new()
	split.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(split)
	_preview = CrosswordPreview.new()
	_preview.size_flags_horizontal = SIZE_EXPAND_FILL
	_preview.size_flags_stretch_ratio = 2.0
	_preview.clip_contents = true
	_preview.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)
	split.add_child(_preview)
	_list = ItemList.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(320, 0)
	_list.item_selected.connect(_on_word_selected)
	_list.set_drag_forwarding(Callable(), _can_drop_data, _drop_data)
	split.add_child(_list)

	_status = Label.new()
	add_child(_status)

	_open_dialog = EditorFileDialog.new()
	_open_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_open_dialog.title = "Ouvrir un mot croisé ou un level"
	_open_dialog.add_filter("*.tres, *.res", "Ressources")
	_open_dialog.file_selected.connect(func(path: String) -> void:
		var data := _resolve(load(path))
		if data == null:
			push_warning("%s n'est ni un mot croisé ni un level de mots croisés." % path)
		else:
			open(data))
	add_child(_open_dialog)


func open(data: CrosswordData) -> void:
	_data = data
	_regen.disabled = data == null
	_path_label.text = data.resource_path if data.resource_path != "" else "(ressource intégrée)"
	_refresh()


func _refresh() -> void:
	_list.clear()
	_placed.clear()
	_preview.data = _data
	_preview.highlighted = null
	if _data == null:
		_preview.queue_redraw()
		return
	var analysis := CrosswordGenerator.analyze(_data)
	_preview.isolated = analysis.isolated
	_preview.conflicts = analysis.conflicts
	var unplaced := 0
	var sorted := _data.get_placed_entries()
	sorted.sort_custom(func(a: CrosswordEntry, b: CrosswordEntry) -> bool:
		return a.number < b.number or (a.number == b.number and a.horizontal))
	for e in sorted:
		var idx := _list.add_item("%2d %s  %s  —  %s" % [e.number, "→" if e.horizontal else "↓", e.answer, e.clue])
		_placed.append(e)
		if e in analysis.isolated:
			_list.set_item_custom_fg_color(idx, Color("ff9f1c"))
			_list.set_item_tooltip(idx, "Mot isolé : il ne croise aucun autre mot.")
	for e in _data.entries:
		if e != null and not e.placed:
			unplaced += 1
			var idx := _list.add_item("   %s  (non placé)" % (e.word if e.answer == "" else e.answer))
			_list.set_item_custom_fg_color(idx, Color("ff4d5a"))
			_list.set_item_selectable(idx, false)
	_status.text = "%d mot(s)  •  grille %d × %d  •  %d isolé(s)  •  %d case(s) en conflit%s" % [
		_placed.size(), _data.grid_width, _data.grid_height, analysis.isolated.size(), analysis.conflicts.size(),
		("  •  %d non placé(s) : régénère la grille" % unplaced) if unplaced > 0 else ""]
	_preview.queue_redraw()


func _on_word_selected(idx: int) -> void:
	if idx < _placed.size():
		_preview.highlighted = _placed[idx]
		_preview.queue_redraw()


func _regenerate() -> void:
	if _data == null:
		return
	CrosswordGenerator.generate(_data)
	_data.notify_property_list_changed()
	var path := _data.resource_path
	if path != "" and not path.contains("::"):
		var err := ResourceSaver.save(_data, path)
		if err != OK:
			push_error("Échec de l'enregistrement de %s : %s" % [path, error_string(err)])
	else:
		push_warning("Mot croisé intégré à une autre ressource : enregistre la ressource parente (Ctrl+S).")
	_refresh()


# --- Glisser-déposer -------------------------------------------------------

func _can_drop_data(_pos: Vector2, drag: Variant) -> bool:
	return _from_drag(drag) != null


func _drop_data(_pos: Vector2, drag: Variant) -> void:
	open(_from_drag(drag))


func _from_drag(drag: Variant) -> CrosswordData:
	if typeof(drag) != TYPE_DICTIONARY:
		return null
	var d: Dictionary = drag
	if d.get("type") == "resource":
		return _resolve(d.get("resource"))
	if d.get("type") == "files":
		for path: String in d.get("files", []):
			if path.get_extension() in ["tres", "res"]:
				var data := _resolve(load(path))
				if data != null:
					return data
	return null


static func _resolve(res: Variant) -> CrosswordData:
	if res is CrosswordData:
		return res
	if res is LevelData and (res as LevelData).mini_game is CrosswordData:
		return (res as LevelData).mini_game
	return null
