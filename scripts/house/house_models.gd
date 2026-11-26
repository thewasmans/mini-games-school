class_name HouseModels
extends RefCounted

const FLOOR_WOOD := Color("c08a55")
const WALL_PAPER := Color("f3dfbd")
const WALL_TRIM := Color("9c6a43")
const DIRT := Color("8a7a66")
const SKIN := Color("f2c29b")
const SHIRT := Color("3d84f2")
const TROUSERS := Color("3a4256")
const HAIR := Color("6b3f22")


static func item(item_data: HousingItemData) -> Node3D:
	if item_data.model != null:
		return item_data.model.instantiate() as Node3D
	var built := ChemistryModels.build(TextUtil.to_answer(item_data.word))
	if built != null:
		return built
	var color := Color.from_hsv(fposmod(hash(item_data.word) / 1000.0, 1.0), 0.55, 0.9)
	var root := Node3D.new()
	var width := item_data.footprint.x * HouseWorld.CELL - 0.2
	var depth := item_data.footprint.y * HouseWorld.CELL - 0.2
	match item_data.slot:
		HousingItemData.Slot.FLOOR:
			root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width, 0.7, depth)), LowPoly.WOOD, Vector3.ONE * 0.02, 1.0), Vector3(0, 0.35, 0)))
			root.add_child(LowPoly.part(LowPoly.flat(LowPoly.sphere(minf(width, depth) * 0.3), color, Vector3.ONE * 0.03, 2.0), Vector3(0, 0.95, 0)))
		HousingItemData.Slot.WALL:
			var height := item_data.footprint.y * HouseWorld.WALL_ROW_HEIGHT - 0.2
			root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width, height, 0.08)), LowPoly.WOOD, Vector3.ZERO, 3.0), Vector3(0, height / 2, 0)))
			root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width - 0.16, height - 0.16, 0.06)), color, Vector3.ZERO, 4.0), Vector3(0, height / 2, 0.03)))
		HousingItemData.Slot.CEILING:
			root.add_child(LowPoly.part(LowPoly.flat(LowPoly.cylinder(0.02, 0.02, 0.6, 4), LowPoly.STONE_DARK, Vector3.ZERO, 5.0), Vector3(0, -0.3, 0)))
			root.add_child(LowPoly.part(LowPoly.flat(LowPoly.sphere(0.28), color, Vector3.ONE * 0.02, 6.0), Vector3(0, -0.7, 0)))
	return root


static func ghost(item_data: HousingItemData) -> MeshInstance3D:
	var height := 1.0 if item_data.slot != HousingItemData.Slot.WALL else item_data.footprint.y * HouseWorld.WALL_ROW_HEIGHT
	var depth := item_data.footprint.y * HouseWorld.CELL if item_data.slot != HousingItemData.Slot.WALL else 0.2
	var mesh := LowPoly.box(Vector3(item_data.footprint.x * HouseWorld.CELL, height, depth))
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = material
	return instance


static func debris(renovation: HousingRenovationData, noise_seed: float) -> Node3D:
	var root := Node3D.new()
	for index in renovation.cells.size():
		var cell := renovation.cells[index]
		var offset := Vector3(cell.x + 0.5, 0, cell.y + 0.5) * HouseWorld.CELL
		if renovation.slot == HousingItemData.Slot.WALL:
			var stain := LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.9, 0.9, 0.04)), DIRT, Vector3.ONE * 0.04, noise_seed + index), Vector3.ZERO, false)
			stain.position = Vector3(cell.x + 0.5, (cell.y + 0.5) * HouseWorld.WALL_ROW_HEIGHT + HouseWorld.WALL_BASE, 0.0)
			root.add_child(stain)
			continue
		root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.7, 0.5, 0.6)), LowPoly.WOOD.lightened(0.15), Vector3.ONE * 0.05, noise_seed + index), offset + Vector3(-0.1, 0.25, 0.05)))
		root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.5, 0.35, 0.45)), DIRT, Vector3.ONE * 0.05, noise_seed + index + 0.5), offset + Vector3(0.15, 0.68, -0.05)))
	return root


static func kid() -> Node3D:
	var root := Node3D.new()
	for side in [-1.0, 1.0]:
		root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.16, 0.45, 0.18)), TROUSERS, Vector3.ZERO, 30.0 + side), Vector3(0.11 * side, 0.23, 0)))
		root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.12, 0.38, 0.12)), SHIRT, Vector3.ZERO, 32.0 + side), Vector3(0.3 * side, 0.72, 0)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.44, 0.5, 0.26)), SHIRT, Vector3.ONE * 0.01, 34.0), Vector3(0, 0.7, 0)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.3, 0.36, 0.14)), Color("e2533f"), Vector3.ZERO, 35.0), Vector3(0, 0.72, 0.18)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.sphere(0.24, 8, 5), SKIN, Vector3.ZERO, 36.0), Vector3(0, 1.17, 0)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.sphere(0.25, 8, 4), HAIR, Vector3.ONE * 0.02, 37.0), Vector3(0, 1.26, 0.03)))
	return root


static func grandfather_portrait() -> Node3D:
	var root := Node3D.new()
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(1.1, 1.4, 0.08)), Color("d9a441"), Vector3.ZERO, 40.0), Vector3(0, 0, 0)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.9, 1.2, 0.06)), Color("4b6a8f"), Vector3.ZERO, 41.0), Vector3(0, 0, 0.03)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.sphere(0.2), SKIN, Vector3.ZERO, 42.0), Vector3(0, 0.15, 0.1)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.36, 0.08, 0.06)), Color("f5f5f5"), Vector3.ZERO, 43.0), Vector3(0, 0.02, 0.18)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.5, 0.4, 0.06)), Color("7a4a2e"), Vector3.ZERO, 44.0), Vector3(0, -0.3, 0.08)))
	return root


static func lock_sign() -> Node3D:
	var root := Node3D.new()
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.5, 0.5, 0.1)), Color("dfe4ee"), Vector3.ZERO, 50.0), Vector3(0, 0, 0)))
	root.add_child(LowPoly.part(LowPoly.flat(LowPoly.cylinder(0.14, 0.14, 0.08, 8), Color("9aa3b5"), Vector3.ZERO, 51.0), Vector3(0, 0.3, 0)))
	return root
