extends Node
## Visite guidée automatique avec captures d'écran (vérification visuelle).
##
##   godot --path . res://tools/autoshot.tscn -- <dossier_de_sortie>

var _out := "user://shots"
var _ui: GameUI


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await _wait(0.5)
	_ui = main.get_child(0) as GameUI
	await _wait(1.6)
	await _shot("01_main")

	_ui.go_to({"screen": "study"})
	await _wait(1.5)
	await _shot("02_study")

	_ui.go_to({"screen": "year", "study": 1})
	await _wait(1.2)
	await _shot("03_years")

	_ui.go_to({"screen": "subject", "study": 1, "year": 3})
	await _wait(1.2)
	await _shot("04_subjects")

	GameState.complete_level("1/3/0", 0, 5)
	_ui.go_to({"screen": "grid", "study": 1, "year": 3, "subject": 0})
	await _wait(0.5)
	await _shot("05_grid_unlocking")
	await _wait(1.5)
	await _shot("06_grid")

	# Mots croisés : un mot juste, un mot faux
	_ui.go_to({"screen": "level", "study": 1, "year": 3, "subject": 0, "index": 0})
	await _wait(1.2)
	var cw: CrosswordUI = _find(_ui, CrosswordUI)
	for l in "NOYAU":
		cw._type(l)
	await _wait(0.3)
	var second := cw._next_open(cw._selected)
	cw._select_word(second)
	for i in (cw._words[second].cells as Array).size():
		cw._type("X")
	await _wait(0.15)
	await _shot("07_crossword")
	_ui.go_back()
	await _wait(0.6)

	# Quiz : une mauvaise réponse
	_ui.go_to({"screen": "level", "study": 1, "year": 3, "subject": 0, "index": 1})
	await _wait(1.2)
	var quiz: MemoUI = _find(_ui, MemoUI)
	quiz._on_answer(3)
	await _wait(0.6)
	await _shot("08_quiz")
	quiz._on_answer(0)
	await _wait(0.3)
	await _shot("09_quiz_good")
	_ui.go_back()
	await _wait(0.6)

	# Cryptogramme : tout rempli avec des erreurs
	_ui.go_to({"screen": "level", "study": 1, "year": 3, "subject": 0, "index": 2})
	await _wait(1.2)
	var crypto: CryptoUI = _find(_ui, CryptoUI)
	await _shot("10_crypto")
	for i in crypto._hidden.size():
		crypto._type("E" if i % 3 == 0 else TextUtil.normalize_char(crypto._cells[crypto._hidden[i]].original))
	await _wait(0.6)
	await _shot("11_crypto_errors")
	crypto._fix_errors()
	for k in crypto._hidden:
		if crypto._cells[k].state == CryptoCell.State.EMPTY:
			crypto._type(TextUtil.normalize_char(crypto._cells[k].original))
	await _wait(0.4)
	await _shot("12_crypto_solved")
	crypto._next_sentence()
	await _wait(0.5)
	for k in crypto._hidden.duplicate():
		crypto._type(TextUtil.normalize_char(crypto._cells[k].original))
	await _wait(0.3)
	crypto._next_sentence()
	await _wait(0.5)
	await _shot("13_victory")
	await _wait(1.6)
	await _shot("14_validate")

	_ui.go_to({"screen": "credits"})
	await _wait(1.3)
	await _shot("15_credits")
	get_tree().quit()


func _find(node: Node, type: Variant) -> Node:
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
		var found := _find(child, type)
		if found != null:
			return found
	return null


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("shot ", name)
