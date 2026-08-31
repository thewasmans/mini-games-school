@tool
extends EditorPlugin

const MEMO_MENU_ITEM := "Importer un mémo (CSV)..."
const CRYPTO_MENU_ITEM := "Importer un crypto (CSV)..."
const MEMO_IMAGE_DIR := "res://content/sprites/memo/"

const COLOR_OK := Color(0.45, 0.82, 0.5)
const COLOR_NEUTRAL := Color(0.62, 0.62, 0.62)
const COLOR_WARN := Color(1.0, 0.62, 0.35)

var _open_file_dialog: EditorFileDialog
var _save_file_dialog: EditorFileDialog
var _report_dialog: ConfirmationDialog
var _report_panel: Control
var _resource_builder: Callable
var _pending_resource: Resource
var _pending_source_path: String
var _report: Dictionary = {}

func _enter_tree() -> void:
	add_tool_menu_item(MEMO_MENU_ITEM, _on_import_memo_pressed)
	add_tool_menu_item(CRYPTO_MENU_ITEM, _on_import_crypto_pressed)

func _exit_tree() -> void:
	remove_tool_menu_item(MEMO_MENU_ITEM)
	remove_tool_menu_item(CRYPTO_MENU_ITEM)
	if _open_file_dialog != null:
		_open_file_dialog.queue_free()
	if _save_file_dialog != null:
		_save_file_dialog.queue_free()
	if _report_dialog != null:
		_report_dialog.queue_free()

func _on_import_memo_pressed() -> void:
	_resource_builder = _build_memo_data
	_popup_open_file_dialog()

func _on_import_crypto_pressed() -> void:
	_resource_builder = _build_crypto_data
	_popup_open_file_dialog()

func _popup_open_file_dialog() -> void:
	if _open_file_dialog == null:
		_open_file_dialog = EditorFileDialog.new()
		_open_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_open_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		_open_file_dialog.add_filter("*.csv", "Fichier CSV")
		_open_file_dialog.file_selected.connect(_on_csv_selected)
		EditorInterface.get_base_control().add_child(_open_file_dialog)
	_open_file_dialog.popup_centered_ratio(0.5)

func _on_csv_selected(path: String) -> void:
	_report = {}
	_pending_source_path = path
	_pending_resource = _resource_builder.call(path)
	_popup_report_dialog()

func _popup_report_dialog() -> void:
	if _report_dialog == null:
		_report_dialog = ConfirmationDialog.new()
		_report_dialog.wrap_controls = false
		_report_dialog.confirmed.connect(_popup_save_file_dialog)
		EditorInterface.get_base_control().add_child(_report_dialog)
	if _report_panel != null:
		_report_dialog.remove_child(_report_panel)
		_report_panel.queue_free()
	_report_panel = _build_report_panel()
	_report_dialog.add_child(_report_panel)
	_report_dialog.title = "Import CSV — %s" % _pending_source_path.get_file()
	_report_dialog.dialog_text = ""
	var savable := _pending_resource != null
	_report_dialog.ok_button_text = "Enregistrer la ressource…" if savable else "Rien à enregistrer"
	_report_dialog.get_ok_button().disabled = not savable
	var editor_size := EditorInterface.get_base_control().size
	var dialog_size := Vector2i(
		clampi(int(editor_size.x * 0.5), 460, 900),
		clampi(int(editor_size.y * 0.5), 340, 680),
	)
	_report_dialog.max_size = dialog_size
	_report_dialog.popup_centered(dialog_size)

func _popup_save_file_dialog() -> void:
	if _pending_resource == null:
		return
	if _save_file_dialog == null:
		_save_file_dialog = EditorFileDialog.new()
		_save_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
		_save_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_save_file_dialog.add_filter("*.tres", "Ressource Godot")
		_save_file_dialog.file_selected.connect(_on_save_path_selected)
		EditorInterface.get_base_control().add_child(_save_file_dialog)
	_save_file_dialog.current_path = "res://data/%s.tres" % _pending_source_path.get_file().get_basename()
	_save_file_dialog.popup_centered_ratio(0.5)

func _on_save_path_selected(path: String) -> void:
	var error := ResourceSaver.save(_pending_resource, path)
	if error != OK:
		push_error("Erreur lors de la sauvegarde de la ressource (%d) : %s" % [error, path])
		return
	EditorInterface.get_resource_filesystem().scan()

func _build_report_panel() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)

	var summary := Label.new()
	summary.text = _report.get("summary", "")
	summary.add_theme_font_size_override("font_size", 15)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)

	var rows: Array = _report.get("rows", [])
	for row_index in rows.size():
		list.add_child(_build_report_row(row_index + 1, rows[row_index]))

	var errors: PackedStringArray = _report.get("errors", PackedStringArray())
	if not errors.is_empty():
		list.add_child(HSeparator.new())
		var errors_header := Label.new()
		errors_header.text = "Lignes en erreur — %d (ignorées)" % errors.size()
		errors_header.add_theme_color_override("font_color", COLOR_WARN)
		list.add_child(errors_header)
		for error_text in errors:
			var error_label := Label.new()
			error_label.text = "•  " + error_text
			error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_child(error_label)

	return root

