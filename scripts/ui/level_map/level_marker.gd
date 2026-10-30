class_name LevelMarker
extends Control

enum State { LOCKED, OPEN, CURRENT, DONE }

@export var number_label: Label
@export var title_label: Label
@export var star_rating: StarRating

@export_group("Réglages")
## Centre de la pastille dans le marqueur : c'est ce point qui suit l'île 3D.
@export var badge_center := Vector2(90, 48)
## Rayon de la pastille, en pixels.
@export var badge_radius := 38.0
## Couleur de la pastille d'un level verrouillé.
@export var locked_color := Color("8a93a6")
## Couleur de la pastille d'un level ouvert.
@export var open_color := Color("3d84f2")
## Couleur de la pastille d'un level terminé.
@export var done_color := Color("ffb43b")

var state := State.LOCKED:
	set(value):
		state = value
		_refresh()
var kind := ""
var lock_offset := Vector2.ZERO
var flash := 0.0

var _t := 0.0
var _phase := 0.0


func _ready() -> void:
	pivot_offset = badge_center
	_refresh()


func setup(level_index: int, title: String, kind_: String, stars: float) -> void:
	number_label.text = str(level_index + 1)
	title_label.text = title
	kind = kind_
	star_rating.value = stars
	_phase = level_index * 1.3


func shake() -> void:
	UIFeedback.shake(self, 10.0, 0.35)


func punch() -> void:
	UIFeedback.punch(self, 0.18, 0.4)


func play_unlock() -> void:
	state = State.LOCKED
	var tw := create_tween()
	tw.tween_interval(0.45)
	tw.tween_method(func(t: float) -> void: lock_offset = Vector2(sin(t * 50.0) * 6.0 * (1.0 - t * 0.5), 0), 0.0, 1.0, 0.6)
	tw.tween_callback(func() -> void:
		lock_offset = Vector2.ZERO
		state = State.CURRENT
		flash = 1.0
		Sfx.play("unlock")
		Confetti.sparkle(self, global_position + badge_center, 26))
	tw.tween_property(self, "flash", 0.0, 0.5)


func _refresh() -> void:
	if not is_node_ready():
		return
	number_label.visible = state != State.LOCKED
	star_rating.visible = state == State.DONE
	title_label.modulate.a = 0.75 if state == State.LOCKED else 1.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := badge_center
	var r := badge_radius
	if state == State.CURRENT:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		for k in 3:
			draw_circle(c, r * (1.15 + k * 0.16 + pulse * 0.08), Color(0.35, 0.9, 1.0, 0.16 - k * 0.045))
	var fill := locked_color if state == State.LOCKED else (done_color if state == State.DONE else open_color)
	draw_circle(c + Vector2(0, 5), r + 5, UIStyle.INK)
	draw_circle(c, r + 5, UIStyle.INK)
	draw_circle(c, r, fill.darkened(0.25))
	draw_circle(c + Vector2(0, -3), r - 4, fill)
	draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.35))
	if state == State.LOCKED:
		UIDraw.lock(self, c + lock_offset, r * 1.1)
	elif state == State.CURRENT or state == State.OPEN:
		for k in 3:
			var a := _t * 1.2 + TAU * k / 3.0 + _phase
			var twinkle := 0.5 + 0.5 * sin(_t * 3.0 + k * 2.0)
			UIDraw.sparkle(self, c + Vector2(cos(a), sin(a)) * (r + 12), 3.0 + 5.0 * twinkle, Color(1, 1, 0.9, 0.5 + 0.5 * twinkle))
	_draw_kind_badge(c + Vector2(r * 0.85, r * 0.7))
	if flash > 0.0:
		draw_circle(c, r * (1.0 + (1.0 - flash) * 0.7), Color(1, 1, 1, flash))


func _draw_kind_badge(c: Vector2) -> void:
	draw_circle(c + Vector2(0, 3), 17, UIStyle.INK)
	draw_circle(c, 16, UIStyle.INK)
	draw_circle(c, 13, Color.WHITE)
	match kind:
		"crossword":
			for i in 4:
				var p := c + Vector2((i % 2) * 9 - 8, floori(i / 2.0) * 9 - 8)
				draw_rect(Rect2(p, Vector2(7, 7)), UIStyle.GOLD if i != 3 else Color("c9c1f2"))
		"memo":
			UIStyle.draw_text(self, "?", c + Vector2(0, 1), 22, UIStyle.PURPLE)
		"crypto":
			UIStyle.draw_text(self, "A_", c + Vector2(0, 1), 14, UIStyle.GREEN.darkened(0.2))
