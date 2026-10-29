class_name MenuCreditsUI
extends MenuUI

@export var contributors_panel: TitledPanel
@export var partners_panel: TitledPanel
@export var partners_grid: GridContainer
@export var empty_label: Label
@export var contributor_line_prefab: PackedScene
@export var partner_tile_prefab: PackedScene


func _refresh() -> void:
	var credits := game_manager.game_data.credits
	empty_label.visible = credits == null
	contributors_panel.visible = credits != null
	partners_panel.visible = credits != null
	if credits == null:
		return
	for child in contributors_panel.content.get_children() + partners_grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	for line_index in credits.contributors.size():
		var line := contributor_line_prefab.instantiate() as Label
		line.text = credits.contributors[line_index]
		contributors_panel.content.add_child(line)
		UIFeedback.pop_in(line, 0.15 + line_index * 0.07, 0.5)
	for partner_index in credits.partner_names.size():
		var logo: Texture2D = credits.partner_logos[partner_index] if partner_index < credits.partner_logos.size() else null
		var tile := partner_tile_prefab.instantiate() as PartnerTile
		tile.setup(credits.partner_names[partner_index], logo)
		partners_grid.add_child(tile)
		UIFeedback.pop_in(tile, 0.3 + partner_index * 0.08, 0.4)
