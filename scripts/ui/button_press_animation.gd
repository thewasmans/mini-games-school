class_name ButtonPressAnimation
extends RefCounted

const PUNCH_SCALE_FACTOR := 0.85
const DOWN_DURATION := 0.06
const UP_DURATION := 0.18
const DEFAULT_THEME_PATH := "res://content/theme/theme_ui.tres"
const CLICK_SOUND := preload("res://content/audios/sfx_button_click.mp3")

static func watch_default_theme_buttons(tree: SceneTree) -> void:
	tree.node_added.connect(_on_node_added)

static func _on_node_added(node: Node) -> void:
	if node is BaseButton and _uses_default_theme(node):
		attach(node)

static func _uses_default_theme(node: Node) -> bool:
	var default_theme := load(DEFAULT_THEME_PATH)
	var current = node
	while current != null:
		if current is Control and current.theme != null:
			return current.theme == default_theme
		current = current.get_parent()
	return true

static func attach(button: BaseButton) -> void:
	if button.has_meta("press_animation_attached"):
		return
	button.set_meta("press_animation_attached", true)
	var base_scale := button.scale
	button.pivot_offset = button.size * 0.5
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.button_down.connect(_animate.bind(button, base_scale * PUNCH_SCALE_FACTOR, DOWN_DURATION, Tween.TRANS_SINE))
	button.button_up.connect(_animate.bind(button, base_scale, UP_DURATION, Tween.TRANS_BACK))
	button.pressed.connect(_play_click_sound.bind(button))

static func _play_click_sound(button: BaseButton) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = CLICK_SOUND
	button.get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func _animate(button: BaseButton, target_scale: Vector2, duration: float, trans: Tween.TransitionType) -> void:
	if button.has_meta("press_tween"):
		var previous_tween: Tween = button.get_meta("press_tween")
		if previous_tween != null and previous_tween.is_valid():
			previous_tween.kill()
	var tween := button.create_tween()
	tween.tween_property(button, "scale", target_scale, duration).set_trans(trans).set_ease(Tween.EASE_OUT)
	button.set_meta("press_tween", tween)
