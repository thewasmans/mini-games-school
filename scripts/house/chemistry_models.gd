class_name ChemistryModels
extends RefCounted

const BRASS := Color("d9a441")
const METAL := Color("b8c0cc")
const METAL_DARK := Color("6b7385")
const WOOD_LIGHT := Color("b07a4a")
const RED := Color("e2533f")
const BLUE := Color("3d84f2")
const WHITE := Color("f5f2ea")
const BLACK := Color("2b2d35")
const YELLOW := Color("ffd23f")
const GREEN := Color("4cc24a")
const ORANGE := Color("ff9a1f")
const PINK := Color("f29bb0")
const WATER := Color("6ec6ff")
const ATOM_COLORS: Array[Color] = [Color("e2533f"), Color("f5f2ea"), Color("2b2d35"), Color("ffd23f")]


static func build(word: String) -> Node3D:
	match word:
		"NOMENCLATURE":
			return _apothecary_cabinet()
		"BINAIRE":
			return _chandelier(2)
		"TERNAIRE":
			return _chandelier(3)
		"QUATERNAIRE":
			return _chandelier(4)
		"ISOTOPE":
			return _matryoshkas()
		"ACTEUR":
			return _theatre_stage()
		"SPECTATEUR":
			return _armchair()
		"IONIQUE":
			return _fridge()
		"SIGNIFICATIFS":
			return _precision_scale()
		"MOLE":
			return _mole_plush()
		"AVOGADRO":
			return _avogadro_portrait()
		"STOECHIOMETRIE":
			return _balance()
		"CNTP":
			return _weather_instruments()
		"DENSITE":
			return _lava_lamp()
		"AQUEUSE":
			return _aquarium()
		"DILUTION":
			return _syrup_carafe()
		"SOLUBILITE":
			return _tea_cup()
		"PRECIPITATION":
			return _snow_globe()
		"ELECTROLYTE":
			return _lemon_battery()
		"ELECTROLYSE":
			return _electrolysis()
		"CONDUCTIBILITE":
			return _string_lights()
	return null


static func _apothecary_cabinet() -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(1.7, 1.3, 0.55)), LowPoly.WOOD, Vector3(0, 0.75, -0.1), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(1.82, 0.12, 0.65)), LowPoly.WOOD.darkened(0.2), Vector3(0, 1.46, -0.1), Vector3.ZERO, 2.0)
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.box(Vector3(0.12, 0.1, 0.12)), LowPoly.WOOD.darkened(0.3), Vector3(0.75 * side, 0.05, 0.08), Vector3.ZERO, 3.0)
	for row in 3:
		for column in 5:
			var at := Vector3(-0.64 + column * 0.32, 0.38 + row * 0.38, 0.19)
			_add(root, LowPoly.box(Vector3(0.28, 0.32, 0.04)), WOOD_LIGHT, at, Vector3.ZERO, 4.0 + row * 5 + column)
			_add(root, LowPoly.box(Vector3(0.16, 0.07, 0.02)), LowPoly.PAPER, at + Vector3(0, 0.07, 0.03), Vector3.ZERO, 30.0)
			_add(root, LowPoly.sphere(0.025, 5, 3), BRASS, at + Vector3(0, -0.06, 0.04), Vector3.ZERO, 31.0)
	return root


static func _chandelier(atom_count: int) -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.cylinder(0.12, 0.12, 0.05, 8), BRASS, Vector3(0, -0.03, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.cylinder(0.02, 0.02, 0.55, 5), METAL_DARK, Vector3(0, -0.3, 0), Vector3.ZERO, 2.0)
	_add(root, LowPoly.sphere(0.14, 8, 5), BRASS, Vector3(0, -0.62, 0), Vector3.ZERO, 3.0)
	_glow(root, LowPoly.sphere(0.07, 6, 4), YELLOW, Vector3(0, -0.76, 0))
	var arm_length := 0.55
	for index in atom_count:
		var angle := TAU * index / atom_count + PI / 2
		var direction := Vector3(cos(angle), -0.18, -sin(angle))
		_add(root, LowPoly.box(Vector3(arm_length, 0.04, 0.04)), BRASS, Vector3(0, -0.62, 0) + direction * arm_length / 2, Vector3(0, angle, -0.18), 4.0 + index)
		_add(root, LowPoly.sphere(0.17, 8, 5), ATOM_COLORS[index % ATOM_COLORS.size()], Vector3(0, -0.62, 0) + direction * arm_length, Vector3.ZERO, 10.0 + index)
	return root


