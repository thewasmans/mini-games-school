class_name MapProps
extends RefCounted

const CREAM := Color("f4ead2")
const WOOD := Color("7a4a2e")
const LEAF := Color("3f7f3a")
const STONE := Color("b9ad98")
const COPPER := Color("c8783a")
const BRASS := Color("d1a646")
const STEEL := Color("8e9bb0")
const DARK_STEEL := Color("4a5468")


static func decorate(theme: MapTheme, island: HexIsland, rng: RandomNumberGenerator, animations: MapAnimations) -> void:
	for spot_index in mini(theme.props_per_island, island.free_spots.size()):
		var prop := _prop(theme, rng, animations)
		var jitter := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2)) * island.tile_size
		prop.position = island.free_spots[spot_index] + jitter
		prop.rotation.y = rng.randf() * TAU
		prop.scale = Vector3.ONE * island.tile_size * rng.randf_range(1.4, 1.8)
		island.add_child(prop)


static func path_stone(theme: MapTheme, lit: bool) -> Mesh:
	var color := theme.lit_stone_color if lit else theme.stone_color
	match theme.style:
		MapTheme.Style.LABORATORY:
			return LowPoly.flat(LowPoly.sphere(0.17, 6, 4), color, Vector3.ZERO, 5.0, Color(0, 0, 0, 0), 0.0 if lit else 0.06)
		MapTheme.Style.MECHANICS:
			return LowPoly.flat(LowPoly.box(Vector3(0.44, 0.08, 0.44)), color, Vector3.ZERO, 5.0, Color(0, 0, 0, 0), 0.0 if lit else 0.06)
	return LowPoly.flat(LowPoly.cylinder(0.26, 0.3, 0.12, 8), color, Vector3.ONE * 0.01, 5.0, Color(0, 0, 0, 0), 0.0 if lit else 0.06)


static func start_landmark(theme: MapTheme, animations: MapAnimations) -> Node3D:
	match theme.style:
		MapTheme.Style.LABORATORY:
			return _workshop(theme, animations)
		MapTheme.Style.MECHANICS:
			return _observatory()
	return _hut()


static func end_landmark(theme: MapTheme, animations: MapAnimations) -> Node3D:
	match theme.style:
		MapTheme.Style.LABORATORY:
			return _crystal_tower(theme, animations)
		MapTheme.Style.MECHANICS:
			return _rocket()
	return _dna_tree(theme, animations)


static func bonus_landmark(theme: MapTheme, animations: MapAnimations) -> Node3D:
	match theme.style:
		MapTheme.Style.LABORATORY:
			return _cauldron(theme, animations)
		MapTheme.Style.MECHANICS:
			return _ringed_planet(theme, animations)
	return _greenhouse(theme)


