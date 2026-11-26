class_name DiscoveryRow
extends HBoxContainer

@export var title_label: Label
@export var bar: JuicyProgressBar
@export var value_label: Label
@export var new_label: Label

var _before := 0
var _after := 0
var _size := 1


func initialize(title: String, before: int, after: int, size: int) -> void:
	_before = before
	_after = after
	_size = maxi(size, 1)
	title_label.text = title
	value_label.text = "%d / %d" % [_before, _size]
	new_label.hide()
	bar.set_value(_before / float(_size), false)


func play() -> void:
	bar.set_value(_after / float(_size))
	var tween := create_tween()
	tween.tween_method(_show_value, _before, _after, 0.7)
	if is_unlocked():
		tween.tween_callback(_announce_new_item)


func is_unlocked() -> bool:
	return _before < _size and _after >= _size


func _show_value(value: int) -> void:
	value_label.text = "%d / %d" % [value, _size]


func _announce_new_item() -> void:
	new_label.show()
	UIFeedback.pop_in(new_label)
	Sfx.play("unlock")