func _build_report_row(number: int, row: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = "%d.  %s" % [number, row.get("label", "")]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(label)

	var status := Label.new()
	status.text = row.get("status", "")
	status.add_theme_color_override("font_color", row.get("color", COLOR_NEUTRAL))
	line.add_child(status)

	return line

func _read_csv_rows(csv_path: String) -> Array[PackedStringArray]:
	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir le fichier CSV : %s" % csv_path)
		return []
	var delimiter := _detect_delimiter(file.get_line())
	file.seek(0)
	var rows: Array[PackedStringArray] = []
	var is_first_row := true
	while not file.eof_reached():
		var row := file.get_csv_line(delimiter)
		if is_first_row:
			is_first_row = false
			if not row.is_empty():
				row.set(0, row[0].trim_prefix(String.chr(0xFEFF)))
		if row.size() == 1 and row[0].strip_edges().is_empty():
			continue
		rows.append(row)
	file.close()
	return rows

func _detect_delimiter(first_line: String) -> String:
	for delimiter in [";", "\t", ","]:
		if first_line.contains(delimiter):
			return delimiter
	return ","

func _build_memo_data(csv_path: String) -> MemoData:
	var rows := _read_csv_rows(csv_path)
	var questions: Array[MemoQuestionData] = []
	var report_rows: Array = []
	var errors: PackedStringArray = PackedStringArray()
	var skipped := 0
	var missing_count := 0
	for row in rows:
		var question := row[0].strip_edges() if not row.is_empty() else ""
		if row.size() < 6 or question.is_empty() or question.to_lower() == "question":
			skipped += 1
			continue
		var choices: Array[String] = []
		for column_index in range(1, 5):
			choices.append(row[column_index].strip_edges())
		var answer := row[5].strip_edges()
		var correct_choice_index := _resolve_correct_index(answer, choices)
		if correct_choice_index < 0:
			errors.append("Réponse « %s » non reconnue — %s" % [answer, _short(question)])
			continue
		var question_data := MemoQuestionData.new()
		question_data.question = question
		question_data.choices = choices
		question_data.correct_choice_index = correct_choice_index
		var image_name := row[6].strip_edges() if row.size() >= 7 else ""
		var status_text := "pas d'image"
		var status_color := COLOR_NEUTRAL
		if not image_name.is_empty():
			var texture := _load_memo_texture(image_name)
			if texture != null:
				question_data.image = texture
				status_text = "image : %s" % image_name
				status_color = COLOR_OK
			else:
				missing_count += 1
				status_text = "image manquante : %s" % image_name
				status_color = COLOR_WARN
		report_rows.append({"label": _short(question, 62), "status": status_text, "color": status_color})
		questions.append(question_data)

	var summary := "%d quiz détecté(s)" % questions.size()
	if missing_count > 0:
		summary += "   —   %d image(s) manquante(s)" % missing_count
	if skipped > 0:
		summary += "   —   %d ligne(s) ignorée(s)" % skipped
	if questions.is_empty():
		summary = "Aucun quiz valide — rien ne sera enregistré."
	_report = {"summary": summary, "rows": report_rows, "errors": errors}

	if questions.is_empty():
		return null
	var memo_data := MemoData.new()
	memo_data.questions = questions
	return memo_data

func _build_crypto_data(csv_path: String) -> CryptoData:
	var rows := _read_csv_rows(csv_path)
	var crypto_data := CryptoData.new()
	var phrases: Array[CryptoPhraseData] = []
	var report_rows: Array = []
	var skipped := 0
	var without_hint := 0
	var ratio_from_csv := false
	for row in rows:
		var text := row[0].strip_edges() if not row.is_empty() else ""
		var key := text.to_lower()
		if key == "ratio" and row.size() >= 2:
			crypto_data.hidden_letter_ratio = clampf(row[1].strip_edges().to_float(), 0.0, 1.0)
			ratio_from_csv = true
			continue
		if text.is_empty() or key in ["phrase", "texte"]:
			skipped += 1
			continue
		var phrase_data := CryptoPhraseData.new()
		phrase_data.text = text
		var hint := row[1].strip_edges() if row.size() >= 2 else ""
		phrase_data.hint = hint
		var status_text := "indice : %s" % hint if not hint.is_empty() else "pas d'indice"
		var status_color := COLOR_OK if not hint.is_empty() else COLOR_NEUTRAL
		if hint.is_empty():
			without_hint += 1
		report_rows.append({"label": _short(text, 62), "status": status_text, "color": status_color})
		phrases.append(phrase_data)

	var summary := "%d phrase(s) détectée(s)   —   masquage %d%%%s" % [
		phrases.size(),
		roundi(crypto_data.hidden_letter_ratio * 100.0),
		"" if ratio_from_csv else " (défaut)",
	]
	if without_hint > 0:
		summary += "   —   %d sans indice" % without_hint
	if phrases.is_empty():
		summary = "Aucune phrase valide — rien ne sera enregistré."
	_report = {"summary": summary, "rows": report_rows, "errors": PackedStringArray()}

	if phrases.is_empty():
		return null
	crypto_data.phrases = phrases
	return crypto_data

func _resolve_correct_index(answer: String, choices: Array[String]) -> int:
	var letter := answer.to_upper()
	if letter.length() == 1 and letter >= "A" and letter <= "D":
		return letter.unicode_at(0) - "A".unicode_at(0)
	for choice_index in choices.size():
		if choices[choice_index].to_lower() == answer.to_lower():
			return choice_index
	return -1

func _load_memo_texture(image_name: String) -> Texture2D:
	var candidates: Array[String] = []
	if image_name.begins_with("res://"):
		candidates.append(image_name)
	else:
		candidates.append(MEMO_IMAGE_DIR.path_join(image_name))
		candidates.append(MEMO_IMAGE_DIR.path_join(image_name) + ".png")
	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D
	return null

func _short(text: String, limit := 45) -> String:
	return text if text.length() <= limit else text.left(limit - 1) + "…"
