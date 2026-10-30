# Architecture

Godot 4.7, GDScript, portrait 720×1280 (`canvas_items`, `expand`). Le fonctionnement côté joueur est décrit dans `fonctionnement_du_jeu.md`, l'architecture détaillée dans `docs/architecture.md`, les risques sans garde-fou dans `docs/points_d_attention.md`.

## Lancement

`scenes/main.tscn` → `Main._ready()` → `GameManager.initialize()`, puis le panneau F1 (`DebugHelper`) dans l'éditeur seulement.

```
Main (main.gd)
├─ Global
│  ├─ GameManager
│  │  ├─ GameUIManager   instancie game_ui.tscn sous UI, pilote la navigation menus <-> level
│  │  └─ LevelManager    instancie level.tscn sous Level
│  └─ ManagersValidator  (@tool) vérifie la liste des managers dans l'éditeur
├─ Background            AnimatedBackground (décor 3D)
├─ UI
└─ Level
```

- **Managers** : `Manager` (`@abstract`) expose `game_state` / `game_data`. Un nouveau manager s'ajoute dans la liste exportée `managers` de `GameManager` (seule référence, qui fixe aussi l'ordre d'initialisation) ; si d'autres scripts doivent y accéder, ajouter un getter typé comme `level_manager`. Le nœud `Global/ManagersValidator` (`@tool`) affiche un avertissement si un `Manager` enfant manque dans la liste ou y figure deux fois ; `GameManager` n'est pas `@tool`.
- **Navigation** : `GameUI.level_requested` → `GameUIManager` cache les menus et appelle `LevelManager.start_level()`. `Level` émet `validated(level_index, stars)` / `exited` / `hint_requested` ; `LevelManager` termine le level dans `GameState` (meilleures étoiles), dépense les bonus pour les indices, libère le level et émet `level_closed` → menus réaffichés.
- **Autoload** : seulement `Sfx` (`scripts/managers/sfx.gd`, sons synthétisés, `Sfx.play("pop")`).

## État et données

