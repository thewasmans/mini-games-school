class_name UIFeedback
extends RefCounted

const TWEEN_META := &"ui_feedback_tween"
const SHAKE_OFFSETS: Array[float] = [8.0, -8.0, 6.0, -6.0, 3.0, 0.0]
const SHAKE_STEP_DURATION := 0.04
const POP_GROW_DURATION := 0.12
const POP_SHRINK_DURATION := 0.18
const POP_DURATION := POP_GROW_DURATION + POP_SHRINK_DURATION
const FLASH_FADE_DURATION := 0.35
const APPEAR_START_SCALE := 0.6
const APPEAR_DURATION := 0.3
const CONFETTI_AMOUNT := 90
const CONFETTI_LIFETIME := 1.8
const CONFETTI_COLORS: Array[Color] = [Color(1.0, 0.35, 0.35), Color(1.0, 0.8, 0.2), Color(0.4, 0.9, 0.45), Color(0.35, 0.65, 1.0), Color(0.8, 0.45, 1.0)]

static func create_tween_for(node: Control) -> Tween:
	if node.has_meta(TWEEN_META):
		var previous_tween: Tween = node.get_meta(TWEEN_META)
		if previous_tween.is_valid():
			previous_tween.kill()
	var node_size := node.size if node.size != Vector2.ZERO else node.get_combined_minimum_size()
	node.pivot_offset = node_size / 2.0
	var tween := node.create_tween()
	node.set_meta(TWEEN_META, tween)
	return tween

static func pop(node: Control, delay: float, pop_scale: float, flash_color: Color, end_color: Color) -> void:
	var tween := create_tween_for(node)
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: node.modulate = flash_color)
	tween.tween_property(node, "scale", Vector2.ONE * pop_scale, POP_GROW_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, POP_SHRINK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate", end_color, FLASH_FADE_DURATION)

static func bounce(node: Control, pop_scale: float) -> void:
	var tween := create_tween_for(node)
	tween.tween_property(node, "scale", Vector2.ONE * pop_scale, POP_GROW_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, POP_SHRINK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func appear(node: Control, delay: float) -> void:
	var tween := create_tween_for(node)
	node.scale = Vector2.ONE * APPEAR_START_SCALE
	node.modulate.a = 0.0
	tween.tween_interval(delay)
	tween.tween_property(node, "scale", Vector2.ONE, APPEAR_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 1.0, APPEAR_DURATION)

static func shake(node: Control) -> void:
	var origin_x := node.position.x
	var tween := node.create_tween()
	for shake_offset in SHAKE_OFFSETS:
		tween.tween_property(node, "position:x", origin_x + shake_offset, SHAKE_STEP_DURATION)

static func spawn_confetti(parent: Control, local_position: Vector2) -> void:
	var confetti := CPUParticles2D.new()
	confetti.amount = CONFETTI_AMOUNT
	confetti.lifetime = CONFETTI_LIFETIME
	confetti.one_shot = true
	confetti.explosiveness = 1.0
	confetti.direction = Vector2.UP
	confetti.spread = 70.0
	confetti.gravity = Vector2(0.0, 700.0)
	confetti.initial_velocity_min = 350.0
	confetti.initial_velocity_max = 650.0
	confetti.angular_velocity_min = -360.0
	confetti.angular_velocity_max = 360.0
	confetti.scale_amount_min = 6.0
	confetti.scale_amount_max = 10.0
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = PackedFloat32Array()
	gradient.colors = PackedColorArray()
	for color_index in CONFETTI_COLORS.size():
		gradient.add_point(float(color_index) / CONFETTI_COLORS.size(), CONFETTI_COLORS[color_index])
	confetti.color_initial_ramp = gradient
	confetti.position = local_position
	confetti.finished.connect(confetti.queue_free)
	parent.add_child(confetti)
	confetti.emitting = true

static func center_in(parent: Control, target: Control) -> Vector2:
	return target.global_position - parent.global_position + target.size / 2.0
