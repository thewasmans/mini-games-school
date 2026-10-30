class_name BonusIslandMarker
extends Control

enum State { LOCKED, READY, CLAIMED }

@export var icon_view: IconView
@export var count_label: Label

@export_group("Réglages")
## Centre de la bulle dans le marqueur : c'est ce point qui suit l'île 3D.
@export var bubble_center := Vector2(70, 42)
## Rayon de la bulle, en pixels.
@export var bubble_radius := 34.0
## Couleur de la bulle tant que les levels précédents ne sont pas tous terminés.
@export var locked_color := Color("8a93a6")
## Couleur de la bulle quand des bonus attendent d'être récupérés.
@export var ready_color := Color("ffd23f")
## Couleur de la bulle quand les bonus ont été récupérés.
@export var claimed_color := Color("4cc24a")

var state := State.LOCKED

var _t := 0.0


func _ready() -> void:
	pivot_offset = bubble_center


func setup(state_: State, pending_count: int, claimed_count: int) -> void:
	state = state_
	match state:
		State.LOCKED:
			count_label.text = "?"
		State.READY:
			count_label.text = "+%d" % pending_count
		State.CLAIMED:
			count_label.text = "×%d" % claimed_count
	icon_view.modulate = Color(0.75, 0.75, 0.8) if state == State.LOCKED else Color.WHITE
	queue_redraw()


func shake() -> void:
	UIFeedback.shake(self, 10.0, 0.35)


func celebrate(gained: int) -> void:
	UIFeedback.punch(self, 0.3, 0.6)
	Confetti.sparkle(self, global_position + bubble_center, 34)
	UIFeedback.float_text(self, "+%d indice%s" % [gained, "s" if gained > 1 else ""], UIStyle.YELLOW, 36)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := bubble_center
	var r := bubble_radius
	var fill := locked_color if state == State.LOCKED else (ready_color if state == State.READY else claimed_color)
	if state == State.READY:
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		for k in 3:
			draw_circle(c, r * (1.2 + k * 0.18 + pulse * 0.1), Color(1.0, 0.85, 0.3, 0.2 - k * 0.06))
	draw_circle(c + Vector2(0, 5), r + 5, UIStyle.INK)
	draw_circle(c, r + 5, UIStyle.INK)
	draw_circle(c, r, fill.darkened(0.25))
	draw_circle(c + Vector2(0, -3), r - 4, fill)
