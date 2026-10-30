class_name AnimatedBackground
extends SubViewportContainer

const HORIZON := Color("9fd0ff")
const BOOK_COVERS: Array[Color] = [Color("b03a2e"), Color("8e5a2b"), Color("2d6cdf"), Color("7d3c98"), Color("c0392b"), Color("1e8449")]
const BOOK_Y := Vector2(-16.0, 18.0)
const CLOUD_X := 26.0

@export_group("Réglages")
## Couleur du haut du ciel : accueil, puis Primaire, Secondaire, Supérieur.
@export var sky_top_colors: Array[Color] = [Color("2b4fb3"), Color("2b4fb3"), Color("1f5aa8"), Color("4a3fb3")]
## Couleur du bas du ciel, dans le même ordre.
@export var sky_bottom_colors: Array[Color] = [Color("1d3584"), Color("1d3584"), Color("12346e"), Color("251a78")]

var _viewport: SubViewport
var _sky: ProceduralSkyMaterial
var _env: Environment
var _camera: Camera3D
var _world: Node3D
var _t := 0.0
var _floaters: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []
var _books: Array[Dictionary] = []
var _sparkles: Array[Dictionary] = []


func _init() -> void:
	stretch = true
	mouse_filter = MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	_build_environment()
	_build_scene()


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)


func set_study_level(study_level_index: int) -> void:
	set_colors(sky_top_colors[study_level_index + 1], sky_bottom_colors[study_level_index + 1])


func set_colors(top: Color, bottom: Color) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(_sky, "sky_top_color", top, 0.6)
	tw.tween_property(_sky, "sky_horizon_color", top.lerp(HORIZON, 0.65), 0.6)
	tw.tween_property(_sky, "ground_horizon_color", top.lerp(HORIZON, 0.65), 0.6)
	tw.tween_property(_sky, "ground_bottom_color", bottom, 0.6)
	tw.tween_property(_env, "fog_light_color", top.lerp(HORIZON, 0.45), 0.6)


func _build_environment() -> void:
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_top_color = Color("2b4fb3")
	_sky.sky_horizon_color = Color("2b4fb3").lerp(HORIZON, 0.65)
	_sky.ground_horizon_color = Color("2b4fb3").lerp(HORIZON, 0.65)
	_sky.ground_bottom_color = Color("1d3584")
	_sky.sky_curve = 0.12
	_sky.ground_curve = 0.3
	_sky.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = _sky
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color("e0d6eb")
	_env.ambient_light_energy = 0.7
	_env.fog_enabled = true
	_env.fog_light_color = Color("2b4fb3").lerp(HORIZON, 0.45)
	_env.fog_density = 0.024
	_env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = _env
	_world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffd99f")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	sun.rotation_degrees = Vector3(-42, 35, 0)
	_world.add_child(sun)

	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_WIDTH
	_camera.fov = 52.0
	_camera.far = 200.0
	_world.add_child(_camera)