static func _matryoshkas() -> Node3D:
	var root := _small_table(0.75, 0.55)
	var sizes: Array[float] = [1.0, 0.78, 0.58]
	var x := -0.2
	for size in sizes:
		var base := Vector3(x, 0.55, 0)
		_add(root, LowPoly.cylinder(0.09 * size, 0.12 * size, 0.24 * size, 8), RED, base + Vector3(0, 0.12 * size, 0), Vector3.ZERO, 1.0)
		_add(root, LowPoly.sphere(0.1 * size, 8, 5), RED, base + Vector3(0, 0.3 * size, 0), Vector3.ZERO, 2.0)
		_add(root, LowPoly.sphere(0.065 * size, 6, 4), Color("f2c29b"), base + Vector3(0, 0.3 * size, 0.05 * size), Vector3.ZERO, 3.0)
		_add(root, LowPoly.box(Vector3(0.14, 0.04, 0.02) * size), YELLOW, base + Vector3(0, 0.12 * size, 0.11 * size), Vector3.ZERO, 4.0)
		x += 0.22 * size + 0.04
	return root


static func _theatre_stage() -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(1.8, 0.3, 0.8)), LowPoly.WOOD, Vector3(0, 0.15, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(1.82, 0.05, 0.82)), WOOD_LIGHT, Vector3(0, 0.32, 0), Vector3.ZERO, 2.0)
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.box(Vector3(0.1, 1.5, 0.1)), LowPoly.WOOD.darkened(0.2), Vector3(0.85 * side, 1.05, -0.32), Vector3.ZERO, 3.0)
		_add(root, LowPoly.box(Vector3(0.36, 1.3, 0.12)), Color("b3263a"), Vector3(0.66 * side, 1.0, -0.26), Vector3(0, 0, 0.05 * side), 4.0)
	_add(root, LowPoly.box(Vector3(1.8, 0.24, 0.14)), Color("b3263a"), Vector3(0, 1.72, -0.28), Vector3.ZERO, 5.0)
	_add(root, LowPoly.box(Vector3(0.04, 0.55, 0.04)), METAL_DARK, Vector3(0, 0.6, 0), Vector3.ZERO, 6.0)
	var mask := _add(root, LowPoly.sphere(0.2, 8, 5), WHITE, Vector3(0, 0.95, 0.02), Vector3.ZERO, 7.0)
	mask.scale = Vector3(1, 1.15, 0.45)
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.sphere(0.04, 5, 3), BLACK, Vector3(0.07 * side, 1.0, 0.1), Vector3.ZERO, 8.0)
	_add(root, LowPoly.box(Vector3(0.12, 0.03, 0.02)), RED, Vector3(0, 0.86, 0.1), Vector3.ZERO, 9.0)
	return root


static func _armchair() -> Node3D:
	var root := Node3D.new()
	var fabric := Color("c0392b")
	_add(root, LowPoly.box(Vector3(0.7, 0.35, 0.65)), fabric, Vector3(0, 0.28, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(0.7, 0.7, 0.16)), fabric, Vector3(0, 0.7, -0.26), Vector3(-0.1, 0, 0), 2.0)
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.box(Vector3(0.14, 0.5, 0.62)), fabric.darkened(0.12), Vector3(0.34 * side, 0.36, 0), Vector3.ZERO, 3.0)
		_add(root, LowPoly.box(Vector3(0.08, 0.12, 0.08)), LowPoly.WOOD, Vector3(0.28 * side, 0.06, 0.24), Vector3.ZERO, 4.0)
	_add(root, LowPoly.cylinder(0.11, 0.08, 0.22, 8), WHITE, Vector3(0.05, 0.57, 0.08), Vector3.ZERO, 5.0)
	_add(root, LowPoly.cylinder(0.112, 0.112, 0.05, 8), RED, Vector3(0.05, 0.64, 0.08), Vector3.ZERO, 6.0)
	for index in 6:
		var angle := TAU * index / 6
		_add(root, LowPoly.sphere(0.045, 5, 3), Color("fff1b8"), Vector3(0.05 + cos(angle) * 0.06, 0.7, 0.08 + sin(angle) * 0.06), Vector3.ZERO, 7.0 + index)
	return root


