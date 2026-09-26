class_name CryptoSlot
extends LineEdit

var minimum_click_width: float = 0.0

func _has_point(point: Vector2) -> bool:
	var extra_width := maxf(0.0, (minimum_click_width - size.x) / 2.0)
	return Rect2(Vector2(-extra_width, 0.0), Vector2(size.x + extra_width * 2.0, size.y)).has_point(point)