static func ambience(theme: MapTheme, root: Node3D, from_z: float, to_z: float, animations: MapAnimations) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	match theme.style:
		MapTheme.Style.FOREST:
			_side_clouds(root, from_z, to_z, rng, Color("fff6ea"))
			for particle_index in theme.ambient_particles:
				var pollen := _glow(LowPoly.sphere(0.05, 4, 2), theme.particle_color, Vector3(rng.randf_range(-6, 6), rng.randf_range(0.5, 3.0), rng.randf_range(to_z, from_z)))
				root.add_child(pollen)
				animations.bob(pollen, rng.randf_range(0.2, 0.5), rng.randf_range(0.6, 1.4), rng.randf() * TAU)
		MapTheme.Style.LABORATORY:
			_side_clouds(root, from_z, to_z, rng, Color("e3d4f2"))
			for particle_index in theme.ambient_particles:
				var bubble := _glow(LowPoly.sphere(rng.randf_range(0.06, 0.14), 6, 4), theme.accent_colors[particle_index % theme.accent_colors.size()],
					Vector3(rng.randf_range(-7, 7), rng.randf_range(-4.0, -2.0), rng.randf_range(to_z, from_z)))
				root.add_child(bubble)
				animations.rise(bubble, 6.0, rng.randf_range(0.4, 0.9))
		MapTheme.Style.MECHANICS:
			for particle_index in theme.ambient_particles:
				var star := _glow(LowPoly.sphere(rng.randf_range(0.04, 0.1), 4, 2), theme.particle_color,
					Vector3(rng.randf_range(-16, 16), rng.randf_range(-14.0, -6.0), rng.randf_range(to_z - 10.0, from_z)))
				root.add_child(star)
			for planet_index in roundi((from_z - to_z) / 18.0) + 1:
				var side := -1.0 if planet_index % 2 == 0 else 1.0
				var planet := _planet(theme.accent_colors[planet_index % theme.accent_colors.size()], rng.randf_range(0.9, 1.6), planet_index % 3 == 0)
				planet.position = Vector3(side * rng.randf_range(7.5, 10.0), rng.randf_range(-5.0, -2.0), lerpf(from_z, to_z, (planet_index + 0.5) / (roundi((from_z - to_z) / 18.0) + 1)))
				root.add_child(planet)
				animations.spin(planet, Vector3.UP, rng.randf_range(0.1, 0.3))
				var moon := LowPoly.part(LowPoly.flat(LowPoly.sphere(0.25, 6, 4), STEEL, Vector3.ONE * 0.02, planet_index))
				root.add_child(moon)
				animations.orbit(moon, planet.position, rng.randf_range(2.2, 2.8), rng.randf_range(0.3, 0.6), rng.randf() * TAU)


static func _prop(theme: MapTheme, rng: RandomNumberGenerator, animations: MapAnimations) -> Node3D:
	var accent := theme.accent_colors[rng.randi_range(0, theme.accent_colors.size() - 1)]
	match theme.style:
		MapTheme.Style.LABORATORY:
			match rng.randi_range(0, 3):
				0:
					return _flask(accent, animations)
				1:
					return _tube_rack(theme, rng)
				2:
					return _crystals(accent, rng)
				_:
					return _alembic(accent, animations)
		MapTheme.Style.MECHANICS:
			match rng.randi_range(0, 3):
				0:
					return _gear(animations, rng)
				1:
					return _turbine(animations)
				2:
					return _telescope()
				_:
					return _pendulum(animations)
	match rng.randi_range(0, 3):
		0:
			return _mushroom(accent if rng.randf() < 0.5 else Color("d9473d"))
		1:
			return _fern(rng)
		2:
			return _flowers(theme, rng)
	return LowPoly.tree(1.0, rng.randf() * 10.0, Vector3.ZERO)


static func _solid(mesh: PrimitiveMesh, color: Color, at := Vector3.ZERO, jitter := 0.0, bottom := Color(0, 0, 0, 0)) -> MeshInstance3D:
	return LowPoly.part(LowPoly.flat(mesh, color, Vector3.ONE * jitter, at.length(), bottom), at)


static func _glow(mesh: PrimitiveMesh, color: Color, at := Vector3.ZERO) -> MeshInstance3D:
	var instance := LowPoly.part(LowPoly.flat(mesh, color, Vector3.ZERO, 0.0, Color(0, 0, 0, 0), 0.0), at, false)
	instance.material_override = LowPoly.glow_material()
	return instance


static func _glass(mesh: PrimitiveMesh, at := Vector3.ZERO) -> MeshInstance3D:
	var instance := LowPoly.part(LowPoly.flat(mesh, Color("e8f6ff"), Vector3.ZERO, 0.0, Color(0, 0, 0, 0), 0.0), at, false)
	instance.material_override = LowPoly.glass_material()
	return instance