static func _fridge() -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(0.72, 1.55, 0.62)), Color("e8f1f8"), Vector3(0, 0.78, -0.12), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(0.7, 0.02, 0.02)), METAL_DARK, Vector3(0, 1.05, 0.2), Vector3.ZERO, 2.0)
	_add(root, LowPoly.box(Vector3(0.04, 0.3, 0.05)), METAL, Vector3(0.28, 1.28, 0.22), Vector3.ZERO, 3.0)
	_add(root, LowPoly.box(Vector3(0.04, 0.4, 0.05)), METAL, Vector3(0.28, 0.7, 0.22), Vector3.ZERO, 4.0)
	_add(root, LowPoly.box(Vector3(0.16, 0.04, 0.03)), RED, Vector3(-0.15, 1.3, 0.2), Vector3.ZERO, 5.0)
	_add(root, LowPoly.box(Vector3(0.04, 0.16, 0.03)), RED, Vector3(-0.15, 1.3, 0.2), Vector3.ZERO, 6.0)
	_add(root, LowPoly.box(Vector3(0.16, 0.04, 0.03)), BLUE, Vector3(-0.15, 0.95, 0.2), Vector3.ZERO, 7.0)
	_add(root, LowPoly.box(Vector3(0.1, 0.1, 0.03)), YELLOW, Vector3(0.05, 0.6, 0.2), Vector3(0, 0, 0.3), 8.0)
	return root


static func _precision_scale() -> Node3D:
	var root := _small_table(0.7, 0.75)
	_add(root, LowPoly.box(Vector3(0.42, 0.08, 0.36)), METAL, Vector3(0, 0.8, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(0.3, 0.06, 0.04)), BLACK, Vector3(0, 0.81, 0.18), Vector3(-0.4, 0, 0), 2.0)
	_glow(root, LowPoly.box(Vector3(0.22, 0.03, 0.01)), Color("7be86a"), Vector3(0, 0.82, 0.2))
	_add(root, LowPoly.cylinder(0.14, 0.14, 0.02, 10), METAL.lightened(0.2), Vector3(0, 0.86, -0.04), Vector3.ZERO, 3.0)
	_add(root, LowPoly.cylinder(0.03, 0.035, 0.06, 6), BRASS, Vector3(0, 0.9, -0.04), Vector3.ZERO, 4.0)
	return root


static func _mole_plush() -> Node3D:
	var root := Node3D.new()
	var fur := Color("5a4a42")
	_add(root, LowPoly.cylinder(0.32, 0.34, 0.1, 8), Color("7a9ed6"), Vector3(0, 0.05, 0), Vector3.ZERO, 1.0)
	var body := _add(root, LowPoly.sphere(0.24, 8, 5), fur, Vector3(0, 0.32, 0), Vector3.ZERO, 2.0)
	body.scale = Vector3(1, 1.1, 0.9)
	_add(root, LowPoly.sphere(0.17, 8, 5), fur, Vector3(0, 0.62, 0.02), Vector3.ZERO, 3.0)
	_add(root, LowPoly.cylinder(0.04, 0.07, 0.12, 6), PINK, Vector3(0, 0.6, 0.18), Vector3(PI / 2, 0, 0), 4.0)
	_add(root, LowPoly.sphere(0.035, 5, 3), Color("d9627f"), Vector3(0, 0.6, 0.25), Vector3.ZERO, 5.0)
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.sphere(0.025, 4, 3), BLACK, Vector3(0.07 * side, 0.68, 0.13), Vector3.ZERO, 6.0)
		_add(root, LowPoly.sphere(0.07, 6, 4), PINK, Vector3(0.18 * side, 0.36, 0.14), Vector3.ZERO, 7.0)
		_add(root, LowPoly.sphere(0.08, 6, 4), PINK, Vector3(0.12 * side, 0.12, 0.17), Vector3.ZERO, 8.0)
	return root