func _build_scene() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	var main := LowPoly.island(4.2, 1.0, 4)
	var keep := LowPoly.castle()
	keep.position = Vector3(0.3, 0.55, -0.4)
	keep.scale = Vector3.ONE * 1.35
	keep.rotation_degrees.y = -25
	main.add_child(keep)
	_add_floater(main, Vector3(6.5, -2.5, -14), 0.35, 0.45, 0.0, 0.0)
	main.rotation_degrees.y = 18

	var home := LowPoly.island(2.4, 2.0, 2)
	var h := LowPoly.house()
	h.position = Vector3(-0.3, 0.3, 0.1)
	h.rotation_degrees.y = 30
	home.add_child(h)
	_add_floater(home, Vector3(-5.5, -10, -7), 0.3, 0.6, 1.0, 0.0)
	_add_floater(LowPoly.island(1.8, 3.0, 2), Vector3(6, -14, -6), 0.25, 0.7, 2.0, 0.0)
	_add_floater(LowPoly.island(2.2, 4.0, 3), Vector3(-9, 6, -28), 0.4, 0.5, 3.0, 0.0)
	_add_floater(LowPoly.island(1.6, 5.0, 1), Vector3(11, 13, -34), 0.4, 0.4, 4.0, 0.0)
	_add_floater(LowPoly.island(1.2, 6.0, 1), Vector3(-6.5, -1, -10), 0.3, 0.8, 5.0, 4.0)

	for i in 14:
		var c := LowPoly.cloud(100.0 + i)
		c.position = Vector3(rng.randf_range(-26, 26), rng.randf_range(-24, -21), rng.randf_range(-48, -22))
		c.scale = Vector3.ONE * rng.randf_range(2.0, 3.2)
		_world.add_child(c)

	for i in 7:
		var c := LowPoly.cloud(10.0 + i)
		c.position = Vector3(rng.randf_range(-CLOUD_X, CLOUD_X), rng.randf_range(5, 22), rng.randf_range(-40, -18))
		c.scale = Vector3.ONE * rng.randf_range(0.9, 1.4)
		_world.add_child(c)
		_clouds.append({"node": c, "speed": rng.randf_range(0.25, 0.6)})

	for i in 8:
		var halves: Array[Node3D] = []
		var b := LowPoly.book(BOOK_COVERS[i % BOOK_COVERS.size()], i % 2 == 0, halves)
		b.position = Vector3(rng.randf_range(-7, 7), rng.randf_range(BOOK_Y.x, BOOK_Y.y), rng.randf_range(-9, -2))
		b.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
		b.scale = Vector3.ONE * rng.randf_range(0.6, 0.9)
		_world.add_child(b)
		_books.append({"node": b, "halves": halves, "speed": rng.randf_range(0.5, 1.0), "phase": rng.randf() * TAU,
			"x": b.position.x, "spin": rng.randf_range(-0.3, 0.3)})

	for i in 30:
		var s := LowPoly.sparkle()
		s.position = Vector3(rng.randf_range(-10, 10), rng.randf_range(-14, 16), rng.randf_range(-14, -1))
		_world.add_child(s)
		_sparkles.append({"node": s, "phase": rng.randf() * TAU, "speed": rng.randf_range(1.5, 3.0)})


func _add_floater(node: Node3D, pos: Vector3, amp: float, speed: float, phase: float, spin: float) -> void:
	node.position = pos
	_world.add_child(node)
	_floaters.append({"node": node, "base": pos, "amp": amp, "speed": speed, "phase": phase, "spin": spin})


func _process(delta: float) -> void:
	_t += delta
	_camera.position = Vector3(sin(_t * 0.11) * 0.9, 1.2 + sin(_t * 0.17) * 0.4, 16)
	_camera.look_at(Vector3(sin(_t * 0.07) * 0.3, 0.5, 0))

	for f in _floaters:
		var n: Node3D = f.node
		n.position.y = f.base.y + sin(_t * f.speed + f.phase) * f.amp
		n.rotation.y += delta * deg_to_rad(f.spin)

	for c in _clouds:
		var n: Node3D = c.node
		n.position.x += delta * c.speed
		if n.position.x > CLOUD_X:
			n.position.x -= CLOUD_X * 2

	for b in _books:
		var n: Node3D = b.node
		n.position.y += delta * b.speed
		if n.position.y > BOOK_Y.y:
			n.position.y = BOOK_Y.x
		n.position.x = b.x + sin(_t * 0.4 + b.phase) * 1.2
		n.rotation.y += delta * b.spin
		n.rotation.z = sin(_t * 0.7 + b.phase) * 0.3
		var halves: Array[Node3D] = b.halves
		if halves.size() == 2:
			var flap := 0.35 + 0.3 * sin(_t * 3.0 + b.phase)
			halves[0].rotation.z = -flap
			halves[1].rotation.z = flap

	for s in _sparkles:
		var n: MeshInstance3D = s.node
		var k := 0.5 + 0.5 * sin(_t * s.speed + s.phase)
		n.scale = Vector3.ONE * (0.3 + 1.2 * k)
		n.rotation.y += delta * 2.0
