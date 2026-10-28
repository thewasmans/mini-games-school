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
- Briques « juicy » : `UIStyle` (palette, police Fredoka, thème, panneaux `frame_box` / `inner_box` / `container_box` / `glass_box`, bannière), `UIDraw` (rectangles arrondis en dégradé, halos, icônes vectorielles, île-château), `JuicyButton` (dégradé, icônes gauche/droite, étincelles ; texte dessiné à la main), `TopBar`, `IconView`, `JuicyProgressBar`, `UIFeedback` (pop, punch, shake, breathe, texte flottant), `Confetti`, `AnimatedBackground` (décor : ciel, château, îles, livres).
- Aucune image n'est nécessaire pour l'UI : tout est dessiné en code. Police : `assets/fonts/Fredoka.ttf` (licence OFL, `assets/fonts/OFL.txt`).

## Conventions

- Typage statique partout, commentaires `##` en français.
- Les Controls ajoutés à un parent déjà dans l'arbre utilisent `set_anchors_and_offsets_preset()` (pas `set_anchors_preset()`, qui garde la taille actuelle).
- Les animations passent par `UIFeedback` ; les sons par `Sfx`.

## Outils

- `tools/build_fake_data.gd` : régénère les données de test (**écrase** `data/game_data.tres`).
  `godot --headless --path . --script res://tools/build_fake_data.gd`
- `tools/autoshot.tscn` : visite automatique avec captures d'écran.
  `godot --path . res://tools/autoshot.tscn -- <dossier>`
- `exemples_csv/` (ignoré par Godot via `.gdignore`) : CSV d'exemple pour l'import.