- `GameState` (`scripts/state/`, `RefCounted`) : créé par `GameManager` depuis `GameData`. Sélection courante (niveau d'études, année, matière, level), progression par `Vector3i` (étoiles par level, îles bonus récupérées), compteur de bonus, signaux `level_unlocked`, `current_level_changed`, `all_levels_unlocked`, `bonus_count_changed`. Îles bonus tous les `SubjectData.bonus_island_interval` levels ; récompense = moyenne d'étoiles du groupe arrondie à l'inférieur. Les nombres de levels sont lus dans `GameData`, jamais copiés. Pas de sauvegarde.
- `GameData` (`scripts/data/`) → `SchoolYearData` → `SubjectData` → `LevelData` → `MiniGameData` (`scripts/mini_games/` : `crossword/`, `memo/`, `crypto/`). Les 18 champs d'années sont fixes (système scolaire belge) : c'est voulu.
- **Un fichier par ressource**, rangé selon la hiérarchie : `data/<niveau>/<année>/<année>.tres`, `data/<niveau>/<année>/<matière>/<matière>.tres`, `level_NN.tres` et les mini-jeux `NN_<type>_<thème>.tres` à côté. Les levels sont courts et grandissent peu à peu, commencent par un cryptogramme et alternent les types (vérifié par `game_data_content_test.gd`). `game_data.tres` ne contient que des références. L'année d'un mini-jeu se déduit de sa place dans la hiérarchie.
- La grille des mots croisés est calculée par `CrosswordGenerator` dans l'éditeur (plugin Crossword ou import CSV), jamais en jeu (sauf repli avec avertissement).

## Interface : prefabs faits main (`content/prefabs/ui/`)

Les écrans sont des scènes modifiables dans l'éditeur ; le code ne fait que les remplir.

- `game_ui.tscn` (`GameUI`) contient un menu par étape (`menus/*.tscn`, scripts `scripts/ui/menus/`, base `MenuUI` : `top_bar`, `back_pressed`, `show_menu()` → `_refresh()`). Les menus sont pré-instanciés, montrés / cachés avec une transition glissée.
- Carte des levels : `level_map/level_map.tscn` (`LevelMap`, 3D low poly dans un `SubViewport`, îles et chemins construits avec `LowPoly`), marqueurs 2D `level_map/level_marker.tscn` et `level_map/bonus_island_marker.tscn` qui suivent les îles.
- Univers de la carte par matière : `SubjectData.map_theme` → `MapTheme` (`content/map_themes/*.tres` : style forêt / laboratoire / mécanique, couleurs des tuiles, ciel, lumière, chemin, particules). `MapProps` construit les accessoires, les repères (départ, arrivée, îles bonus) et l'ambiance de chaque style ; `MapAnimations` anime ce qui bouge (engrenages, bulles, orbites). Nouvelle matière = nouveau `MapTheme`.
- Briques : `top_bar.tscn`, `choice_entry_ui.tscn` (bouton + jauge + « Bientôt disponible »), `keyboard_key.tscn`, `contributor_line_ui.tscn`, `default_quiz_image.tscn`, `panels/*.tscn` (`TitledPanel`, `FramePanel`, `MenuPanel`, `TitleBanner`, `Pill`, `StarsPill`, `PartnerTile`, `OnScreenKeyboard`).
- `level/level.tscn` (`Level`) : barre du haut, titre, jauge d'étoiles `star_gauge.tscn` (`StarGauge` : une `JuicyProgressBar` et les étoiles posées sur ses paliers), bouton indice, conteneur du mini-jeu, Valider ; `level/victory_banner.tscn`.
- Mini-jeux : `mini_games/*_ui.tscn`, scripts héritant de `MiniGameUI` (`@abstract`, signaux `completed` / `progress_changed(completed_count, total_count)` / `mistake_made` / `answer_found(mistake_count, hinted)`, `initialize(mini_game_data)` qui fixe `answer_total`, `use_hint() -> bool`, et pour chaque réponse (question, mot, lettre cachée) `_make_mistake(clé)`, `_mark_hinted(clé)`, `_answer_found(clé)`). `Level` convertit les réponses en points (10 sans erreur, 5 après 1 erreur, 2 après 2, 0 au-delà, 4 au plus avec un indice) rapportés au score maximum du level ; la jauge `StarGauge` monte avec le score et porte les étoiles à 30 %, 60 % et 90 % : seule une étoile atteinte par la jauge est gagnée. `Level` choisit le prefab dans le registre `mini_games/mini_game_prefabs.tres` (`MiniGamePrefabs`, script de données → prefab). Ajouter un mini-jeu = données + interface + entrée du registre (+ cheat), sans toucher à `Level`.
- Composants posés explicitement dans les prefabs : `ButtonPressAnimation` (enfant d'un bouton : écrasement, survol, son), jamais de script global qui modifie les nœuds.
- Debug F1 : `content/prefabs/ui/debug_helper.tscn` (`scripts/helpers/`), barre en bas au thème par défaut de Godot. Elle écoute `LevelManager.level_started` et utilise un `MiniGameCheat` par mini-jeu (`CrosswordCheat`, `MemoCheat`, `CryptoCheat`).

## Thème et rendu

- **Thème Godot** : `content/ui/game_theme.tres` (thème du projet), généré par `ThemeBuilder` (addon `dev_tools`) à partir de `content/ui/*.png`. Variations : `Button<Couleur>`, `ButtonPlay`, `ButtonKey`, `ButtonBack`, `ButtonGear` ; `PanelFrame`, `PanelTitled`, `PanelInner`, `PanelBig`, `PanelGlass`, `Pill`, `PillBlue`, `PillStars(Inner)`, `Tile`, `Banner<Couleur>`, `Board` ; icônes `CrosswordCell`, `CryptoCell`, `DefaultQuizImage`, `GameIcons`.
- `JuicyButton` (`@tool`) : fond et texte natifs du thème, icônes, étincelles, reflet. `color` choisit la variation la plus proche, `skin` en impose une.
- Dessin à la main : `UIDraw` (dont `rating_star`), `UIStyle` (palette, `draw_text`), `StarRating`, `StarGauge`, `LevelMarker`, `BonusIslandMarker`, cases, `ProgressRing`, `JuicyProgressBar`, `VictoryBanner`.
- `AnimatedBackground` : décor 3D low poly construit en code (`LowPoly`) ; couleurs du ciel par niveau d'études en réglages exportés.
- **Direction artistique 3D** : low poly en diorama de plateau, dans l'esprit de For the King. Îles en tuiles hexagonales en terrasses (`LowPoly.island`), facettes en aplats, palette chaude, soleil doré, vue oblique. La scène reste lumineuse : la chaleur vient des couleurs, pas de l'assombrissement. Les couleurs de sommets sont en sRGB (`vertex_color_is_srgb`), donc la palette de `LowPoly` s'affiche telle quelle.
- Police : `content/fonts/Fredoka.ttf` (OFL), graisse 650 via `content/fonts/fredoka.tres`.

## Conventions

- **Pas de commentaires** dans le GDScript. Seule exception : une ligne `##` sur chaque export du groupe `@export_group("Réglages")` (infobulle de l'Inspector), réservé à ce qu'un non-développeur peut ajuster. Les exports d'assemblage (nœuds, prefabs) restent sans commentaire.
- **Les `@export` sont toujours assignés** dans l'Inspector : pas de test de nullité sur un export (voir `docs/points_d_attention.md`).
- Typage statique, `class_name` en PascalCase, point d'entrée `initialize(...)` appelé par celui qui instancie ; les UI remontent leurs actions par signaux.
- Prefabs plutôt qu'UI construite en code ; comportements ajoutés comme composants visibles dans les prefabs.
- Ressources du jeu dans `content/`, données dans `data/`.
- Pas de `add_theme_stylebox_override` pour l'habillage : ajouter une variation dans `addons/dev_tools/theme_builder.gd`.
- Nouveaux `.tscn` / `.tres` : les enregistrer une fois dans l'éditeur pour qu'ils aient un UID (`scripts/tests/content/resource_uid_test.gd` le vérifie).

## Tests (gdUnit4, `scripts/tests/`)

`unit/` (logique pure), `integration/` (prefabs et `main.tscn` pilotés, cheats F1), `content/` (vraies données et UID), `fixtures/` (`TestData`). Onglet GdUnit de l'éditeur, ou :

```
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://scripts/tests --ignoreHeadlessMode
```

Lancés en CI par `.github/workflows/tests.yml`. Rapports dans `reports/` (ignoré par git).

## Outils (addon `addons/dev_tools`, menu Projet > Outils > Outils du jeu)

- `ThemeBuilder` : régénère le thème et la police (écrase `game_theme.tres` en gardant les UID).
- `cli.gd` : `godot --headless --path . --script res://addons/dev_tools/cli.gd -- theme`
- `extract_ui_assets.py` : PNG d'UI extraits des maquettes (`python addons/dev_tools/extract_ui_assets.py [--sprites]`).
- `autoshot/autoshot.tscn` : visite automatique avec captures (`godot --path . res://addons/dev_tools/autoshot/autoshot.tscn -- <dossier>`).
- `exemples_csv/` (ignoré par Godot via `.gdignore`) : CSV d'exemple pour l'import.