static func _avogadro_portrait() -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(0.9, 1.5, 0.08)), BRASS, Vector3(0, 0.85, 0.04), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(0.74, 1.08, 0.06)), Color("3f5a7a"), Vector3(0, 0.98, 0.07), Vector3.ZERO, 2.0)
	_add(root, LowPoly.box(Vector3(0.44, 0.42, 0.04)), BLACK, Vector3(0, 0.72, 0.1), Vector3.ZERO, 3.0)
	_add(root, LowPoly.box(Vector3(0.12, 0.12, 0.02)), WHITE, Vector3(0, 0.86, 0.12), Vector3.ZERO, 4.0)
	_add(root, LowPoly.sphere(0.15, 8, 5), Color("f2c29b"), Vector3(0, 1.08, 0.12), Vector3.ZERO, 5.0)
	_add(root, LowPoly.sphere(0.16, 8, 4), Color("e8e4dc"), Vector3(0, 1.16, 0.08), Vector3.ZERO, 6.0)
	_add(root, LowPoly.box(Vector3(0.62, 0.2, 0.03)), LowPoly.PAPER, Vector3(0, 0.27, 0.1), Vector3.ZERO, 7.0)
	_label(root, "6,02 × 10²³", Vector3(0, 0.27, 0.12), 40)
	return root


static func _balance() -> Node3D:
	var root := _small_table(1.6, 0.65)
	_add(root, LowPoly.box(Vector3(0.3, 0.06, 0.24)), BRASS, Vector3(0, 0.68, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.cylinder(0.03, 0.04, 0.7, 6), BRASS, Vector3(0, 1.0, 0), Vector3.ZERO, 2.0)
	_add(root, LowPoly.box(Vector3(1.2, 0.04, 0.04)), BRASS, Vector3(0, 1.34, 0), Vector3.ZERO, 3.0)
	_add(root, LowPoly.sphere(0.05, 6, 4), BRASS, Vector3(0, 1.38, 0), Vector3.ZERO, 4.0)
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.box(Vector3(0.015, 0.4, 0.015)), METAL_DARK, Vector3(0.58 * side, 1.14, 0), Vector3.ZERO, 5.0)
		_add(root, LowPoly.cylinder(0.2, 0.16, 0.04, 10), BRASS, Vector3(0.58 * side, 0.94, 0), Vector3.ZERO, 6.0)
		for index in 3:
			_add(root, LowPoly.sphere(0.05, 6, 4), ATOM_COLORS[index], Vector3(0.58 * side + (index - 1) * 0.09, 1.0, 0), Vector3.ZERO, 7.0 + index)
	return root


static func _weather_instruments() -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(0.24, 0.8, 0.05)), WOOD_LIGHT, Vector3(-0.5, 0.45, 0.03), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(0.05, 0.6, 0.03)), WHITE, Vector3(-0.5, 0.48, 0.07), Vector3.ZERO, 2.0)
	_add(root, LowPoly.box(Vector3(0.03, 0.32, 0.03)), RED, Vector3(-0.5, 0.34, 0.09), Vector3.ZERO, 3.0)
	_add(root, LowPoly.sphere(0.05, 6, 4), RED, Vector3(-0.5, 0.16, 0.08), Vector3.ZERO, 4.0)
	_label(root, "0 °C", Vector3(-0.5, 0.92, 0.07), 32)
	_add(root, LowPoly.cylinder(0.32, 0.32, 0.08, 12), BRASS, Vector3(0.4, 0.5, 0.04), Vector3(PI / 2, 0, 0), 5.0)
	_add(root, LowPoly.cylinder(0.26, 0.26, 0.04, 12), WHITE, Vector3(0.4, 0.5, 0.09), Vector3(PI / 2, 0, 0), 6.0)
	_add(root, LowPoly.box(Vector3(0.03, 0.22, 0.02)), BLACK, Vector3(0.45, 0.56, 0.12), Vector3(0, 0, -0.5), 7.0)
	_add(root, LowPoly.sphere(0.03, 5, 3), BLACK, Vector3(0.4, 0.5, 0.12), Vector3.ZERO, 8.0)
	_label(root, "101,3 kPa", Vector3(0.4, 0.92, 0.07), 32)
	return root


