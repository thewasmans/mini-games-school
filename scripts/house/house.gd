class_name House
extends Control

signal closed
signal play_requested(subject_key: Vector3i, level_index: int)

const HALL_TITLE := "Hall du grand-père"

@export var world_root: Node3D
@export var world: HouseWorld
@export var player_prefab: PackedScene
@export var back_button: JuicyButton
@export var play_button: JuicyButton
@export var room_title: Label
@export var room_counter: Pill
@export var action_points_pill: ActionPointsPill
@export var camera_drag_area: Control
@export var joystick: TouchJoystick
@export var inventory_button: JuicyButton
@export var primary_button: JuicyButton
@export var secondary_button: JuicyButton
@export var info_button: JuicyButton
@export var inventory: HouseInventory
@export var item_sign: ItemSign
@export var empty_label: Label

var player: PlayerCharacter
var carried: HousingItemData
var room: Dictionary = {}

var _game_state: GameState
var _housing_state: HousingState
var _game_data: GameData
var _home_subject := Vector3i.ZERO
var _moving := false
var _carried_key := HouseWorld.HALL_KEY
var _target_item: HousingItemData
var _target_renovation := -1
var _target_cell := Vector2i.ZERO
var _dragging := false


func _ready() -> void:
	back_button.pressed.connect(closed.emit)
	play_button.pressed.connect(_on_play_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	primary_button.pressed.connect(_on_primary_button_pressed)
	secondary_button.pressed.connect(_on_secondary_button_pressed)
	info_button.pressed.connect(_on_info_button_pressed)
	camera_drag_area.gui_input.connect(_on_camera_drag_input)
	inventory.take_requested.connect(_on_take_requested)
	inventory.play_requested.connect(_on_item_play_requested)
	item_sign.replay_requested.connect(_on_item_play_requested)
	inventory.hide()
	item_sign.hide()


func initialize(game_state: GameState, housing_state: HousingState, game_data: GameData, subject_key: Vector3i) -> void:
	_game_state = game_state
	_housing_state = housing_state
	_game_data = game_data
	_home_subject = subject_key
	var open_keys: Array[Vector3i] = []
	for key in housing_state.catalog.subject_keys():
		if game_state.completed_level_count(key.x, key.y, key.z) > 0 or housing_state.unlocked_count(key) > 0:
			open_keys.append(key)
	world.build(housing_state, open_keys)
	empty_label.visible = housing_state.catalog.subject_keys().is_empty()
	player = player_prefab.instantiate() as PlayerCharacter
	world_root.add_child(player)
	player.global_position = world.spawn_position(subject_key if open_keys.has(subject_key) else HouseWorld.HALL_KEY)
	action_points_pill.set_points(housing_state.action_points)
	housing_state.action_points_changed.connect(action_points_pill.set_points)
	_refresh_room()


func _exit_tree() -> void:
	if _housing_state != null and _housing_state.action_points_changed.is_connected(action_points_pill.set_points):
		_housing_state.action_points_changed.disconnect(action_points_pill.set_points)


func _process(_delta: float) -> void:
	if player == null:
		return
	player.move_input = joystick.direction
	var current := world.room_at(player.global_position)
	if not current.is_empty() and (room.is_empty() or current.key != room.key):
		room = current
		_refresh_room()
	_refresh_target()


func carry(item: HousingItemData, moving: bool) -> void:
	carried = item
	_moving = moving
	_carried_key = room.key


func place_carried() -> bool:
	var key := _carried_key
	var placed := _housing_state.move_item(key, carried, _target_cell) if _moving else _housing_state.place_item(key, carried, _target_cell)
	if not placed:
		return false
	_drop_carried()
	world.refresh_room(key)
	_refresh_room()
	return true


func _drop_carried() -> void:
	carried = null
	_moving = false
	world.hide_ghost()


func _refresh_room() -> void:
	var is_hall = room.is_empty() or room.key == HouseWorld.HALL_KEY
	inventory_button.visible = not is_hall
	if is_hall:
		room_title.text = HALL_TITLE
		room_counter.text = "%d pièce%s" % [_housing_state.catalog.subject_keys().size(), "s" if _housing_state.catalog.subject_keys().size() > 1 else ""]
		return
	var key: Vector3i = room.key
	room_title.text = _subject_name(key)
	room_counter.text = "%d / %d objets découverts" % [_housing_state.unlocked_count(key), _housing_state.catalog.items(key).size()]


func _refresh_target() -> void:
	var target := player.target_point()
	_target_item = null
	_target_renovation = -1
	if carried != null:
		var same_room = not room.is_empty() and room.key == _carried_key
		var cost := HousingState.MOVE_COST if _moving else HousingState.PLACE_COST
		if same_room:
			_target_cell = world.target_cell(room, carried, target)
			world.show_ghost(room, carried, _target_cell, _can_drop_here() and _housing_state.action_points >= cost)
		else:
			world.hide_ghost()
		_show_buttons("POSER (%d)" % cost, "ANNULER", false)
		return
	_target_item = world.item_at(room, target)
	if _target_item != null:
		_show_buttons("DÉPLACER (%d)" % HousingState.MOVE_COST, "RANGER (%d)" % HousingState.REMOVE_COST, true)
		return
	_target_renovation = world.renovation_at(room, target)
	if _target_renovation >= 0:
		var renovation := _housing_state.catalog.room(room.key).renovations[_target_renovation]
		_show_buttons("RÉNOVER (%d)" % renovation.cost, "", false)
		return
	_show_buttons("", "", false)


func _can_drop_here() -> bool:
	return _housing_state.can_place(_carried_key, carried, _target_cell, carried if _moving else null)


func _show_buttons(primary: String, secondary: String, info: bool) -> void:
	primary_button.visible = not primary.is_empty()
	if primary_button.text != primary:
		primary_button.text = primary
	secondary_button.visible = not secondary.is_empty()
	if secondary_button.text != secondary:
		secondary_button.text = secondary
	info_button.visible = info


func _on_primary_button_pressed() -> void:
	if carried != null:
		if room.is_empty() or room.key != _carried_key:
			_refuse("Retourne dans la bonne pièce")
		elif _housing_state.action_points < (HousingState.MOVE_COST if _moving else HousingState.PLACE_COST):
			_refuse_points()
		elif not place_carried():
			_refuse("Pas de place ici")
		else:
			Sfx.play("good")
		return
	if _target_item != null:
		if _housing_state.action_points < HousingState.MOVE_COST:
			_refuse_points()
			return
		carry(_target_item, true)
		Sfx.play("pop")
		return
	if _target_renovation >= 0:
		var key: Vector3i = room.key
		if not _housing_state.renovate(key, _target_renovation):
			_refuse_points()
			return
		world.refresh_room(key)
		Sfx.play("unlock")


func _on_secondary_button_pressed() -> void:
	if carried != null:
		_drop_carried()
		return
	if _target_item == null:
		return
	var key: Vector3i = room.key
	if not _housing_state.remove_item(key, _target_item):
		_refuse_points()
		return
	world.refresh_room(key)
	Sfx.play("pop")


func _on_info_button_pressed() -> void:
	if _target_item != null:
		item_sign.show_item(_target_item)


func _on_inventory_button_pressed() -> void:
	if room.is_empty() or room.key == HouseWorld.HALL_KEY:
		return
	inventory.show_room(room.key, _subject_name(room.key), _housing_state)


func _on_take_requested(item: HousingItemData) -> void:
	inventory.hide()
	carry(item, false)


func _on_item_play_requested(item: HousingItemData) -> void:
	var key: Vector3i = room.key if not room.is_empty() and room.key != HouseWorld.HALL_KEY else _home_subject
	play_requested.emit(key, _housing_state.level_to_play(key, item))


func _on_play_button_pressed() -> void:
	var key: Vector3i = room.key if not room.is_empty() and room.key != HouseWorld.HALL_KEY else _home_subject
	play_requested.emit(key, -1)


func _on_camera_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		player.rotate_camera(event.relative)


func _refuse_points() -> void:
	_refuse("Pas assez de points d'action : joue un level !")


func _refuse(message: String) -> void:
	Sfx.play("error")
	UIFeedback.shake(primary_button)
	UIFeedback.float_text(primary_button, message, Color.WHITE, 26)


func _subject_name(key: Vector3i) -> String:
	var subject := _game_data.get_subject(key.x, key.y, key.z)
	return subject.name if subject != null else ""
