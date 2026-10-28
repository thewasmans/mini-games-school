@tool
extends EditorPlugin
## Projet → Outils → Importer un mini-jeu (CSV)…

const MENU_ITEM := "Importer un mini-jeu (CSV)…"
const SAVE_DIR := "res://data/minigames"

var _open_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _recap: ConfirmationDialog
var _recap_text: RichTextLabel
var _pending: Resource


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM, _on_menu)

	_open_dialog = EditorFileDialog.new()
	_open_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_open_dialog.title = "Choisir un CSV (en dehors du projet)"
	_open_dialog.add_filter("*.csv", "CSV")
	_open_dialog.file_selected.connect(_on_csv_selected)
	EditorInterface.get_base_control().add_child(_open_dialog)

	_recap = ConfirmationDialog.new()
	_recap.title = "Import CSV"
	_recap.ok_button_text = "Enregistrer le .tres…"
	_recap.min_size = Vector2i(720, 560)
	_recap_text = RichTextLabel.new()
	_recap_text.bbcode_enabled = true
	_recap_text.fit_content = false
	_recap_text.scroll_active = true
	_recap.add_child(_recap_text)
	_recap.confirmed.connect(_on_recap_confirmed)
	EditorInterface.get_base_control().add_child(_recap)

	_save_dialog = EditorFileDialog.new()
	_save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.title = "Enregistrer le mini-jeu"
	_save_dialog.add_filter("*.tres", "Ressource")
	_save_dialog.file_selected.connect(_on_save_selected)
	EditorInterface.get_base_control().add_child(_save_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM)
	for d in [_open_dialog, _recap, _save_dialog]:
		if is_instance_valid(d):
			d.queue_free()


func _on_menu() -> void:
	_open_dialog.popup_file_dialog()


func _on_csv_selected(path: String) -> void:
	var project_dir := ProjectSettings.globalize_path("res://")
	var result := CsvMiniGameParser.parse(path)
	var t := ""
	if path.begins_with(project_dir):
		t += "[color=orange]⚠ Ce CSV est dans le projet : Godot risque de l'importer comme fichier de traduction. Garde-le en dehors du projet.[/color]\n\n"
	if not result.ok:
		t += "[color=red][b]Erreur :[/b] %s[/color]" % result.error
		_recap_text.text = t
		_recap.get_ok_button().disabled = true
		_recap.popup_centered()
		return
	_pending = result.resource
	var entries: Array = result.entries
	var warnings: Array = result.warnings
	t += "[b]Type détecté :[/b] %s\n" % result.kind
	t += "[b]Entrées (%d) :[/b]\n" % entries.size()
	for e in entries:
		t += "  • %s\n" % e
	if not warnings.is_empty():
		t += "\n[b]Avertissements :[/b]\n"
		for w in warnings:
			t += "  [color=orange]⚠ %s[/color]\n" % w
	_recap_text.text = t
	_recap.get_ok_button().disabled = false
	_recap.popup_centered()


func _on_recap_confirmed() -> void:
	if _pending == null:
		return
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_save_dialog.current_dir = SAVE_DIR
	_save_dialog.current_file = (_pending as MiniGameData).theme_title.to_snake_case() + ".tres"
	_save_dialog.popup_file_dialog()


func _on_save_selected(path: String) -> void:
	var err := ResourceSaver.save(_pending, path)
	if err != OK:
		push_error("Échec de l'enregistrement de %s : %s" % [path, error_string(err)])
		return
	EditorInterface.get_resource_filesystem().scan()
	var saved := load(path)
	EditorInterface.edit_resource(saved)
	print("Mini-jeu enregistré : %s. Ajoute-le à un LevelData dans data/game_data.tres." % path)
	_pending = null