static func _lava_lamp() -> Node3D:
	var root := _small_table(0.5, 0.45)
	_add(root, LowPoly.cylinder(0.08, 0.14, 0.2, 8), METAL_DARK, Vector3(0, 0.55, 0), Vector3.ZERO, 1.0)
	_glass(root, LowPoly.cylinder(0.11, 0.08, 0.6, 8), Color("ff6fa8"), Vector3(0, 0.95, 0))
	for blob in [Vector3(0, 0.75, 0), Vector3(0.02, 1.02, 0.01), Vector3(-0.02, 1.15, 0)]:
		_glow(root, LowPoly.sphere(0.05 if blob.y > 0.9 else 0.07, 6, 4), ORANGE, blob)
	_add(root, LowPoly.cylinder(0.05, 0.11, 0.12, 8), METAL_DARK, Vector3(0, 1.31, 0), Vector3.ZERO, 3.0)
	return root


static func _aquarium() -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(1.7, 0.6, 0.6)), LowPoly.WOOD, Vector3(0, 0.3, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.box(Vector3(1.6, 0.08, 0.5)), Color("d8c49a"), Vector3(0, 0.64, 0), Vector3.ZERO, 2.0)
	_glass(root, LowPoly.box(Vector3(1.6, 0.62, 0.5)), WATER, Vector3(0, 0.95, 0))
	_add(root, LowPoly.box(Vector3(1.64, 0.05, 0.54)), METAL_DARK, Vector3(0, 1.28, 0), Vector3.ZERO, 3.0)
	for index in 4:
		_add(root, LowPoly.cylinder(0.015, 0.03, 0.3 + index * 0.05, 4), GREEN, Vector3(-0.6 + index * 0.08, 0.83, -0.1), Vector3(0, 0, 0.1 * (index - 2)), 4.0 + index)
	for fish in [Vector3(-0.1, 0.95, 0.05), Vector3(0.35, 1.08, -0.05), Vector3(0.55, 0.85, 0.08)]:
		var fish_body := _add(root, LowPoly.sphere(0.06, 6, 4), ORANGE, fish, Vector3.ZERO, 10.0)
		fish_body.scale = Vector3(1.4, 1, 0.7)
		_add(root, LowPoly.box(Vector3(0.05, 0.08, 0.02)), ORANGE.darkened(0.2), fish + Vector3(-0.1, 0, 0), Vector3.ZERO, 11.0)
	return root


static func _syrup_carafe() -> Node3D:
	var root := _small_table(0.75, 0.6)
	_glass(root, LowPoly.cylinder(0.06, 0.11, 0.32, 8), WHITE, Vector3(-0.15, 0.76, 0))
	_add(root, LowPoly.cylinder(0.1, 0.1, 0.14, 8), Color("d6334f"), Vector3(-0.15, 0.67, 0), Vector3.ZERO, 1.0)
	_glass(root, LowPoly.cylinder(0.09, 0.09, 0.26, 8), WHITE, Vector3(0.17, 0.73, 0.02))
	_add(root, LowPoly.cylinder(0.08, 0.08, 0.16, 8), Color("f29bb0"), Vector3(0.17, 0.68, 0.02), Vector3.ZERO, 2.0)
	_glass(root, LowPoly.cylinder(0.08, 0.1, 0.34, 8), WATER, Vector3(0.05, 0.79, -0.2))
	return root


