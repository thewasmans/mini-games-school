class_name UIFeedback
extends RefCounted
## Animations de feedback réutilisables (apparition, secousse, rebond, texte flottant).


## Apparition avec dépassement (scale 0.6 -> 1 en TRANS_BACK).
static func pop_in(node: Control, delay := 0.0, from := 0.6) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2.ONE * from
	# Les écrans sont construits avant d'entrer dans l'arbre : on attend d'y être.
	if not node.is_node_ready():
		await node.ready
	await node.get_tree().process_frame
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2
	var tw := node.create_tween().set_parallel()
	tw.tween_property(node, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.18).set_delay(delay)


## Petit coup de scale élastique.
static func punch(node: Control, strength := 0.2, duration := 0.45) -> void:
	node.pivot_offset = node.size / 2
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE * (1.0 + strength), 0.07).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Secousse horizontale amortie. La position d'origine est restaurée à la fin.
static func shake(node: Control, strength := 14.0, duration := 0.45) -> void:
	if node.has_meta("_shake_tween"):
		var old: Tween = node.get_meta("_shake_tween")
		if old and old.is_valid():
			old.kill()
	if not node.has_meta("_shake_origin"):
		node.set_meta("_shake_origin", node.position)
	var origin: Vector2 = node.get_meta("_shake_origin")
	var tw := node.create_tween()
	tw.tween_method(func(t: float) -> void:
		node.position = origin + Vector2(sin(t * 38.0) * strength * (1.0 - t), 0), 0.0, 1.0, duration)
	tw.tween_callback(func() -> void:
		node.position = origin
		node.remove_meta("_shake_origin")
		node.remove_meta("_shake_tween"))
	node.set_meta("_shake_tween", tw)


## Pulsation en boucle (boutons à mettre en avant).
static func breathe(node: Control, amount := 0.05, period := 1.1) -> Tween:
	node.pivot_offset = node.size / 2
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2.ONE * (1.0 + amount), period / 2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, period / 2).set_trans(Tween.TRANS_SINE)
	return tw


## Texte qui monte et s'efface (« +1 », « Bravo ! »).
static func float_text(anchor: Control, text: String, color := UIStyle.YELLOW, size := 44) -> void:
	var l := UIStyle.label(text, size, color, 12)
	l.top_level = true
	l.z_index = 100
	anchor.add_child(l)
	l.reset_size()
	l.global_position = anchor.global_position + anchor.size / 2 - l.size / 2
	l.pivot_offset = l.size / 2
	l.scale = Vector2.ONE * 0.4
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position:y", l.global_position.y - 110, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


## Désactive les clics sur toute une branche (écran en train de partir).
static func disable_input(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		disable_input(child)
