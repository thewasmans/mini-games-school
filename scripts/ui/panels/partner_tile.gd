@tool
class_name PartnerTile
extends PanelContainer
## Prefab de la tuile partenaire des crédits : logo, ou nom si le logo manque.

const SCENE := "res://scenes/ui/panels/partner_tile.tscn"


static func create(partner_name: String, logo: Texture2D) -> PartnerTile:
	var t: PartnerTile = load(SCENE).instantiate()
	t.setup(partner_name, logo)
	return t


func setup(partner_name: String, logo: Texture2D) -> void:
	tooltip_text = partner_name
	$Logo.texture = logo
	$Logo.visible = logo != null
	$Name.text = partner_name
	$Name.visible = logo == null
