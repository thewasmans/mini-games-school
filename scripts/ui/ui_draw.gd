class_name UIDraw
extends RefCounted
## Dessin vectoriel « cartoon » : rectangles arrondis en dégradé, lueurs, icônes et île-château.
## Toutes les fonctions dessinent dans le _draw() du CanvasItem passé en paramètre.


# --- Formes de base --------------------------------------------------------

static func rrect_points(r: Rect2, radius: float, steps := 6) -> PackedVector2Array:
	var rad := clampf(radius, 1.0, minf(r.size.x, r.size.y) / 2.0)
	var corners := [
		[r.position + Vector2(rad, rad), PI],
		[Vector2(r.end.x - rad, r.position.y + rad), PI * 1.5],
		[r.end - Vector2(rad, rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI * 0.5],
	]
	var pts := PackedVector2Array()
	for c in corners:
		for i in steps + 1:
			var a: float = c[1] + (PI / 2.0) * i / steps
			var p: Vector2 = c[0] + Vector2(cos(a), sin(a)) * rad
			if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(p) > 0.01:
				pts.append(p)
	if pts.size() > 2 and pts[0].distance_squared_to(pts[pts.size() - 1]) <= 0.01:
		pts.remove_at(pts.size() - 1)
	return pts


## Rectangle arrondi rempli d'un dégradé vertical, bord anticrénelé.
static func rrect(ci: CanvasItem, r: Rect2, radius: float, top: Color, bottom := Color(0, 0, 0, -1), outline := Color(0, 0, 0, 0), outline_width := 0.0) -> void:
	if r.size.x < 2 or r.size.y < 2:
		return
	if bottom.a < 0:
		bottom = top
	var pts := rrect_points(r, radius)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)))
	ci.draw_polygon(pts, cols)
	var closed := pts.duplicate()
	closed.append(pts[0])
	if outline_width > 0 and outline.a > 0:
		ci.draw_polyline(closed, outline, outline_width, true)
	else:
		var closed_cols := cols.duplicate()
		closed_cols.append(cols[0])
		ci.draw_polyline_colors(closed, closed_cols, 1.0, true)


## Halo lumineux autour d'un rectangle arrondi.
static func glow(ci: CanvasItem, r: Rect2, radius: float, color: Color, size := 14.0, layers := 5) -> void:
	for i in layers:
		var k := float(layers - i) / layers
		var g := r.grow(size * k)
		var c := color
		c.a = color.a * (1.0 - k) * 0.6
		rrect(ci, g, radius + size * k, c)


