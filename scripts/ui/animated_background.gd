class_name AnimatedBackground
extends Control
## Décor de fond : ciel, nuages, château au loin, falaise, îles flottantes, livres volants
## et étincelles. Couleurs volontairement douces pour rester « flou » derrière l'interface.

var sky_top := Color("2b4fb3")
var sky_mid := Color("6aa6ea")
var sky_bottom := Color("1d3584")

var _t := 0.0
var _clouds: Array[Dictionary] = []
var _books: Array[Dictionary] = []
var _stars: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 7:
		_clouds.append({"x": rng.randf(), "y": rng.randf_range(0.05, 0.5), "s": rng.randf_range(0.6, 1.3), "speed": rng.randf_range(0.004, 0.01)})
	var covers: Array[Color] = [Color("b03a2e"), Color("8e5a2b"), Color("2d6cdf"), Color("7d3c98"), Color("c0392b"), Color("1e8449")]
	for i in 8:
		_books.append({"x": rng.randf(), "y": rng.randf(), "rot": rng.randf_range(-0.5, 0.5), "speed": rng.randf_range(0.004, 0.01),
			"size": rng.randf_range(46, 96), "color": covers[i % covers.size()], "phase": rng.randf() * TAU, "open": i % 2 == 0})
	for i in 26:
		_stars.append({"x": rng.randf(), "y": rng.randf(), "s": rng.randf_range(4, 10), "phase": rng.randf() * TAU})


## Teinte du ciel (légère variation par niveau d'études).
func set_colors(top: Color, bottom: Color) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "sky_top", top, 0.6)
	tw.tween_property(self, "sky_bottom", bottom, 0.6)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2 or h < 2:
		return
	# Ciel en 3 bandes
	var mid_y := h * 0.42
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, mid_y), Vector2(0, mid_y)]),
		PackedColorArray([sky_top, sky_top, sky_mid, sky_mid]))
	draw_polygon(PackedVector2Array([Vector2(0, mid_y), Vector2(w, mid_y), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([sky_mid, sky_mid, sky_bottom, sky_bottom]))

	for c in _clouds:
		var x := fposmod(c.x + _t * c.speed, 1.4) * w - 0.2 * w
		var y: float = c.y * h
		var s: float = c.s * 90.0
		for k in 5:
			var off := Vector2((k - 2) * s * 0.55, -sin(k * 1.3) * s * 0.25 - (0.3 * s if k == 2 else 0.0))
			draw_circle(Vector2(x, y) + off, s * (0.55 if k != 2 else 0.75), Color(1, 1, 1, 0.09))

	_draw_castle(Vector2(w * 0.8, h * 0.6), h * 0.00075)
	_draw_cliff(Vector2(w * 0.06, h * 0.8), h * 0.0007)

	# Îles flottantes au loin
	_island(Vector2(w * 0.18, h * 0.88 + sin(_t * 0.7) * 5), Vector2(170, 46), 0.55)
	_island(Vector2(w * 0.9, h * 0.94 + sin(_t * 0.6 + 1.0) * 5), Vector2(140, 40), 0.5)

	for b in _books:
		var y := fposmod(b.y - _t * b.speed, 1.25) * h - 0.12 * h
		var x: float = b.x * w + sin(_t * 0.4 + b.phase) * 34
		var s: float = b.size
		var rot: float = b.rot + sin(_t * 0.7 + b.phase) * 0.18
		var flap := 0.75 + 0.25 * sin(_t * 3.0 + b.phase)
		draw_set_transform(Vector2(x, y), rot, Vector2.ONE)
		var cover: Color = b.color
		cover.a = 0.75
		var paper := Color(1, 0.96, 0.86, 0.8)
		if b.open:
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-s * 0.55, -s * 0.18 * flap), Vector2(-s * 0.55, s * 0.32), Vector2(0, s * 0.42)]), cover)
			draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s * 0.55, -s * 0.18 * flap), Vector2(s * 0.55, s * 0.32), Vector2(0, s * 0.42)]), cover.darkened(0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s * 0.04), Vector2(-s * 0.5, -s * 0.22 * flap), Vector2(-s * 0.5, s * 0.26), Vector2(0, s * 0.36)]), paper)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s * 0.04), Vector2(s * 0.5, -s * 0.22 * flap), Vector2(s * 0.5, s * 0.26), Vector2(0, s * 0.36)]), paper.darkened(0.08))
		else:
			draw_rect(Rect2(-s / 2, -s * 0.36, s, s * 0.72), cover)
			draw_rect(Rect2(-s / 2 + 4, s * 0.36 - 9, s - 8, 6), paper)
			draw_rect(Rect2(-s / 2, -s * 0.36, s * 0.14, s * 0.72), cover.darkened(0.3))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	for st in _stars:
		var k := 0.5 + 0.5 * sin(_t * 2.0 + st.phase)
		UIDraw.sparkle(self, Vector2(st.x * w, st.y * h), st.s * (0.4 + k * 0.7), Color(1, 1, 0.9, 0.15 + k * 0.5))

	# Vignette douce en haut et en bas
	var dark := Color(0.04, 0.07, 0.25, 0.45)
	var clear := Color(0.04, 0.07, 0.25, 0.0)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h * 0.12), Vector2(0, h * 0.12)]), PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, h * 0.86), Vector2(w, h * 0.86), Vector2(w, h), Vector2(0, h)]), PackedColorArray([clear, clear, dark, dark]))


