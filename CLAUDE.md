# Architecture

Godot 4.7, GDScript, portrait 720×1280 (`canvas_items`, `expand`). Le fonctionnement côté joueur est décrit dans `fonctionnement_du_jeu.md`.

## Lancement

`scenes/main.tscn` → `scripts/main.gd` → `GameManager.initialize()` puis `GameUI.new()`. Toute l'interface est construite en code (pas de scènes par écran).

## Autoloads

| Nom | Fichier | Rôle |
|---|---|---|
| `GameState` | `scripts/state/game_state.gd` | Progression en mémoire (clé `"étude/année/matière"`), non sauvegardée. |
| `Sfx` | `scripts/managers/sfx.gd` | Sons synthétisés au démarrage. `Sfx.play("pop")`. |
| `GameManager` | `scripts/managers/game_manager.gd` | Charge `data/game_data.tres`, porte les réglages du helper F1. |

## Données (`scripts/data/`)

`GameData` → `SchoolYearData` → `SubjectData` → `LevelData` → `MiniGameData` (`CrosswordData`, `MemoData`, `CryptoData`). Tous `@tool` pour être utilisables par les plugins. La grille des mots croisés est calculée par `CrosswordGenerator` dans l'éditeur, jamais en jeu (sauf repli avec avertissement si elle manque).

## UI (`scripts/ui/`)

- `game_ui.gd` : navigation par pile (`go_to` / `go_back`), chaque écran est reconstruit à l'affichage.
- `level/level.gd` : écran de level (titre, barre de progression, mini-jeu, Valider).
- Mini-jeux : `MiniGameUI` (base : signaux `progress_changed`, `completed`, hooks `debug_autofill` / `set_show_hints`), `crossword_ui.gd`, `memo_ui.gd`, `crypto_ui.gd`.
- Briques « juicy » : `UIStyle` (palette, accès au thème, fabriques `label` / `panel(variation)` / `pill` / `banner`), `UISkin` (couleur → variation `Button<Couleur>`, icônes `GameIcons`), `UIDraw` (rectangles arrondis en dégradé, halos, icônes vectorielles de repli), `JuicyButton` (fond + texte natifs du thème ; icônes gauche/droite, étincelles, reflet, rebond), `TopBar`, `IconView`, `JuicyProgressBar`, `UIFeedback` (pop, punch, shake, breathe, texte flottant), `Confetti`, `AnimatedBackground` (décor de fond en 3D low poly dans un `SubViewportContainer` : ciel procédural, brouillard, château sur île flottante, îles, nuages, livres volants, étincelles ; `set_colors()` teinte le ciel), `LowPoly` (modèles 3D construits en code : primitives converties en facettes à normales plates, sommets déformés, couleur par face).
- **Thème Godot** : `assets/ui/game_theme.tres`, thème du projet (`gui/theme/custom`), généré par `tools/build_theme.gd` à partir de `assets/ui/*.png` (extraits des maquettes `*.jpg` à la racine par `tools/extract_ui_assets.py`). Le code ne construit pas de StyleBox : il choisit une variation via `theme_type_variation`.
  - Button : `Button<Couleur>` (Blue, Orange, Green, Purple, Yellow, Red, Grey, Light, Navy), `ButtonPlay`, `ButtonKey`, `ButtonBack`, `ButtonGear`. `JuicyButton.color` choisit la plus proche, `JuicyButton.skin` en impose une.
  - PanelContainer : `PanelFrame` (défaut), `PanelTitled`, `PanelInner`, `PanelBig`, `PanelGlass`, `Pill`, `PillBlue`, `PillStars(Inner)`, `Tile`, `DebugPanel`, `Banner<Couleur>`. Panel : `Board`.
  - Icônes (sprites des contrôles dessinés à la main, lus par `get_theme_icon`) : `CrosswordCell`, `CryptoCell`, `LevelNode`, `LevelPath`, `DefaultQuizImage`, `GameIcons`. Si une icône manque, le dessin vectoriel prend le relais.
- Police : `assets/fonts/Fredoka.ttf` (licence OFL, `assets/fonts/OFL.txt`), graisse 650 via `assets/fonts/fredoka.tres` (police par défaut du thème).

## Régénérer le thème

```
python tools/extract_ui_assets.py             # PNG des skins (Pillow + numpy)
python tools/extract_ui_assets.py --sprites   # + sprites détourés (pip install "rembg[cpu]")
godot --headless --path . --script res://tools/build_theme.gd   # écrase game_theme.tres
```

Les boîtes de découpe sont en tête de chaque fonction (`skins()`, `SPRITES`) : à ajuster si les maquettes changent. Les marges 9-slice et les variations sont en tête de `tools/build_theme.gd`. Retoucher le `.tres` dans l'éditeur de thème est possible, mais une régénération l'écrase.

## Conventions

- Typage statique partout, commentaires `##` en français.
- Les Controls ajoutés à un parent déjà dans l'arbre utilisent `set_anchors_and_offsets_preset()` (pas `set_anchors_preset()`, qui garde la taille actuelle).
- Les animations passent par `UIFeedback` ; les sons par `Sfx`.
- Pas de `add_theme_stylebox_override` pour l'habillage : ajouter une variation dans `tools/build_theme.gd`.

## Outils

- `tools/build_fake_data.gd` : régénère les données de test (**écrase** `data/game_data.tres`).
  `godot --headless --path . --script res://tools/build_fake_data.gd`
- `tools/autoshot.tscn` : visite automatique avec captures d'écran.
  `godot --path . res://tools/autoshot.tscn -- <dossier>`
- `exemples_csv/` (ignoré par Godot via `.gdignore`) : CSV d'exemple pour l'import.