static func _side_clouds(root: Node3D, from_z: float, to_z: float, rng: RandomNumberGenerator, color: Color) -> void:
	for cloud_index in roundi((from_z - to_z) / 10.0 * 1.2):
		var cloud := Node3D.new()
		var side := -1.0 if cloud_index % 2 == 0 else 1.0
		cloud.position = Vector3(side * rng.randf_range(7.0, 13.0), rng.randf_range(-7.0, -4.0), rng.randf_range(to_z, from_z))
		cloud.scale = Vector3.ONE * rng.randf_range(1.0, 1.8)
		for puff_index in rng.randi_range(4, 6):
			var radius := rng.randf_range(0.8, 1.4)
			var puff := LowPoly.part(LowPoly.flat(LowPoly.sphere(radius, 7, 4), color, Vector3.ONE * radius * 0.12, cloud_index + puff_index, Color(0, 0, 0, 0), 0.03),
				Vector3((puff_index - 2.5) * 1.1, rng.randf_range(-0.1, 0.4), rng.randf_range(-0.4, 0.4)), false)
			puff.scale = Vector3(1, 0.75, 1)
			cloud.add_child(puff)
		root.add_child(cloud)


static func _mushroom(cap_color: Color) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.cylinder(0.08, 0.11, 0.38, 6), CREAM, Vector3(0, 0.19, 0)))
	root.add_child(_solid(LowPoly.cylinder(0.05, 0.32, 0.2, 7), cap_color, Vector3(0, 0.46, 0), 0.01))
	for spot_index in 3:
		var angle := TAU * spot_index / 3.0
		root.add_child(_solid(LowPoly.sphere(0.045, 4, 2), CREAM, Vector3(cos(angle) * 0.17, 0.53, sin(angle) * 0.17)))
	return root


static func _fern(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for leaf_index in 6:
		var pivot := Node3D.new()
		pivot.rotation = Vector3(0, TAU * leaf_index / 6.0 + rng.randf_range(-0.2, 0.2), 0)
		var leaf := _solid(LowPoly.box(Vector3(0.12, 0.03, 0.55)), LEAF.lightened(rng.randf_range(0.0, 0.15)), Vector3(0, 0.2, 0.24))
		leaf.rotation.x = -0.7
		pivot.add_child(leaf)
		root.add_child(pivot)
	return root


static func _flowers(theme: MapTheme, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for flower_index in 3:
		var at := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		var height := rng.randf_range(0.3, 0.55)
		root.add_child(_solid(LowPoly.cylinder(0.02, 0.025, height, 4), LEAF, at + Vector3(0, height / 2.0, 0)))
		var petal_color := theme.accent_colors[rng.randi_range(0, theme.accent_colors.size() - 1)]
		for petal_index in 5:
			var angle := TAU * petal_index / 5.0
			root.add_child(_solid(LowPoly.sphere(0.06, 5, 3), petal_color, at + Vector3(cos(angle) * 0.08, height, sin(angle) * 0.08)))
		root.add_child(_solid(LowPoly.sphere(0.05, 5, 3), Color("ffd84a"), at + Vector3(0, height + 0.02, 0)))
	return root


static func _hut() -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.box(Vector3(1.2, 0.8, 1.0)), Color("a8784c"), Vector3(0, 0.4, 0), 0.02))
	var roof := PrismMesh.new()
	roof.size = Vector3(1.5, 0.75, 1.25)
	root.add_child(_solid(roof, Color("4f8a3a"), Vector3(0, 1.17, 0), 0.03))
	root.add_child(_solid(LowPoly.box(Vector3(0.3, 0.5, 0.05)), WOOD.darkened(0.2), Vector3(0, 0.25, 0.51)))
	root.add_child(_solid(LowPoly.box(Vector3(0.25, 0.22, 0.05)), Color("ffd45c"), Vector3(0.35, 0.5, 0.51)))
	return root


