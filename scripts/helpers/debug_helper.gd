class_name DebugHelper
extends CanvasLayer

const HINT_REFRESH_INTERVAL := 0.3

@export var bar: PanelContainer
@export var auto_fill_check: CheckBox
@export var auto_validate_check: CheckBox
@export var show_hints_check: CheckBox
@export var unlock_all_button: Button
@export var hint_label: Label

var _game_manager: GameManager
var _level: Level
var _cheat: MiniGameCheat
var _hint_countdown := 0.0


func initialize(game_manager: GameManager) -> void:
	_game_manager = game_manager
	bar.theme = ThemeDB.get_default_theme()
	hint_label.hide()
	auto_fill_check.toggled.connect(_on_auto_fill_toggled)
	auto_validate_check.toggled.connect(_on_auto_validate_toggled)
	show_hints_check.toggled.connect(_on_show_hints_toggled)
	unlock_all_button.pressed.connect(game_manager.game_state.unlock_all_levels)
	game_manager.level_manager.level_started.connect(_on_level_started)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		bar.visible = not bar.visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not show_hints_check.button_pressed:
		return
	_hint_countdown -= delta
	if _hint_countdown <= 0.0:
		_hint_countdown = HINT_REFRESH_INTERVAL
		_refresh_hint()


func _on_level_started(level: Level) -> void:
	if _cheat != null:
		_cheat.cancel()
	_level = level
	_cheat = _make_cheat(level.mini_game_ui) if level.mini_game_ui != null else null
	level.validation_available.connect(_on_validation_available)
	level.tree_exited.connect(_on_level_closed.bind(level))
	_refresh_hint()
	if auto_fill_check.button_pressed:
		_start_autofill()


func _on_level_closed(level: Level) -> void:
	if level != _level:
		return
	if _cheat != null:
		_cheat.cancel()
	_level = null
	_cheat = null
	_refresh_hint()


func _on_auto_fill_toggled(on: bool) -> void:
	if on:
		_start_autofill()
	elif _cheat != null:
		_cheat.cancel()


func _on_auto_validate_toggled(on: bool) -> void:
	if on and _level != null:
		_level.validate()


func _on_show_hints_toggled(_on: bool) -> void:
	_refresh_hint()


func _on_validation_available() -> void:
	if auto_validate_check.button_pressed:
		_level.validate()


func _start_autofill() -> void:
	if _cheat == null:
		return
	_cheat.arm()
	_cheat.autofill()


func _refresh_hint() -> void:
	var hint := _cheat.hint_text() if show_hints_check.button_pressed and _cheat != null else ""
	hint_label.visible = not hint.is_empty()
	hint_label.text = "Réponse : " + hint


func _make_cheat(mini_game_ui: MiniGameUI) -> MiniGameCheat:
	if mini_game_ui is CrosswordUI:
		return CrosswordCheat.new(mini_game_ui)
	if mini_game_ui is MemoUI:
		return MemoCheat.new(mini_game_ui)
	if mini_game_ui is CryptoUI:
		return CryptoCheat.new(mini_game_ui)
	return null
