class_name AnimatedBackground
extends Control
## Fond animé : dégradé, rayons lumineux, bulles, étoiles scintillantes et livres flottants.

var top_color := Color("2f6fe0")
var bottom_color := Color("12206a")

var _t := 0.0
var _bubbles: Array[Dictionary] = []
var _stars: Array[Dictionary] = []
var _books: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 18:
		_bubbles.append({"x": rng.randf(), "y": rng.randf(), "r": rng.randf_range(20, 90), "speed": rng.randf_range(0.01, 0.03), "a": rng.randf_range(0.04, 0.1)})
	for i in 30:
		_stars.append({"x": rng.randf(), "y": rng.randf(), "s": rng.randf_range(3, 8), "phase": rng.randf() * TAU})
	var book_colors: Array[Color] = [Color("c0392b"), Color("8e5a2b"), Color("2d6cdf"), Color("7d3c98"), Color("1e8449")]
	for i in 7:
		_books.append({"x": rng.randf(), "y": rng.randf(), "rot": rng.randf_range(-0.6, 0.6), "speed": rng.randf_range(0.006, 0.014),
			"size": rng.randf_range(40, 80), "color": book_colors[i % book_colors.size()], "phase": rng.randf() * TAU})


func set_colors(top: Color, bottom: Color) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "top_color", top, 0.6)
	tw.tween_property(self, "bottom_color", bottom, 0.6)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

	# Rayons qui tournent lentement depuis le haut
	var origin := Vector2(w / 2, h * 0.18)
	for i in 12:
		var a := _t * 0.06 + TAU * i / 12.0
		var p1 := origin + Vector2(cos(a), sin(a)) * h * 1.3
		var p2 := origin + Vector2(cos(a + 0.16), sin(a + 0.16)) * h * 1.3
		draw_colored_polygon(PackedVector2Array([origin, p1, p2]), Color(1, 1, 1, 0.035))

	for b in _bubbles:
		var y := fposmod(b.y - _t * b.speed, 1.2) * h - 0.1 * h
		var x: float = b.x * w + sin(_t * 0.5 + b.r) * 20
		draw_circle(Vector2(x, y), b.r, Color(1, 1, 1, b.a))

	for b in _books:
		var y := fposmod(b.y + _t * b.speed, 1.25) * h - 0.12 * h
		var x: float = b.x * w + sin(_t * 0.4 + b.phase) * 30
		var s: float = b.size
		draw_set_transform(Vector2(x, y), b.rot + sin(_t * 0.7 + b.phase) * 0.15, Vector2.ONE)
		var c: Color = b.color
		c.a = 0.45
		draw_rect(Rect2(-s / 2, -s * 0.35, s, s * 0.7), c)
		draw_rect(Rect2(-s / 2 + 4, -s * 0.35 + s * 0.7 - 8, s - 8, 6), Color(1, 0.96, 0.85, 0.45))
		draw_rect(Rect2(-3, -s * 0.35, 6, s * 0.7), Color(0, 0, 0, 0.15))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	for s in _stars:
		var tw := 0.5 + 0.5 * sin(_t * 2.2 + s.phase)
		var c := Vector2(s.x * w, s.y * h)
		draw_colored_polygon(UIStyle.star(c, s.s * (0.6 + tw * 0.6), s.s * 0.25, _t * 0.5 + s.phase), Color(1, 1, 0.85, 0.15 + tw * 0.5))

	# Îles en ombre chinoise en bas
	for i in 3:
		var cx := w * (0.15 + i * 0.38)
		var cy := h * (0.97 - (i % 2) * 0.04) + sin(_t * 0.8 + i) * 6
		draw_colored_polygon(UIStyle.ellipse(Vector2(cx, cy), Vector2(w * 0.3, 60)), Color(0.04, 0.07, 0.25, 0.55))