static func _dna_tree(theme: MapTheme, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	var helix := Node3D.new()
	root.add_child(helix)
	for step in 14:
		var angle := step * 0.55
		var height := 0.2 + step * 0.17
		for strand in 2:
			var offset := Vector3(cos(angle + strand * PI), 0, sin(angle + strand * PI)) * 0.32
			helix.add_child(_solid(LowPoly.sphere(0.09, 5, 3), theme.accent_colors[strand % theme.accent_colors.size()], offset + Vector3(0, height, 0)))
		var rung := _solid(LowPoly.box(Vector3(0.6, 0.04, 0.04)), CREAM, Vector3(0, height, 0))
		rung.rotation.y = -angle
		helix.add_child(rung)
	animations.spin(helix, Vector3.UP, 0.4)
	root.add_child(_solid(LowPoly.cylinder(0.1, 0.18, 2.6, 6), WOOD, Vector3(0, 1.3, 0)))
	for puff_index in 5:
		var angle := TAU * puff_index / 5.0
		root.add_child(_solid(LowPoly.sphere(0.55, 6, 4), LEAF.lightened(0.05 * puff_index), Vector3(cos(angle) * 0.45, 2.85 + (puff_index % 2) * 0.2, sin(angle) * 0.45), 0.05))
	root.add_child(_solid(LowPoly.sphere(0.6, 6, 4), LEAF.lightened(0.15), Vector3(0, 3.25, 0), 0.05))
	return root


static func _greenhouse(theme: MapTheme) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.box(Vector3(1.3, 0.12, 1.0)), STONE, Vector3(0, 0.06, 0)))
	root.add_child(_glass(LowPoly.box(Vector3(1.2, 0.7, 0.9)), Vector3(0, 0.47, 0)))
	var roof := PrismMesh.new()
	roof.size = Vector3(1.25, 0.45, 0.95)
	root.add_child(_glass(roof, Vector3(0, 1.05, 0)))
	for corner in 4:
		var at := Vector3(0.6 if corner % 2 == 0 else -0.6, 0.47, 0.45 if corner < 2 else -0.45)
		root.add_child(_solid(LowPoly.box(Vector3(0.05, 0.72, 0.05)), Color("f2f2f2"), at))
	var plants := _flowers(theme, RandomNumberGenerator.new())
	plants.position = Vector3(0, 0.12, 0)
	root.add_child(plants)
	return root


static func _flask(liquid: Color, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.sphere(0.17, 7, 4), liquid, Vector3(0, 0.19, 0)))
	root.add_child(_glass(LowPoly.sphere(0.24, 8, 5), Vector3(0, 0.24, 0)))
	root.add_child(_glass(LowPoly.cylinder(0.06, 0.07, 0.3, 6), Vector3(0, 0.58, 0)))
	var bubble := _glow(LowPoly.sphere(0.05, 4, 2), liquid.lightened(0.3), Vector3(0, 0.7, 0))
	root.add_child(bubble)
	animations.rise(bubble, 0.6, 0.5)
	return root


static func _tube_rack(theme: MapTheme, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.box(Vector3(0.6, 0.08, 0.2)), WOOD, Vector3(0, 0.04, 0)))
	root.add_child(_solid(LowPoly.box(Vector3(0.6, 0.05, 0.2)), WOOD, Vector3(0, 0.3, 0)))
	for tube_index in 3:
		var x := (tube_index - 1) * 0.18
		var liquid := theme.accent_colors[rng.randi_range(0, theme.accent_colors.size() - 1)]
		root.add_child(_solid(LowPoly.cylinder(0.045, 0.045, 0.22, 6), liquid, Vector3(x, 0.19, 0)))
		root.add_child(_glass(LowPoly.cylinder(0.06, 0.06, 0.5, 6), Vector3(x, 0.3, 0)))
	return root


