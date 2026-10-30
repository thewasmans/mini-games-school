@tool
class_name MapTheme
extends Resource

enum Style { FOREST, LABORATORY, MECHANICS }

@export_group("Réglages")
## Univers des décors : forêt (biologie), laboratoire (chimie) ou mécanique (physique).
@export var style := Style.FOREST
## Couleurs du dessus des tuiles, piochées au hasard pour chaque tuile.
@export var tile_top_colors: Array[Color] = [Color("5f9e38"), Color("5f9e38"), Color("7aae40")]
## Couleur du haut des flancs des tuiles.
@export var tile_side_color := Color("c28650")
## Couleur du bas des flancs et de la roche sous les îles.
@export var tile_bottom_color := Color("5a3828")
## Couleurs des accessoires (fleurs, liquides, cristaux…), piochées au hasard.
@export var accent_colors: Array[Color] = [Color("ff8fa3"), Color("ffd84a")]
## Nombre d'accessoires posés sur chaque île de level.
@export_range(0, 6) var props_per_island := 3
## Couleur du haut du ciel.
@export var sky_top_color := Color("417bb2")
## Couleur de l'horizon.
@export var sky_horizon_color := Color("99c9d6")
## Couleur du fond, sous les îles (c'est elle qu'on voit le plus).
@export var ground_bottom_color := Color("337296")
## Couleur de la brume au loin.
@export var fog_color := Color("8abbcc")
## Couleur du soleil.
@export var sun_color := Color("ffd99f")
## Intensité du soleil.
@export_range(0.0, 3.0, 0.05) var sun_energy := 0.95
## Couleur de la lumière ambiante.
@export var ambient_color := Color("e0d6eb")
## Intensité de la lumière ambiante.
@export_range(0.0, 2.0, 0.05) var ambient_energy := 0.4
## Couleur des pierres d'un chemin pas encore ouvert.
@export var stone_color := Color("8a7d6b")
## Couleur des pierres d'un chemin ouvert.
@export var lit_stone_color := Color("ffd56a")
## Nombre de particules d'ambiance (pollen, bulles, étoiles).
@export_range(0, 200) var ambient_particles := 40
## Couleur des particules d'ambiance.
@export var particle_color := Color("fff2a8")
