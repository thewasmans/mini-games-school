class_name LowPoly
extends RefCounted

const GRASS := Color("5aa846")
const GRASS_DARK := Color("3f8f3a")
const ROCK_TOP := Color("d9844a")
const ROCK_BOTTOM := Color("6b3a2a")
const STONE := Color("c9c3e3")
const STONE_DARK := Color("8f88b8")
const ROOF := Color("d9505a")
const WOOD := Color("8b5a3c")
const CLOUD := Color("e4ecff")
const PAPER := Color("fff4dc")

static var _material: StandardMaterial3D
static var _glow_material: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.95
		_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return _material


static func glow_material() -> StandardMaterial3D:
	if _glow_material == null:
		_glow_material = StandardMaterial3D.new()
		_glow_material.vertex_color_use_as_albedo = true
		_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _glow_material


static func flat(src: PrimitiveMesh, color: Color, jitter := Vector3.ZERO, noise_seed := 0.0, bottom := Color(0, 0, 0, 0), vary := 0.06) -> ArrayMesh:
	var arrays := src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var min_y := INF
	var max_y := -INF
	for v in verts:
		min_y = minf(min_y, v.y)
		max_y = maxf(max_y, v.y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in range(0, idx.size(), 3):
		var tri: Array[Vector3] = []
		for k in 3:
			var p := verts[idx[i + k]]
			tri.append(p + Vector3(_hash(p, noise_seed + 1.0), _hash(p, noise_seed + 2.0), _hash(p, noise_seed + 3.0)) * jitter)
		var centroid := (tri[0] + tri[1] + tri[2]) / 3.0
		var c := color
		if bottom.a > 0 and max_y > min_y:
			c = color.lerp(bottom, inverse_lerp(max_y, min_y, centroid.y))
		var v := _hash(centroid, noise_seed + 7.0) * vary
		c = c.lightened(v) if v > 0 else c.darkened(-v)
		st.set_color(c)
		for p in tri:
			st.add_vertex(p)
	st.generate_normals()
	return st.commit()


static func _hash(p: Vector3, k: float) -> float:
	var q := p.snappedf(0.001)
	var d := q.dot(Vector3(12.9898, 78.233, 37.719)) + k * 17.31
	return fposmod(sin(d) * 43758.5453, 1.0) * 2.0 - 1.0


static func part(mesh: Mesh, pos := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func cylinder(top: float, bottom: float, height: float, segments := 8, rings := 0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = rings
	return m


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func sphere(radius: float, segments := 7, rings := 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2
	m.radial_segments = segments
	m.rings = rings
	return m


static func island(radius: float, noise_seed: float, trees := 3) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(noise_seed * 1000.0)
	var root := Node3D.new()
	var r := radius
	root.add_child(part(flat(cylinder(r, r * 0.95, r * 0.26, 11), GRASS, Vector3(r * 0.06, r * 0.03, r * 0.06), noise_seed), Vector3.ZERO))
	root.add_child(part(flat(cylinder(r * 0.96, r * 0.1, r * 1.35, 11, 3), ROCK_TOP, Vector3(r * 0.16, r * 0.1, r * 0.16), noise_seed, ROCK_BOTTOM, 0.08),
		Vector3(0, -r * 0.8, 0)))
	for i in trees:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.35, 0.75) * r
		root.add_child(tree(rng.randf_range(0.8, 1.3) * minf(r * 0.3, 1.0), noise_seed + i, Vector3(cos(a) * d, r * 0.13, sin(a) * d)))
	for i in 2:
		var a := rng.randf() * TAU
		var rock := part(flat(sphere(r * 0.08, 5, 3), Color("a9a3bd"), Vector3.ONE * r * 0.02, noise_seed + 10 + i),
			Vector3(cos(a) * r * 0.7, r * 0.14, sin(a) * r * 0.7))
		root.add_child(rock)
	return root


static func tree(scale: float, noise_seed: float, pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale
	root.add_child(part(flat(cylinder(0.08, 0.12, 0.5, 5), WOOD, Vector3.ZERO, noise_seed), Vector3(0, 0.25, 0)))
	root.add_child(part(flat(cylinder(0.0, 0.55, 0.9, 6), GRASS_DARK, Vector3.ONE * 0.05, noise_seed), Vector3(0, 0.85, 0)))
	root.add_child(part(flat(cylinder(0.0, 0.42, 0.7, 6), GRASS_DARK.lightened(0.12), Vector3.ONE * 0.04, noise_seed + 1), Vector3(0, 1.3, 0)))
	return root


static func castle() -> Node3D:
	var root := Node3D.new()
	root.add_child(part(flat(box(Vector3(2.6, 1.4, 2.6)), STONE, Vector3.ONE * 0.03, 1.0, STONE_DARK), Vector3(0, 0.7, 0)))
	for i in 12:
		var t := float(i % 3) / 2.0 - 0.5
		var side := floori(i / 3.0)
		var p := Vector3(t * 1.6, 1.55, 1.25) if side == 0 else (Vector3(t * 1.6, 1.55, -1.25) if side == 1 else
			(Vector3(1.25, 1.55, t * 1.6) if side == 2 else Vector3(-1.25, 1.55, t * 1.6)))
		root.add_child(part(flat(box(Vector3(0.3, 0.3, 0.3)), STONE, Vector3.ZERO, 2.0 + i), p))
	for i in 4:
		var p := Vector3(1.3 if i % 2 == 0 else -1.3, 0, 1.3 if i < 2 else -1.3)
		root.add_child(part(flat(cylinder(0.42, 0.48, 2.4, 8), STONE, Vector3.ONE * 0.03, 3.0 + i, STONE_DARK), p + Vector3(0, 1.2, 0)))
		root.add_child(part(flat(cylinder(0.0, 0.62, 1.1, 8), ROOF, Vector3.ONE * 0.03, 4.0 + i), p + Vector3(0, 2.95, 0)))
	root.add_child(part(flat(cylinder(0.62, 0.7, 3.8, 8), STONE, Vector3.ONE * 0.03, 9.0, STONE_DARK), Vector3(0, 1.9, -0.2)))
	root.add_child(part(flat(cylinder(0.0, 0.88, 1.7, 8), ROOF, Vector3.ONE * 0.04, 10.0), Vector3(0, 4.65, -0.2)))
	root.add_child(part(flat(box(Vector3(0.7, 0.9, 0.1)), Color("5a3424"), Vector3.ZERO, 11.0), Vector3(0, 0.45, 1.31)))
	for p in [Vector3(0, 5.5, -0.2), Vector3(1.3, 3.5, 1.3), Vector3(-1.3, 3.5, -1.3)]:
		root.add_child(part(flat(cylinder(0.025, 0.025, 0.7, 4), WOOD), p + Vector3(0, 0.35, 0), false))
		root.add_child(part(flat(box(Vector3(0.45, 0.28, 0.03)), Color("3d84f2"), Vector3.ZERO), p + Vector3(0.24, 0.55, 0), false))
	var window := MeshInstance3D.new()
	window.mesh = flat(box(Vector3(0.18, 0.3, 0.05)), Color("ffd45c"), Vector3.ZERO, 0.0, Color(0, 0, 0, 0), 0.0)
	window.material_override = glow_material()
	window.position = Vector3(0, 2.8, 0.44)
	root.add_child(window)
	return root


static func house() -> Node3D:
	var root := Node3D.new()
	root.add_child(part(flat(box(Vector3(1.4, 1.0, 1.1)), Color("f1e3c8"), Vector3.ONE * 0.02, 20.0), Vector3(0, 0.5, 0)))
	var roof := PrismMesh.new()
	roof.size = Vector3(1.7, 0.8, 1.3)
	root.add_child(part(flat(roof, ROOF, Vector3.ONE * 0.02, 21.0), Vector3(0, 1.4, 0)))
	root.add_child(part(flat(box(Vector3(0.22, 0.5, 0.22)), Color("a9a3bd"), Vector3.ZERO, 22.0), Vector3(0.4, 1.7, 0)))
	root.add_child(part(flat(box(Vector3(0.3, 0.55, 0.05)), WOOD, Vector3.ZERO, 23.0), Vector3(-0.2, 0.28, 0.56)))
	return root


static func cloud(noise_seed: float) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(noise_seed * 100.0)
	var root := Node3D.new()
	var n := rng.randi_range(4, 6)
	for i in n:
		var r := rng.randf_range(0.8, 1.5) * (1.3 if i == floori(n / 2.0) else 1.0)
		var x := (i - (n - 1) / 2.0) * 1.1 + rng.randf_range(-0.2, 0.2)
		var mi := part(flat(sphere(r, 7, 4), CLOUD, Vector3.ONE * r * 0.12, noise_seed + i, Color(0, 0, 0, 0), 0.03),
			Vector3(x, rng.randf_range(-0.1, 0.4) + (0.4 if i == floori(n / 2.0) else 0.0), rng.randf_range(-0.4, 0.4)), false)
		mi.scale = Vector3(1, 0.75, 1)
		root.add_child(mi)
	return root


static func book(cover: Color, open: bool, halves: Array[Node3D]) -> Node3D:
	var root := Node3D.new()
	if not open:
		root.add_child(part(flat(box(Vector3(1.0, 0.2, 1.4)), cover, Vector3.ZERO), Vector3.ZERO, false))
		root.add_child(part(flat(box(Vector3(0.94, 0.16, 1.32)), PAPER, Vector3.ZERO, 0.0, Color(0, 0, 0, 0), 0.02), Vector3(0.05, 0, 0), false))
		return root
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		root.add_child(pivot)
		pivot.add_child(part(flat(box(Vector3(0.75, 0.05, 1.4)), cover, Vector3.ZERO), Vector3(s * 0.375, -0.04, 0), false))
		pivot.add_child(part(flat(box(Vector3(0.7, 0.07, 1.32)), PAPER, Vector3.ZERO, 0.0, Color(0, 0, 0, 0), 0.02), Vector3(s * 0.35, 0.02, 0), false))
		halves.append(pivot)
	return root


static func sparkle() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = flat(sphere(0.12, 4, 2), Color("fff6c4"), Vector3.ZERO, 0.0, Color(0, 0, 0, 0), 0.0)
	mi.material_override = glow_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