static func _tea_cup() -> Node3D:
	var root := _small_table(0.6, 0.6)
	_add(root, LowPoly.cylinder(0.17, 0.17, 0.02, 10), WHITE, Vector3(0, 0.61, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.cylinder(0.11, 0.08, 0.13, 10), WHITE, Vector3(0, 0.69, 0), Vector3.ZERO, 2.0)
	_add(root, LowPoly.cylinder(0.1, 0.1, 0.02, 10), Color("b5652a"), Vector3(0, 0.745, 0), Vector3.ZERO, 3.0)
	_add(root, LowPoly.box(Vector3(0.03, 0.08, 0.06)), WHITE, Vector3(0.13, 0.7, 0), Vector3.ZERO, 4.0)
	for index in 4:
		_add(root, LowPoly.box(Vector3(0.06, 0.06, 0.06)), WHITE, Vector3(-0.2 + (index % 2) * 0.07, 0.63 + floori(index / 2.0) * 0.065, 0.12), Vector3(0, 0.2 * index, 0), 5.0 + index)
	return root


static func _snow_globe() -> Node3D:
	var root := _small_table(0.55, 0.55)
	_add(root, LowPoly.cylinder(0.16, 0.19, 0.1, 10), LowPoly.WOOD, Vector3(0, 0.6, 0), Vector3.ZERO, 1.0)
	_add(root, LowPoly.cylinder(0.0, 0.07, 0.18, 6), LowPoly.GRASS_DARK, Vector3(0, 0.77, 0), Vector3.ZERO, 2.0)
	for index in 8:
		var angle := TAU * index / 8
		_add(root, LowPoly.sphere(0.018, 4, 3), WHITE, Vector3(cos(angle) * 0.1, 0.67 + (index % 3) * 0.08, sin(angle) * 0.1), Vector3.ZERO, 3.0 + index)
	_glass(root, LowPoly.sphere(0.18, 10, 6), WHITE, Vector3(0, 0.82, 0))
	return root


static func _lemon_battery() -> Node3D:
	var root := _small_table(0.7, 0.6)
	var lemon := _add(root, LowPoly.sphere(0.12, 8, 5), YELLOW, Vector3(-0.1, 0.7, 0), Vector3.ZERO, 1.0)
	lemon.scale = Vector3(1.35, 0.9, 0.9)
	_add(root, LowPoly.box(Vector3(0.02, 0.16, 0.06)), Color("c8753a"), Vector3(-0.17, 0.8, 0), Vector3.ZERO, 2.0)
	_add(root, LowPoly.box(Vector3(0.02, 0.16, 0.06)), METAL, Vector3(-0.03, 0.8, 0), Vector3.ZERO, 3.0)
	_add(root, LowPoly.box(Vector3(0.3, 0.015, 0.015)), RED, Vector3(0.02, 0.89, 0.05), Vector3(0, 0, -0.3), 4.0)
	_add(root, LowPoly.box(Vector3(0.24, 0.015, 0.015)), BLACK, Vector3(0.08, 0.86, -0.05), Vector3(0, 0, -0.2), 5.0)
	_add(root, LowPoly.cylinder(0.04, 0.05, 0.08, 6), METAL_DARK, Vector3(0.2, 0.64, 0), Vector3.ZERO, 6.0)
	_glow(root, LowPoly.sphere(0.07, 8, 5), Color("fff3a0"), Vector3(0.2, 0.75, 0))
	return root


static func _electrolysis() -> Node3D:
	var root := _small_table(1.6, 0.6)
	_add(root, LowPoly.box(Vector3(0.6, 0.05, 0.3)), METAL_DARK, Vector3(0, 0.63, 0), Vector3.ZERO, 1.0)
	for side in [-1.0, 1.0]:
		_glass(root, LowPoly.cylinder(0.06, 0.06, 0.8, 8), WATER, Vector3(0.18 * side, 1.05, 0))
		_glass(root, LowPoly.cylinder(0.05, 0.05, 0.5 if side < 0 else 0.62, 8), WATER, Vector3(0.18 * side, 0.9 if side < 0 else 0.96, 0))
		_add(root, LowPoly.cylinder(0.015, 0.015, 0.12, 4), METAL, Vector3(0.18 * side, 0.68, 0), Vector3.ZERO, 3.0)
		for bubble in 3:
			_add(root, LowPoly.sphere(0.018, 4, 3), WHITE, Vector3(0.18 * side + 0.02 * (bubble - 1), 0.8 + bubble * 0.12, 0.02), Vector3.ZERO, 4.0 + bubble)
	_add(root, LowPoly.box(Vector3(0.36, 0.03, 0.03)), METAL, Vector3(0, 1.44, 0), Vector3.ZERO, 5.0)
	_glass(root, LowPoly.sphere(0.1, 8, 5), WATER, Vector3(0, 1.55, 0))
	_add(root, LowPoly.box(Vector3(0.24, 0.16, 0.14)), BLACK, Vector3(0.55, 0.73, 0.05), Vector3.ZERO, 6.0)
	_add(root, LowPoly.box(Vector3(0.24, 0.05, 0.14)), ORANGE, Vector3(0.55, 0.83, 0.05), Vector3.ZERO, 7.0)
	_add(root, LowPoly.cylinder(0.02, 0.02, 0.04, 6), RED, Vector3(0.49, 0.87, 0.05), Vector3.ZERO, 8.0)
	_add(root, LowPoly.cylinder(0.02, 0.02, 0.04, 6), BLACK, Vector3(0.61, 0.87, 0.05), Vector3.ZERO, 9.0)
	return root


static func _string_lights() -> Node3D:
	var root := Node3D.new()
	var bulb_colors: Array[Color] = [YELLOW, Color("ff6b74"), Color("7be86a"), Color("6ec6ff")]
	var points: Array[Vector3] = []
	var count := 12
	for index in count + 1:
		var t := float(index) / count
		points.append(Vector3(-1.35 + t * 2.7, 0.85 - sin(t * PI) * 0.35, 0.05))
	for index in count:
		var a := points[index]
		var b := points[index + 1]
		var segment := _add(root, LowPoly.box(Vector3(a.distance_to(b), 0.015, 0.015)), Color("2f5d3a"), (a + b) / 2, Vector3.ZERO, 1.0)
		segment.rotation.z = atan2(b.y - a.y, b.x - a.x)
		if index > 0:
			_glow(root, LowPoly.sphere(0.045, 6, 4), bulb_colors[index % bulb_colors.size()], a + Vector3(0, -0.06, 0.01))
	for side in [-1.0, 1.0]:
		_add(root, LowPoly.box(Vector3(0.06, 0.06, 0.08)), METAL_DARK, Vector3(1.36 * side, 0.85, 0.04), Vector3.ZERO, 2.0)
	_glass(root, LowPoly.cylinder(0.09, 0.09, 0.22, 8), WATER, Vector3(1.2, 0.15, 0.12))
	_add(root, LowPoly.box(Vector3(0.02, 0.3, 0.02)), METAL, Vector3(1.17, 0.25, 0.12), Vector3.ZERO, 3.0)
	_add(root, LowPoly.box(Vector3(0.02, 0.3, 0.02)), Color("c8753a"), Vector3(1.23, 0.25, 0.12), Vector3.ZERO, 4.0)
	return root


static func _small_table(width: float, height: float) -> Node3D:
	var root := Node3D.new()
	_add(root, LowPoly.box(Vector3(width, 0.06, 0.6)), WOOD_LIGHT, Vector3(0, height - 0.03, 0), Vector3.ZERO, 90.0)
	for x_side in [-1.0, 1.0]:
		for z_side in [-1.0, 1.0]:
			_add(root, LowPoly.box(Vector3(0.06, height - 0.06, 0.06)), LowPoly.WOOD, Vector3((width / 2 - 0.06) * x_side, (height - 0.06) / 2, 0.24 * z_side), Vector3.ZERO, 91.0)
	return root


static func _add(root: Node3D, mesh: PrimitiveMesh, color: Color, at: Vector3, rotation: Vector3, noise_seed: float) -> MeshInstance3D:
	var part := LowPoly.part(LowPoly.flat(mesh, color, Vector3.ZERO, noise_seed), at)
	part.rotation = rotation
	root.add_child(part)
	return part


static func _glass(root: Node3D, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var part := _add(root, mesh, color, at, Vector3.ZERO, 0.0)
	part.material_override = LowPoly.glass_material()
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


static func _glow(root: Node3D, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var part := _add(root, mesh, color, at, Vector3.ZERO, 0.0)
	part.material_override = LowPoly.glow_material()
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


static func _label(root: Node3D, text: String, at: Vector3, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.004
	label.modulate = BLACK
	label.outline_size = 0
	label.position = at
	label.shaded = false
	root.add_child(label)
	return label
