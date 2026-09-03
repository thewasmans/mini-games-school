class_name DebugHelper
extends CanvasLayer

const CHAR_INTERVAL := 0.06
const STEP_INTERVAL := 0.35
const HINT_REFRESH := 0.3
const THEME_PATH := "res://content/theme/theme_helpers.tres"
const FONT_SIZE := 10
const CHECK_ICON_MAX_WIDTH := 9
const PANEL_MARGIN := 4
const BUTTON_CONTENT_MARGIN := 1

static var instance: DebugHelper
static var auto_prefill := false
static var auto_validate := false
static var show_hints := false

var _mini_game_ui
var _cheat: MiniGameCheat
var _level: Level
var _panel: PanelContainer
var _hint_label: Label
var _ready_done := false
var _prefill_running := false
var _hint_refresh_countdown := 0.0

func _ready() -> void:
	if not OS.has_feature("editor"):
		queue_free()
		return
	instance = self
	layer = 128
	_build_ui()
	_ready_done = true

func _exit_tree() -> void:
	if instance == self:
		instance = null

func bind(mini_game_ui: Node, level: Level) -> void:
	unbind()
	_mini_game_ui = mini_game_ui
	_level = level
	level.tree_exited.connect(unbind, CONNECT_ONE_SHOT)
	if mini_game_ui.is_inside_tree():
		_activate_binding()
	else:
		mini_game_ui.tree_entered.connect(_activate_binding, CONNECT_ONE_SHOT)

func unbind() -> void:
	if is_instance_valid(_level) and _level.tree_exited.is_connected(unbind):
		_level.tree_exited.disconnect(unbind)
	if is_instance_valid(_mini_game_ui) and _mini_game_ui.is_connected("completed", _on_mini_game_completed):
		_mini_game_ui.disconnect("completed", _on_mini_game_completed)
	if _cheat != null:
		_cheat.cancel()
	_mini_game_ui = null
	_cheat = null
	_level = null
	_prefill_running = false
	_refresh_hints()

func _activate_binding() -> void:
	if not _ready_done or _mini_game_ui == null:
		return
	if not _mini_game_ui.is_connected("completed", _on_mini_game_completed):
		_mini_game_ui.connect("completed", _on_mini_game_completed)
	_cheat = _make_cheat(_mini_game_ui)
	_refresh_hints()
	if auto_prefill:
		_start_prefill()
	if auto_validate:
		_validate_if_ready()

func _input(event: InputEvent) -> void:
	if not _ready_done:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not _ready_done or not show_hints or not _hint_label.visible:
		return
	_hint_refresh_countdown -= delta
	if _hint_refresh_countdown <= 0.0:
		_hint_refresh_countdown = HINT_REFRESH
		_refresh_hints()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.theme = _compact_theme()
	_panel.visible = false
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, PANEL_MARGIN)
	_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var title := Label.new()
	title.text = "Helper (F1)"
	title.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(title)

	row.add_child(_make_toggle("Auto select / prefill", auto_prefill, _on_prefill_toggled))
	row.add_child(_make_toggle("Auto validate", auto_validate, _on_validate_toggled))
	row.add_child(_make_toggle("Show hints", show_hints, _on_hints_toggled))

	_hint_label = Label.new()
	_hint_label.visible = false
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.clip_text = true
	_hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(_hint_label)

func _compact_theme() -> Theme:
	var theme := (load(THEME_PATH) as Theme).duplicate(true) as Theme
	if not theme.has_stylebox("panel", "PanelContainer") and theme.has_stylebox("panel", "Panel"):
		theme.set_stylebox("panel", "PanelContainer", theme.get_stylebox("panel", "Panel"))
	for state in ["normal", "hover", "pressed"]:
		var box: StyleBox = theme.get_stylebox(state, "Button")
		if box != null:
			box.content_margin_top = BUTTON_CONTENT_MARGIN
			box.content_margin_bottom = BUTTON_CONTENT_MARGIN
	var default_theme := ThemeDB.get_default_theme()
	for icon_name in default_theme.get_icon_list("CheckBox"):
		theme.set_icon(icon_name, "CheckBox", default_theme.get_icon(icon_name, "CheckBox"))
	return theme

func _make_toggle(text: String, pressed: bool, handler: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = pressed
	check.add_theme_font_size_override("font_size", FONT_SIZE)
	check.add_theme_constant_override("icon_max_width", CHECK_ICON_MAX_WIDTH)
	check.add_theme_constant_override("h_separation", 4)
	check.toggled.connect(handler)
	return check

func _on_prefill_toggled(pressed: bool) -> void:
	auto_prefill = pressed
	if pressed:
		_start_prefill()
	elif _cheat != null:
		_cheat.cancel()

func _on_validate_toggled(pressed: bool) -> void:
	auto_validate = pressed
	if pressed:
		_validate_if_ready()

func _on_hints_toggled(pressed: bool) -> void:
	show_hints = pressed
	_refresh_hints()

func _refresh_hints() -> void:
	if not _ready_done:
		return
	var hint := _cheat.hint_text() if show_hints and _cheat != null else ""
	if hint.is_empty():
		_hint_label.visible = false
	else:
		_hint_label.text = "Hint : " + hint
		_hint_label.visible = true

func _start_prefill() -> void:
	if _prefill_running or _cheat == null:
		return
	var cheat := _cheat
	cheat.arm()
	_prefill_running = true
	await cheat.autofill()
	if _cheat == cheat:
		_prefill_running = false

func _on_mini_game_completed() -> void:
	_refresh_hints()
	if auto_validate:
		_validate_if_ready()

func _validate_if_ready() -> void:
	if _level != null and _level.validate_button.visible:
		_level.validate()

func _make_cheat(mini_game_ui: Node) -> MiniGameCheat:
	if mini_game_ui is CrosswordUI:
		return CrosswordCheat.new(mini_game_ui)
	if mini_game_ui is MemoUI:
		return MemoCheat.new(mini_game_ui)
	if mini_game_ui is CryptoUI:
		return CryptoCheat.new(mini_game_ui)
	return null
