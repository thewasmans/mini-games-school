@tool
extends EditorPlugin

const MENU := "Outils du jeu"
const AUTOSHOT := "res://addons/dev_tools/autoshot/autoshot.tscn"
const EXTRACT := "res://addons/dev_tools/extract_ui_assets.py"

enum Item { THEME, FAKE_DATA, EXTRACT, EXTRACT_SPRITES, AUTOSHOT }

var _menu: PopupMenu
var _confirm: ConfirmationDialog
var _pending := -1


func _enter_tree() -> void:
	_menu = PopupMenu.new()
	_menu.add_item("Régénérer le thème (game_theme.tres)", Item.THEME)
	_menu.add_item("Régénérer les données de test (écrase game_data.tres)…", Item.FAKE_DATA)
	_menu.add_separator()
	_menu.add_item("Extraire les PNG d'UI des maquettes (Python)", Item.EXTRACT)
	_menu.add_item("Extraire les PNG d'UI + sprites détourés (Python + rembg)", Item.EXTRACT_SPRITES)
	_menu.add_separator()
	_menu.add_item("Lancer la visite automatique (captures)", Item.AUTOSHOT)
	_menu.id_pressed.connect(_on_item)
	add_tool_submenu_item(MENU, _menu)

	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(func() -> void: _run(_pending))
	EditorInterface.get_base_control().add_child(_confirm)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU)
	_confirm.queue_free()


func _on_item(id: int) -> void:
	match id:
		Item.FAKE_DATA:
			_ask(id, "Écraser data/game_data.tres et data/minigames/ avec les données de test ?")
		Item.THEME:
			_ask(id, "Régénérer content/ui/game_theme.tres ? Les retouches faites dans l'éditeur de thème seront perdues.")
		_:
			_run(id)


func _ask(id: int, text: String) -> void:
	_pending = id
	_confirm.dialog_text = text
	_confirm.popup_centered()


func _run(id: int) -> void:
	match id:
		Item.THEME:
			_report("Thème", ThemeBuilder.run())
		Item.FAKE_DATA:
			_report("Données de test", FakeDataBuilder.run())
		Item.EXTRACT, Item.EXTRACT_SPRITES:
			var args := [ProjectSettings.globalize_path(EXTRACT)]
			if id == Item.EXTRACT_SPRITES:
				args.append("--sprites")
			var output := []
			var code := OS.execute("python", args, output, true)
			print("".join(output))
			if code != 0:
				push_error("extract_ui_assets.py a échoué (code %d). Python, Pillow et numpy sont-ils installés ?" % code)
		Item.AUTOSHOT:
			print("Visite automatique : captures dans ", ProjectSettings.globalize_path("user://shots"))
			EditorInterface.play_custom_scene(AUTOSHOT)
	EditorInterface.get_resource_filesystem().scan()


func _report(what: String, err: Error) -> void:
	if err == OK:
		print("%s : régénéré." % what)
	else:
		push_error("%s : échec (%s)." % [what, error_string(err)])
