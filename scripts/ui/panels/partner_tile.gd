@tool
class_name PartnerTile
extends PanelContainer


func setup(partner_name: String, logo: Texture2D) -> void:
	tooltip_text = partner_name
	$Logo.texture = logo
	$Logo.visible = logo != null
	$Name.text = partner_name
	$Name.visible = logo == null