## Polygone défini en coordonnées unitaires, centré sur c, mis à l'échelle s et tourné.
static func poly(ci: CanvasItem, unit_pts: Array, c: Vector2, s: float, rot: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for p: Vector2 in unit_pts:
		pts.append(c + p.rotated(rot) * s)
	ci.draw_colored_polygon(pts, color)


static func ellipse(center: Vector2, radius: Vector2, steps := 36) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * i / steps
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return pts


static func star_points(center: Vector2, outer: float, inner: float, points := 5, rotation := -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var r := outer if i % 2 == 0 else inner
		var a := rotation + TAU * i / (points * 2.0)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


## Étincelle à 4 branches.
static func sparkle(ci: CanvasItem, p: Vector2, size: float, color := Color(1, 1, 0.9)) -> void:
	if size <= 0.5:
		return
	ci.draw_colored_polygon(star_points(p, size, size * 0.22, 4, 0.0), color)
	ci.draw_circle(p, size * 0.22, Color(1, 1, 1, color.a))


# --- Icônes ----------------------------------------------------------------

## Icône vectorielle de hauteur ~s centrée sur c.
static func icon(ci: CanvasItem, name: String, c: Vector2, s: float) -> void:
	var sprite := UISkin.icon(name)
	if sprite != null:
		UISkin.draw_fit(ci, sprite, c, s * 1.15)
		return
	match name:
		"book":
			_book(ci, c, s, Color("e2533f"))
		"book_blue":
			_book(ci, c, s, Color("3b7be0"))
		"pencil":
			_pencil(ci, c, s)
		"compass":
			_compass(ci, c, s)
		"ruler":
			_ruler(ci, c, s)
		"scroll":
			_scroll(ci, c, s)
		"microscope":
			_microscope(ci, c, s)
		"star":
			ci.draw_colored_polygon(star_points(c + Vector2(0, s * 0.05), s * 0.55, s * 0.25), Color("b86e00"))
			ci.draw_colored_polygon(star_points(c, s * 0.52, s * 0.23), Color("ffd23f"))
			ci.draw_colored_polygon(star_points(c + Vector2(-s * 0.06, -s * 0.06), s * 0.25, s * 0.11), Color(1, 1, 1, 0.35))
		"gear":
			_gear(ci, c, s)
		"back":
			_chevron(ci, c, s, true)
		"next":
			_chevron(ci, c, s, false)
		"check":
			var pts := PackedVector2Array([c + Vector2(-0.4, 0.0) * s, c + Vector2(-0.12, 0.3) * s, c + Vector2(0.42, -0.3) * s])
			ci.draw_polyline(pts, UIStyle.INK, s * 0.32, true)
			ci.draw_polyline(pts, Color.WHITE, s * 0.18, true)
		"backspace":
			var pts := PackedVector2Array([c + Vector2(-0.55, 0) * s, c + Vector2(-0.25, -0.32) * s, c + Vector2(0.5, -0.32) * s,
				c + Vector2(0.5, 0.32) * s, c + Vector2(-0.25, 0.32) * s, c + Vector2(-0.55, 0) * s])
			ci.draw_polyline(pts, UIStyle.INK, s * 0.09, true)
			ci.draw_line(c + Vector2(-0.02, -0.14) * s, c + Vector2(0.26, 0.14) * s, UIStyle.INK, s * 0.09, true)
			ci.draw_line(c + Vector2(0.26, -0.14) * s, c + Vector2(-0.02, 0.14) * s, UIStyle.INK, s * 0.09, true)
		"lock":
			lock(ci, c, s)
		"sound_off":
			_gear(ci, c, s)
			ci.draw_line(c + Vector2(-0.45, -0.45) * s, c + Vector2(0.45, 0.45) * s, UIStyle.INK, s * 0.2, true)
			ci.draw_line(c + Vector2(-0.45, -0.45) * s, c + Vector2(0.45, 0.45) * s, Color("ff4d5a"), s * 0.11, true)


static func _book(ci: CanvasItem, c: Vector2, s: float, cover: Color) -> void:
	var rot := -0.18
	poly(ci, [Vector2(-0.3, -0.42), Vector2(0.36, -0.42), Vector2(0.36, 0.46), Vector2(-0.3, 0.46)], c + Vector2(0.04, 0.04) * s, s, rot, Color(0, 0, 0, 0.25))
	poly(ci, [Vector2(-0.24, -0.38), Vector2(0.36, -0.38), Vector2(0.36, 0.44), Vector2(-0.24, 0.44)], c, s, rot, Color("fff4dc"))
	poly(ci, [Vector2(-0.3, -0.44), Vector2(0.3, -0.44), Vector2(0.3, 0.38), Vector2(-0.3, 0.38)], c, s, rot, cover)
	poly(ci, [Vector2(-0.3, -0.44), Vector2(-0.18, -0.44), Vector2(-0.18, 0.38), Vector2(-0.3, 0.38)], c, s, rot, cover.darkened(0.3))
	poly(ci, [Vector2(-0.06, -0.24), Vector2(0.2, -0.24), Vector2(0.2, -0.12), Vector2(-0.06, -0.12)], c, s, rot, Color(1, 1, 1, 0.55))
	poly(ci, [Vector2(0.08, 0.38), Vector2(0.16, 0.38), Vector2(0.16, 0.56), Vector2(0.12, 0.5), Vector2(0.08, 0.56)], c, s, rot, Color("3b7be0"))


static func _pencil(ci: CanvasItem, c: Vector2, s: float) -> void:
	var rot := 0.75
	poly(ci, [Vector2(-0.1, -0.5), Vector2(0.1, -0.5), Vector2(0.1, 0.24), Vector2(-0.1, 0.24)], c, s, rot, Color("ffc93c"))
	poly(ci, [Vector2(0.02, -0.5), Vector2(0.1, -0.5), Vector2(0.1, 0.24), Vector2(0.02, 0.24)], c, s, rot, Color("e89e14"))
	poly(ci, [Vector2(-0.1, 0.24), Vector2(0.1, 0.24), Vector2(0.0, 0.5)], c, s, rot, Color("f4c48a"))
	poly(ci, [Vector2(-0.035, 0.42), Vector2(0.035, 0.42), Vector2(0.0, 0.5)], c, s, rot, UIStyle.INK)
	poly(ci, [Vector2(-0.1, -0.6), Vector2(0.1, -0.6), Vector2(0.1, -0.5), Vector2(-0.1, -0.5)], c, s, rot, Color("b8c0cc"))
	poly(ci, [Vector2(-0.1, -0.72), Vector2(0.1, -0.72), Vector2(0.1, -0.6), Vector2(-0.1, -0.6)], c, s, rot, Color("ff8fa3"))


static func _ruler(ci: CanvasItem, c: Vector2, s: float) -> void:
	var rot := -0.8
	poly(ci, [Vector2(-0.14, -0.55), Vector2(0.14, -0.55), Vector2(0.14, 0.55), Vector2(-0.14, 0.55)], c + Vector2(0.03, 0.04) * s, s, rot, Color(0, 0, 0, 0.25))
	poly(ci, [Vector2(-0.14, -0.55), Vector2(0.14, -0.55), Vector2(0.14, 0.55), Vector2(-0.14, 0.55)], c, s, rot, Color("f5b041"))
	poly(ci, [Vector2(0.06, -0.55), Vector2(0.14, -0.55), Vector2(0.14, 0.55), Vector2(0.06, 0.55)], c, s, rot, Color("d68910"))
	for i in 9:
		var y := -0.45 + i * 0.11
		var l := 0.12 if i % 2 == 0 else 0.06
		poly(ci, [Vector2(-0.14, y), Vector2(-0.14 + l, y), Vector2(-0.14 + l, y + 0.025), Vector2(-0.14, y + 0.025)], c, s, rot, Color("7a4a10"))


static func _compass(ci: CanvasItem, c: Vector2, s: float) -> void:
	var top := c + Vector2(0, -0.42) * s
	var l := c + Vector2(-0.3, 0.48) * s
	var r := c + Vector2(0.3, 0.48) * s
	for leg in [l, r]:
		ci.draw_line(top, leg, UIStyle.INK, s * 0.17, true)
		ci.draw_line(top, leg, Color("c9d1de"), s * 0.09, true)
	ci.draw_line(top.lerp(l, 0.55), top.lerp(r, 0.55), Color("8e44ad"), s * 0.06, true)
	ci.draw_circle(top, s * 0.12, UIStyle.INK)
	ci.draw_circle(top, s * 0.08, Color("e2533f"))
	ci.draw_line(top, top + Vector2(0, -0.12) * s, UIStyle.INK, s * 0.07, true)


static func _scroll(ci: CanvasItem, c: Vector2, s: float) -> void:
	var rot := -0.15
	poly(ci, [Vector2(-0.42, -0.3), Vector2(0.42, -0.3), Vector2(0.42, 0.34), Vector2(-0.42, 0.34)], c + Vector2(0.03, 0.04) * s, s, rot, Color(0, 0, 0, 0.25))
	poly(ci, [Vector2(-0.38, -0.3), Vector2(0.38, -0.3), Vector2(0.38, 0.3), Vector2(-0.38, 0.3)], c, s, rot, Color("f7e1b5"))
	for y in [-0.14, 0.0, 0.14]:
		poly(ci, [Vector2(-0.24, y), Vector2(0.22, y), Vector2(0.22, y + 0.04), Vector2(-0.24, y + 0.04)], c, s, rot, Color("c79a5a"))
	for x in [-0.42, 0.42]:
		poly(ci, [Vector2(x - 0.07, -0.36), Vector2(x + 0.07, -0.36), Vector2(x + 0.07, 0.36), Vector2(x - 0.07, 0.36)], c, s, rot, Color("d9a95f"))
		poly(ci, [Vector2(x - 0.02, -0.36), Vector2(x + 0.07, -0.36), Vector2(x + 0.07, 0.36), Vector2(x - 0.02, 0.36)], c, s, rot, Color("b07f3a"))


static func _microscope(ci: CanvasItem, c: Vector2, s: float) -> void:
	UIDraw.rrect(ci, Rect2(c + Vector2(-0.4, 0.34) * s, Vector2(0.8, 0.16) * s), s * 0.06, Color("7d6bc2"), Color("5a4a9a"))
	ci.draw_arc(c + Vector2(0.05, 0.05) * s, s * 0.3, -PI * 0.45, PI * 0.5, 16, UIStyle.INK, s * 0.17, true)
	ci.draw_arc(c + Vector2(0.05, 0.05) * s, s * 0.3, -PI * 0.45, PI * 0.5, 16, Color("a99ae0"), s * 0.09, true)
	UIDraw.rrect(ci, Rect2(c + Vector2(-0.3, 0.12) * s, Vector2(0.4, 0.08) * s), s * 0.03, Color("c9d1de"))
	poly(ci, [Vector2(-0.08, -0.34), Vector2(0.08, -0.34), Vector2(0.08, 0.12), Vector2(-0.08, 0.12)], c + Vector2(-0.1, -0.05) * s, s, -0.45, Color("dfe4ee"))
	poly(ci, [Vector2(0.0, -0.34), Vector2(0.08, -0.34), Vector2(0.08, 0.12), Vector2(0.0, 0.12)], c + Vector2(-0.1, -0.05) * s, s, -0.45, Color("aab3c4"))
	poly(ci, [Vector2(-0.1, -0.44), Vector2(0.1, -0.44), Vector2(0.1, -0.34), Vector2(-0.1, -0.34)], c + Vector2(-0.1, -0.05) * s, s, -0.45, Color("5a4a9a"))


static func _gear(ci: CanvasItem, c: Vector2, s: float) -> void:
	var col := Color.WHITE
	for i in 8:
		var a := TAU * i / 8.0
		poly(ci, [Vector2(-0.1, -0.5), Vector2(0.1, -0.5), Vector2(0.12, -0.3), Vector2(-0.12, -0.3)], c, s, a, UIStyle.INK)
	ci.draw_circle(c, s * 0.36, UIStyle.INK)
	for i in 8:
		var a := TAU * i / 8.0
		poly(ci, [Vector2(-0.07, -0.44), Vector2(0.07, -0.44), Vector2(0.09, -0.3), Vector2(-0.09, -0.3)], c, s, a, col)
	ci.draw_circle(c, s * 0.31, col)
	ci.draw_circle(c, s * 0.13, Color("2f6be0"))


static func _chevron(ci: CanvasItem, c: Vector2, s: float, left: bool) -> void:
	var d := 1.0 if left else -1.0
	var pts := PackedVector2Array([c + Vector2(0.18 * d, -0.36) * s, c + Vector2(-0.2 * d, 0) * s, c + Vector2(0.18 * d, 0.36) * s])
	ci.draw_polyline(pts, UIStyle.INK, s * 0.34, true)
	ci.draw_polyline(pts, Color.WHITE, s * 0.2, true)


## Cadenas argenté.
static func lock(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c + Vector2(0, -0.12) * s, s * 0.24, PI, TAU, 18, UIStyle.INK, s * 0.17, true)
	ci.draw_arc(c + Vector2(0, -0.12) * s, s * 0.24, PI, TAU, 18, Color("dfe4ee"), s * 0.09, true)
	var body := Rect2(c + Vector2(-0.36, -0.14) * s, Vector2(0.72, 0.6) * s)
	rrect(ci, body.grow(s * 0.04), s * 0.12, UIStyle.INK)
	rrect(ci, body, s * 0.1, Color("eef1f6"), Color("9aa3b5"))
	ci.draw_circle(c + Vector2(0, 0.08) * s, s * 0.08, Color("3a4256"))
	ci.draw_line(c + Vector2(0, 0.1) * s, c + Vector2(0, 0.28) * s, Color("3a4256"), s * 0.07, true)


# --- Île flottante avec château --------------------------------------------

## Île flottante surmontée d'un château, largeur 2*s, sommet de l'herbe en c.
static func castle_island(ci: CanvasItem, c: Vector2, s: float, roof := Color("3b6fd8"), dark := false) -> void:
	var P := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	var stone := Color("8a8fa3") if dark else Color("c3c9d6")
	var stone_dark := Color("5f6478") if dark else Color("9199ab")
	# Roche
	ci.draw_colored_polygon(PackedVector2Array([P.call(-1.0, 0.05), P.call(1.0, 0.05), P.call(0.75, 0.42), P.call(0.4, 0.72),
		P.call(0.08, 1.05), P.call(-0.22, 0.75), P.call(-0.6, 0.5)]), Color("8b5a3c"))
	ci.draw_colored_polygon(PackedVector2Array([P.call(0.1, 0.05), P.call(1.0, 0.05), P.call(0.75, 0.42), P.call(0.4, 0.72),
		P.call(0.08, 1.05)]), Color("6b4228"))
	ci.draw_colored_polygon(PackedVector2Array([P.call(-0.6, 0.5), P.call(-0.35, 0.55), P.call(-0.45, 0.82)]), Color("7a4a2e"))
	ci.draw_colored_polygon(ellipse(P.call(0, 0.08), Vector2(1.0, 0.24) * s), Color("7a4a2e"))
	ci.draw_colored_polygon(ellipse(P.call(0, 0.0), Vector2(1.0, 0.24) * s), Color("62b844"))
	ci.draw_colored_polygon(ellipse(P.call(-0.2, -0.03), Vector2(0.65, 0.13) * s), Color("86d65e"))
	# Arbres
	for t in [[-0.82, 0.0], [0.8, 0.02], [0.66, 0.08]]:
		ci.draw_rect(Rect2(P.call(t[0] - 0.02, t[1] - 0.12), Vector2(0.04, 0.12) * s), Color("6b4228"))
		ci.draw_colored_polygon(PackedVector2Array([P.call(t[0] - 0.11, t[1] - 0.1), P.call(t[0] + 0.11, t[1] - 0.1), P.call(t[0], t[1] - 0.42)]), Color("2e8b3e"))
	# Murailles
	var wall := Rect2(P.call(-0.5, -0.38), Vector2(1.0, 0.38) * s)
	ci.draw_rect(wall, stone)
	ci.draw_rect(Rect2(P.call(0.1, -0.38), Vector2(0.4, 0.38) * s), stone_dark)
	for i in 6:
		ci.draw_rect(Rect2(P.call(-0.5 + i * 0.18, -0.46), Vector2(0.1, 0.09) * s), stone if i < 3 else stone_dark)
	# Porte
	ci.draw_colored_polygon(PackedVector2Array([P.call(-0.12, 0.0), P.call(0.12, 0.0), P.call(0.12, -0.18), P.call(0.0, -0.27), P.call(-0.12, -0.18)]), Color("5a3a28"))
	ci.draw_line(P.call(0, 0), P.call(0, -0.25), Color("3e2618"), s * 0.02)
	# Tours
	for tw in [[-0.62, 0.26, -0.62], [0.36, 0.26, -0.62], [-0.16, 0.32, -0.95]]:
		var x: float = tw[0]
		var w: float = tw[1]
		var top: float = tw[2]
		ci.draw_rect(Rect2(P.call(x, top), Vector2(w, -top) * s), stone)
		ci.draw_rect(Rect2(P.call(x + w * 0.55, top), Vector2(w * 0.45, -top) * s), stone_dark)
		ci.draw_colored_polygon(PackedVector2Array([P.call(x - 0.05, top), P.call(x + w + 0.05, top), P.call(x + w / 2, top - w * 1.25)]), roof)
		ci.draw_colored_polygon(PackedVector2Array([P.call(x + w / 2, top), P.call(x + w + 0.05, top), P.call(x + w / 2, top - w * 1.25)]), roof.darkened(0.25))
		var win := Color("ff7a3d") if dark else Color("ffcf6b")
		ci.draw_rect(Rect2(P.call(x + w * 0.38, top + 0.12), Vector2(w * 0.24, 0.12) * s), Color("2a2f45"))
		ci.draw_rect(Rect2(P.call(x + w * 0.42, top + 0.14), Vector2(w * 0.16, 0.08) * s), win)
	# Drapeau
	ci.draw_line(P.call(0.0, -1.35), P.call(0.0, -1.6), Color("4a4f60"), s * 0.025)
	ci.draw_colored_polygon(PackedVector2Array([P.call(0.0, -1.6), P.call(0.2, -1.55), P.call(0.0, -1.48)]), Color("ff4d5a"))