static func _crystals(color: Color, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for crystal_index in 4:
		var height := rng.randf_range(0.35, 0.8)
		var crystal := _solid(LowPoly.cylinder(0.0, 0.11, height, 5), color.lightened(crystal_index * 0.08), Vector3.ZERO, 0.0, color.darkened(0.3))
		crystal.position = Vector3(rng.randf_range(-0.15, 0.15), height / 2.0, rng.randf_range(-0.15, 0.15))
		crystal.rotation = Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
		root.add_child(crystal)
	return root


static func _alembic(liquid: Color, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.sphere(0.24, 7, 4), COPPER, Vector3(0, 0.24, 0), 0.0))
	root.add_child(_solid(LowPoly.cylinder(0.05, 0.09, 0.25, 6), COPPER.darkened(0.1), Vector3(0, 0.55, 0)))
	var pipe := _solid(LowPoly.cylinder(0.03, 0.03, 0.6, 5), COPPER.lightened(0.1), Vector3(0.22, 0.58, 0))
	pipe.rotation.z = -1.0
	root.add_child(pipe)
	root.add_child(_solid(LowPoly.sphere(0.1, 6, 4), liquid, Vector3(0.48, 0.12, 0)))
	root.add_child(_glass(LowPoly.sphere(0.14, 7, 4), Vector3(0.48, 0.14, 0)))
	var steam := _glow(LowPoly.sphere(0.06, 4, 2), Color("f4ecff"), Vector3(0, 0.7, 0))
	root.add_child(steam)
	animations.rise(steam, 0.7, 0.4)
	return root


static func _workshop(theme: MapTheme, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.box(Vector3(1.3, 0.9, 1.0)), STONE, Vector3(0, 0.45, 0), 0.02))
	var roof := PrismMesh.new()
	roof.size = Vector3(1.55, 0.6, 1.2)
	root.add_child(_solid(roof, Color("7a3f8f"), Vector3(0, 1.2, 0), 0.03))
	root.add_child(_solid(LowPoly.box(Vector3(0.25, 0.7, 0.25)), STONE.darkened(0.2), Vector3(0.4, 1.4, 0)))
	root.add_child(_solid(LowPoly.box(Vector3(0.3, 0.5, 0.05)), WOOD, Vector3(-0.2, 0.25, 0.51)))
	root.add_child(_solid(LowPoly.box(Vector3(0.3, 0.25, 0.05)), theme.accent_colors[0], Vector3(0.3, 0.55, 0.51)))
	for puff_index in 3:
		var smoke := _solid(LowPoly.sphere(0.16, 5, 3), Color("e7e0ef"), Vector3(0.4 + puff_index * 0.05, 1.8, 0))
		root.add_child(smoke)
		animations.rise(smoke, 1.2, 0.35 + puff_index * 0.05)
	return root


static func _crystal_tower(theme: MapTheme, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.cylinder(0.75, 0.9, 0.5, 6), STONE, Vector3(0, 0.25, 0), 0.02, STONE.darkened(0.3)))
	var cluster := Node3D.new()
	root.add_child(cluster)
	for crystal_index in 7:
		var color := theme.accent_colors[crystal_index % theme.accent_colors.size()]
		var height := 2.6 if crystal_index == 0 else 1.0 + (crystal_index % 3) * 0.35
		var crystal := _solid(LowPoly.cylinder(0.0, 0.32 if crystal_index == 0 else 0.18, height, 5), color, Vector3.ZERO, 0.0, color.darkened(0.35))
		var angle := TAU * crystal_index / 6.0
		var spread := 0.0 if crystal_index == 0 else 0.4
		crystal.position = Vector3(cos(angle) * spread, 0.5 + height / 2.0, sin(angle) * spread)
		crystal.rotation = Vector3(sin(angle) * 0.35 * spread * 2.5, 0, -cos(angle) * 0.35 * spread * 2.5)
		cluster.add_child(crystal)
	var core := _glow(LowPoly.sphere(0.2, 6, 4), theme.particle_color, Vector3(0, 3.4, 0))
	root.add_child(core)
	animations.bob(core, 0.15, 1.5)
	return root


