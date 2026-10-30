class_name MapAnimations
extends RefCounted

var _entries: Array[Dictionary] = []


func spin(node: Node3D, axis: Vector3, speed: float) -> void:
	_entries.append({"kind": "spin", "node": node, "axis": axis.normalized(), "speed": speed})


func bob(node: Node3D, amplitude: float, speed: float, phase := 0.0) -> void:
	_entries.append({"kind": "bob", "node": node, "base": node.position.y, "amplitude": amplitude, "speed": speed, "phase": phase})


func rise(node: Node3D, height: float, speed: float) -> void:
	_entries.append({"kind": "rise", "node": node, "base": node.position.y, "height": height, "speed": speed, "offset": fposmod(node.position.x * 7.3, height)})


func swing(node: Node3D, angle: float, speed: float) -> void:
	_entries.append({"kind": "swing", "node": node, "angle": angle, "speed": speed})


func orbit(node: Node3D, center: Vector3, radius: float, speed: float, phase := 0.0) -> void:
	_entries.append({"kind": "orbit", "node": node, "center": center, "radius": radius, "speed": speed, "phase": phase})


func clear() -> void:
	_entries.clear()


func update(time: float, delta: float) -> void:
	for entry in _entries:
		var node: Node3D = entry.node
		if not is_instance_valid(node):
			continue
		match entry.kind:
			"spin":
				node.rotate_object_local(entry.axis, entry.speed * delta)
			"bob":
				node.position.y = entry.base + sin(time * entry.speed + entry.phase) * entry.amplitude
			"rise":
				node.position.y = entry.base + fposmod(entry.offset + time * entry.speed, entry.height)
				node.scale = Vector3.ONE * clampf(minf(node.position.y - entry.base, entry.base + entry.height - node.position.y) * 2.0, 0.0, 1.0)
			"swing":
				node.rotation.z = sin(time * entry.speed) * entry.angle
			"orbit":
				var angle: float = time * entry.speed + entry.phase
				node.position = entry.center + Vector3(cos(angle), 0, sin(angle)) * entry.radius