## Château lointain, désaturé, fenêtres allumées.
func _draw_castle(base: Vector2, s: float) -> void:
	var stone := Color(0.5, 0.6, 0.82, 0.7)
	var stone_dark := Color(0.36, 0.45, 0.7, 0.7)
	var roofs: Array[Color] = [Color(0.38, 0.35, 0.7, 0.8), Color(0.78, 0.42, 0.48, 0.8)]
	# Colline
	draw_colored_polygon(UIDraw.ellipse(base + Vector2(0, 40) * s, Vector2(320, 70) * s), Color(0.24, 0.42, 0.5, 0.6))
	# Courtine crénelée
	var wall := Rect2(base + Vector2(-210, -150) * s, Vector2(420, 190) * s)
	draw_rect(wall, stone_dark)
	for k in 11:
		draw_rect(Rect2(wall.position + Vector2((k * 40 - 4) * s, -22 * s), Vector2(22, 22) * s), stone_dark)
	# Tours : [x, largeur, hauteur]
	var towers := [[-200, 70, 300], [-95, 64, 400], [0, 86, 520], [105, 64, 380], [190, 66, 280]]
	for i in towers.size():
		var x: float = towers[i][0]
		var tw: float = towers[i][1]
		var th: float = towers[i][2]
		var r := Rect2(base + Vector2(x - tw / 2, -th) * s, Vector2(tw, th + 40) * s)
		draw_rect(r, stone)
		draw_rect(Rect2(r.position + Vector2(r.size.x * 0.62, 0), Vector2(r.size.x * 0.38, r.size.y)), stone_dark)
		for k in 3:
			draw_rect(Rect2(r.position + Vector2((k * tw / 2.5 - 2) * s, -14 * s), Vector2(tw / 5, 14) * s), stone)
		var roof := roofs[i % 2]
		var apex := r.position + Vector2(r.size.x / 2, -tw * 1.7 * s)
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(-12 * s, -10 * s), r.position + Vector2(r.size.x + 12 * s, -10 * s), apex]), roof)
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x / 2, -10 * s), r.position + Vector2(r.size.x + 12 * s, -10 * s), apex]), roof.darkened(0.2))
		var glow := 0.6 + 0.4 * sin(_t * 2.0 + x)
		var win := Rect2(r.position + Vector2(r.size.x * 0.36, 50 * s), Vector2(r.size.x * 0.28, 40 * s))
		draw_rect(win, Color(0.15, 0.18, 0.35, 0.7))
		draw_rect(win.grow(-3 * s), Color(1.0, 0.75, 0.4, 0.6 * glow))
		if i == 2:
			draw_line(apex, apex + Vector2(0, -50) * s, stone_dark, 4 * s)
			var wave := sin(_t * 4.0) * 8 * s
			draw_colored_polygon(PackedVector2Array([apex + Vector2(0, -50) * s, apex + Vector2(46, -40) * s + Vector2(0, wave), apex + Vector2(0, -28) * s]), Color(0.9, 0.35, 0.35, 0.8))
	# Porte
	draw_rect(Rect2(base + Vector2(-28, -70) * s, Vector2(56, 110) * s), Color(0.2, 0.18, 0.3, 0.7))


## Falaise et petite tour à gauche.
func _draw_cliff(base: Vector2, s: float) -> void:
	var rock := Color(0.2, 0.28, 0.55, 0.8)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-200, 400) * s, base + Vector2(-200, -150) * s, base + Vector2(-60, -230) * s,
		base + Vector2(80, -170) * s, base + Vector2(150, 0) * s, base + Vector2(120, 400) * s]), rock)
	draw_colored_polygon(UIDraw.ellipse(base + Vector2(-40, -200) * s, Vector2(140, 40) * s), Color(0.28, 0.5, 0.42, 0.75))
	var house := Rect2(base + Vector2(-110, -330) * s, Vector2(130, 120) * s)
	draw_rect(house, Color(0.55, 0.42, 0.42, 0.8))
	draw_colored_polygon(PackedVector2Array([house.position + Vector2(-20, 0) * s, house.position + Vector2(150, 0) * s, house.position + Vector2(65, -90) * s]), Color(0.6, 0.3, 0.3, 0.85))
	draw_rect(Rect2(house.position + Vector2(45, 50) * s, Vector2(36, 70) * s), Color(0.25, 0.18, 0.2, 0.9))


func _island(c: Vector2, r: Vector2, a: float) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r.x, 0), c + Vector2(r.x, 0), c + Vector2(r.x * 0.3, r.y * 2.6), c + Vector2(-r.x * 0.2, r.y * 2.2)]), Color(0.32, 0.22, 0.25, a))
	draw_colored_polygon(UIDraw.ellipse(c, r), Color(0.32, 0.6, 0.38, a))