static func _cauldron(theme: MapTheme, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	for leg in 3:
		var angle := TAU * leg / 3.0
		root.add_child(_solid(LowPoly.cylinder(0.04, 0.04, 0.3, 4), DARK_STEEL, Vector3(cos(angle) * 0.3, 0.15, sin(angle) * 0.3)))
	root.add_child(_solid(LowPoly.sphere(0.5, 8, 5), Color("2f3445"), Vector3(0, 0.6, 0), 0.0))
	root.add_child(_solid(LowPoly.cylinder(0.46, 0.46, 0.08, 8), Color("2f3445"), Vector3(0, 0.98, 0)))
	var potion := theme.accent_colors[1 % theme.accent_colors.size()]
	root.add_child(_glow(LowPoly.cylinder(0.4, 0.4, 0.04, 8), potion, Vector3(0, 1.0, 0)))
	for bubble_index in 4:
		var bubble := _glow(LowPoly.sphere(0.07, 4, 2), potion.lightened(0.3), Vector3((bubble_index - 1.5) * 0.15, 1.05, 0))
		root.add_child(bubble)
		animations.rise(bubble, 0.8, 0.4 + bubble_index * 0.1)
	return root


static func _gear(animations: MapAnimations, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.box(Vector3(0.12, 0.5, 0.12)), DARK_STEEL, Vector3(0, 0.25, 0)))
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.5, 0)
	pivot.rotation.x = PI / 2.0
	root.add_child(pivot)
	var color := BRASS if rng.randf() < 0.5 else COPPER
	pivot.add_child(_solid(LowPoly.cylinder(0.32, 0.32, 0.08, 12), color, Vector3.ZERO))
	pivot.add_child(_solid(LowPoly.cylinder(0.09, 0.09, 0.12, 6), DARK_STEEL, Vector3.ZERO))
	for tooth in 10:
		var angle := TAU * tooth / 10.0
		var tooth_mesh := _solid(LowPoly.box(Vector3(0.1, 0.08, 0.12)), color.darkened(0.1), Vector3(cos(angle), 0, sin(angle)) * 0.36)
		tooth_mesh.rotation.y = -angle
		pivot.add_child(tooth_mesh)
	animations.spin(pivot, Vector3.UP, rng.randf_range(0.5, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0))
	return root


static func _turbine(animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.cylinder(0.03, 0.06, 1.1, 5), Color("eef1f6"), Vector3(0, 0.55, 0)))
	var rotor := Node3D.new()
	rotor.position = Vector3(0, 1.1, 0.06)
	root.add_child(rotor)
	rotor.add_child(_solid(LowPoly.sphere(0.06, 5, 3), STEEL, Vector3.ZERO))
	for blade in 3:
		var arm := Node3D.new()
		arm.rotation.z = TAU * blade / 3.0
		arm.add_child(_solid(LowPoly.box(Vector3(0.07, 0.5, 0.02)), Color("eef1f6"), Vector3(0, 0.27, 0)))
		rotor.add_child(arm)
	animations.spin(rotor, Vector3.BACK, 2.0)
	return root


static func _telescope() -> Node3D:
	var root := Node3D.new()
	for leg in 3:
		var angle := TAU * leg / 3.0
		var tripod := _solid(LowPoly.cylinder(0.02, 0.02, 0.6, 4), WOOD, Vector3(cos(angle) * 0.12, 0.28, sin(angle) * 0.12))
		tripod.rotation = Vector3(sin(angle) * 0.35, 0, -cos(angle) * 0.35)
		root.add_child(tripod)
	var tube := _solid(LowPoly.cylinder(0.07, 0.1, 0.7, 7), BRASS, Vector3(0, 0.66, 0))
	tube.rotation.x = 0.9
	root.add_child(tube)
	return root


