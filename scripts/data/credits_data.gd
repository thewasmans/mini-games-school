@tool
class_name CreditsData
extends Resource
## Contenu de l'écran Crédits.

## Une ligne par contributeur, par exemple « Développement — Prénom Nom ».
@export var contributors: PackedStringArray = PackedStringArray()
@export var partner_names: PackedStringArray = PackedStringArray()
## Logos des partenaires, dans le même ordre que partner_names. Un logo manquant affiche le nom.
@export var partner_logos: Array[Texture2D] = []
