class_name Confetti
extends RefCounted
## Confettis et étincelles, dessinés sur une CanvasLayer au-dessus de tout.

const COLORS: Array[Color] = [Color("ff4d5a"), Color("ffc928"), Color("4cd964"), Color("35d0ff"), Color("b05ce0"), Color("ff9f1c"), Color("ffffff")]

static var _rect_tex: Texture2D
static var _star_tex: Texture2D


## Grande explosion de confettis depuis les deux coins du bas et pluie depuis le haut.
static func burst(from: Node) -> void:
	var layer := _layer(from)
	var size := from.get_viewport().get_visible_rect().size
	_emit(layer, Vector2(-20, size.y * 0.85), Vector2(0.55, -1), 22.0, 90, Vector2(900, 1600))
	_emit(layer, Vector2(size.x + 20, size.y * 0.85), Vector2(-0.55, -1), 22.0, 90, Vector2(900, 1600))
	var rain := _emit(layer, Vector2(size.x / 2, -30), Vector2(0, 1), 70.0, 70, Vector2(100, 450))
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(size.x / 2, 10)
	rain.explosiveness = 0.6


## Petite gerbe d'étoiles à une position globale.
static func sparkle(from: Node, global_pos: Vector2, amount := 18, color := Color("ffe066")) -> void:
	var layer := _layer(from)
	var p := CPUParticles2D.new()
	p.texture = _star()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.spread = 180.0
	p.direction = Vector2.UP
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 420.0
	p.gravity = Vector2(0, 500)
	p.damping_min = 200.0
	p.damping_max = 300.0
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.color = color
	p.position = global_pos
	layer.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func _emit(layer: CanvasLayer, pos: Vector2, dir: Vector2, spread: float, amount: int, velocity: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _rect()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 3.2
	p.explosiveness = 0.95
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = velocity.x
	p.initial_velocity_max = velocity.y
	p.gravity = Vector2(0, 1300)
	p.damping_min = 250.0
	p.damping_max = 450.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.8
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	for i in COLORS.size():
		offsets.append(float(i) / COLORS.size())
	g.offsets = offsets
	g.colors = PackedColorArray(COLORS)
	p.color_initial_ramp = g
	p.position = pos
	layer.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func _layer(from: Node) -> CanvasLayer:
	var root := from.get_tree().root
	var layer := root.get_node_or_null("ConfettiLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "ConfettiLayer"
		layer.layer = 50
		root.add_child(layer)
	return layer


static func _rect() -> Texture2D:
	if _rect_tex == null:
		var img := Image.create(10, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_rect_tex = ImageTexture.create_from_image(img)
	return _rect_tex


static func _star() -> Texture2D:
	if _star_tex == null:
		var s := 24
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		var c := Vector2(s, s) / 2.0
		for x in s:
			for y in s:
				var d := Vector2(x + 0.5, y + 0.5) - c
				# Étoile à 4 branches : |x|^0.5 + |y|^0.5 < r^0.5
				var v := sqrt(absf(d.x)) + sqrt(absf(d.y))
				var a := clampf((sqrt(s / 2.0) * 1.05 - v) * 2.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_star_tex = ImageTexture.create_from_image(img)
	return _star_tex