static func _pendulum(animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	for side: float in [-1.0, 1.0]:
		root.add_child(_solid(LowPoly.box(Vector3(0.06, 0.9, 0.06)), WOOD, Vector3(side * 0.3, 0.45, 0)))
	root.add_child(_solid(LowPoly.box(Vector3(0.7, 0.06, 0.06)), WOOD, Vector3(0, 0.9, 0)))
	var arm := Node3D.new()
	arm.position = Vector3(0, 0.88, 0)
	root.add_child(arm)
	arm.add_child(_solid(LowPoly.cylinder(0.012, 0.012, 0.6, 4), STEEL, Vector3(0, -0.3, 0)))
	arm.add_child(_solid(LowPoly.sphere(0.09, 6, 4), BRASS, Vector3(0, -0.62, 0)))
	animations.swing(arm, 0.5, 2.2)
	return root


static func _observatory() -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.cylinder(0.7, 0.75, 0.9, 10), Color("dfe4ee"), Vector3(0, 0.45, 0), 0.01, STEEL))
	var dome := _solid(LowPoly.sphere(0.72, 10, 6), STEEL.lightened(0.2), Vector3(0, 0.9, 0))
	root.add_child(dome)
	root.add_child(_solid(LowPoly.box(Vector3(0.22, 0.7, 0.3)), DARK_STEEL, Vector3(0, 1.3, 0.5)))
	var scope := _solid(LowPoly.cylinder(0.08, 0.1, 0.8, 6), BRASS, Vector3(0, 1.6, 0.55))
	scope.rotation.x = 0.7
	root.add_child(scope)
	root.add_child(_solid(LowPoly.box(Vector3(0.3, 0.45, 0.05)), WOOD, Vector3(0, 0.22, 0.73)))
	return root


static func _rocket() -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.cylinder(0.9, 1.0, 0.2, 8), DARK_STEEL, Vector3(0, 0.1, 0)))
	root.add_child(_solid(LowPoly.cylinder(0.35, 0.4, 2.0, 10), Color("f2f2f5"), Vector3(0, 1.3, 0), 0.0, Color("c9ced8")))
	root.add_child(_solid(LowPoly.cylinder(0.0, 0.36, 0.8, 10), Color("e2533f"), Vector3(0, 2.7, 0)))
	root.add_child(_glow(LowPoly.cylinder(0.14, 0.14, 0.05, 8), Color("7fd6ff"), Vector3(0, 1.8, 0.37)))
	for fin in 3:
		var pivot := Node3D.new()
		pivot.rotation.y = TAU * fin / 3.0
		pivot.add_child(_solid(LowPoly.box(Vector3(0.05, 0.6, 0.4)), Color("e2533f"), Vector3(0, 0.6, 0.48)))
		root.add_child(pivot)
	root.add_child(_solid(LowPoly.box(Vector3(0.12, 2.6, 0.12)), STEEL, Vector3(0.75, 1.4, 0)))
	return root


static func _ringed_planet(theme: MapTheme, animations: MapAnimations) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.cylinder(0.08, 0.12, 0.9, 5), DARK_STEEL, Vector3(0, 0.45, 0)))
	var planet := _planet(theme.accent_colors[0], 0.55, true)
	planet.position = Vector3(0, 1.35, 0)
	root.add_child(planet)
	animations.spin(planet, Vector3.UP, 0.6)
	var moon := _solid(LowPoly.sphere(0.13, 6, 4), STEEL.lightened(0.2), Vector3.ZERO)
	root.add_child(moon)
	animations.orbit(moon, Vector3(0, 1.35, 0), 1.05, 1.2)
	return root


static func _planet(color: Color, radius: float, ringed: bool) -> Node3D:
	var root := Node3D.new()
	root.add_child(_solid(LowPoly.sphere(radius, 10, 6), color, Vector3.ZERO, radius * 0.04, color.darkened(0.35)))
	if ringed:
		var ring := TorusMesh.new()
		ring.inner_radius = radius * 1.3
		ring.outer_radius = radius * 1.65
		ring.rings = 16
		ring.ring_segments = 4
		var ring_instance := _solid(ring, Color("f3d9a4"), Vector3.ZERO)
		ring_instance.scale = Vector3(1, 0.15, 1)
		ring_instance.rotation.z = 0.35
		root.add_child(ring_instance)
	return root
