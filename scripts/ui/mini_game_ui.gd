class_name MiniGameUI
extends Control
## Base des mini-jeux. Un mini-jeu signale sa progression (0..1) et sa réussite ;
## l'écran de level s'occupe de la barre de progression et du bouton Valider.

signal progress_changed(ratio: float)
signal completed

var is_completed := false


static func create(data: MiniGameData) -> MiniGameUI:
	var ui: MiniGameUI
	if data is CrosswordData:
		ui = CrosswordUI.new()
	elif data is MemoData:
		ui = MemoUI.new()
	elif data is CryptoData:
		ui = CryptoUI.new()
	else:
		return null
	ui.setup(data)
	return ui


func _ready() -> void:
	size_flags_vertical = SIZE_EXPAND_FILL
	GameManager.debug_changed.connect(_on_debug_changed)
	_on_debug_changed.call_deferred()


func setup(_data: MiniGameData) -> void:
	pass


## Helper F1 « Auto select / prefill ».
func debug_autofill() -> void:
	pass


## Helper F1 « Show hints ».
func set_show_hints(_on: bool) -> void:
	pass


func _on_debug_changed() -> void:
	set_show_hints(GameManager.debug_show_hints)
	if GameManager.debug_auto_fill and not is_completed:
		debug_autofill()


func _finish() -> void:
	if is_completed:
		return
	is_completed = true
	progress_changed.emit(1.0)
	Sfx.play("win")
	Confetti.burst(self)
	completed.emit()


## Délai qui ne plante pas si le mini-jeu est quitté entre-temps.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
