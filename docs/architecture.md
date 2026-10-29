# Architecture du projet

Ce document décrit l'architecture du jeu de révision (Godot 4.7, GDScript). Il s'adresse aux développeurs qui arrivent sur le projet. Les conventions de code sont résumées dans `CLAUDE.md` à la racine, et les risques connus sans garde-fou dans [points_d_attention.md](points_d_attention.md).

---

## 1. Vue d'ensemble

Le projet suit un **pattern de managers** :

- un `GameManager` central possède l'état du jeu (`GameState`) et sa configuration (`GameData`) ;
- il initialise, dans l'ordre, les managers spécialisés ;
- l'interface (menus, level et mini-jeux) est faite de **prefabs `.tscn` assemblés à la main** ; le code ne fait que les remplir et réagir à leurs signaux ;
- le contenu pédagogique est décrit par des ressources `.tres`, **une par fichier**, éditables dans l'Inspector.

```
Main (_ready)
 └─► GameManager.initialize()
      ├─ game_state = GameState.new(game_data)
      ├─ GameUIManager.initialize()   → instancie GameUI (menus), pilote la navigation
      ├─ LevelManager.initialize()    → instancie Level à la demande
      └─ emit initialized
```

---

## 2. Scène principale (`scenes/main.tscn`)

```
Main (main.gd)
├─ Global
│  └─ GameManager (game_manager.gd)
│     ├─ GameUIManager (game_ui_manager.gd)
│     └─ LevelManager (level_manager.gd)
├─ Background       ← AnimatedBackground : décor 3D low poly
├─ UI               ← parent de GameUI
└─ Level            ← parent des levels instanciés
```

**`Main`** ([scripts/main.gd](../scripts/main.gd)) appelle `game_manager.initialize()` puis, dans l'éditeur seulement, ajoute le panneau de debug (prefab `debug_helper.tscn`, touche F1).

Le seul autoload est **`Sfx`** : sons synthétisés au démarrage, joués avec `Sfx.play("pop")`.

---

## 3. Couches du code (`scripts/`)

| Dossier | Rôle |
|---|---|
| `managers/` | Orchestration : `GameManager`, `Manager` (base abstraite), `GameUIManager`, `LevelManager`, `Sfx` |
| `state/` | État de la partie : `GameState` |
| `data/` | Ressources de contenu : `GameData`, `SchoolYearData`, `SubjectData`, `LevelData`, `CreditsData` |
| `mini_games/` | Données et logique des mini-jeux, un sous-dossier par mini-jeu ; `MiniGameData` et `TextUtil` à la racine |
| `ui/` | Scripts des prefabs : menus (`menus/`), panneaux (`panels/`), mini-jeux, composants et utilitaires de dessin |
| `level/` | `Level` (l'écran qui contient un mini-jeu) et `VictoryBanner` |
| `helpers/` | Debug : `DebugHelper` et les cheats de chaque mini-jeu |

### 3.1 Managers

- **`Manager`** ([manager.gd](../scripts/managers/manager.gd)) : classe `@abstract`. Elle expose `game_state` et `game_data`, qui renvoient vers le `GameManager`. Chaque sous-classe surcharge `initialize(game_manager)` et appelle `super.initialize()` en premier.
- **`GameManager`** ([game_manager.gd](../scripts/managers/game_manager.gd)) :
  - Il exporte `game_data` et les managers ; le getter `managers` fixe l'ordre d'initialisation.
  - **Un nouveau manager doit être ajouté à la fois dans les exports et dans ce getter.** Le script est `@tool` : un `Manager` enfant absent du getter affiche un avertissement sur le nœud dans l'arbre de la scène.
- **`GameUIManager`** : instancie `game_ui.tscn` sous `UI`. C'est le **seul responsable de la navigation** entre menus et levels :
  - sur `GameUI.level_requested`, il cache les menus et appelle `LevelManager.start_level()` ;
  - sur `LevelManager.level_closed`, il réaffiche les menus (grille des levels mise à jour) ;
  - sur `GameUI.study_level_shown`, il teinte le ciel du décor (`AnimatedBackground.set_study_level`).
- **`LevelManager`** : `start_level(index)` instancie `level.tscn` sous `Level`, compose le titre (niveau d'études - année - matière - thème) et l'initialise. Il émet `level_started(level)`. Sur `Level.validated`, il appelle `GameState.complete_level()` ; sur `validated` ou `exited`, il libère le level et émet `level_closed`.

### 3.2 État : `GameState`

[game_state.gd](../scripts/state/game_state.gd) hérite de `RefCounted` et est recréé à chaque lancement à partir de `GameData`.

- **Sélection en cours :** `current_study_level`, `current_school_year`, `current_subject`, `current_level`, et `current_levels` (les levels de la matière).
- **Progression :** stockée par clé `Vector3i(niveau d'études, année, matière)` ; les nombres de levels sont toujours lus dans `GameData`.
- **Règles :** le level 0 est débloqué ; un level est débloqué si lui-même ou le précédent est terminé ; `unlock_all_levels()` débloque tout (debug).
- **Compteurs :** `completed_level_count()` et `level_count()` filtrent par niveau d'études, et facultativement par année et matière ; `total_progress()` alimente la pastille d'étoiles.
- **Signaux :** `level_unlocked`, `current_level_changed`, `all_levels_unlocked`.
- **Pas de sauvegarde.**

### 3.3 Données : hiérarchie du contenu

```
GameData (data/game_data.tres)
├─ primary_1 … primary_6           ┐
├─ secondary_1 … secondary_6       ├─ SchoolYearData (name, subjects)
├─ quadrimester_1 … quadrimester_6 ┘     └─ SubjectData (name, color, levels)
└─ credits (CreditsData)                      └─ LevelData (mini_game)
                                                   └─ MiniGameData (theme_title)
                                                        ├─ CrosswordData
                                                        ├─ MemoData
                                                        └─ CryptoData
```

- Les 18 champs d'années sont fixes (système scolaire belge). Un champ vide = année « Bientôt disponible ».
- **Un fichier par ressource**, rangé selon la hiérarchie :

```
data/game_data.tres                                GameData (références seulement)
data/secondaire/s4/s4.tres                         SchoolYearData
data/secondaire/s4/biologie/biologie.tres          SubjectData
data/secondaire/s4/biologie/level_01.tres          LevelData
data/secondaire/s4/biologie/01_la_cellule.tres     CrosswordData, MemoData ou CryptoData
```

Ajouter du contenu ne touche que les fichiers de la matière concernée. L'année d'un mini-jeu se déduit de sa place : il n'y a pas de champ pour la répéter.

---

## 4. Interface

Toutes les scènes d'interface sont dans `content/prefabs/ui/`. Elles s'ouvrent et se modifient dans l'éditeur ; les scripts exposent leurs nœuds en `@export` et leurs réglages dans un groupe « Réglages ».

### 4.1 Navigation des menus : `GameUI`

[game_ui.gd](../scripts/ui/game_ui.gd) est la racine de `game_ui.tscn`, qui contient un menu par étape (`menus/*.tscn`). Chaque menu hérite de `MenuUI` (barre du haut, signal `back_pressed`, `show_menu()` qui rafraîchit son contenu). Les menus sont pré-instanciés et montrés avec une transition glissée.

```
MenuStartUI ──play──► MenuStudyLevelsUI ──► MenuSchoolYearsUI ──► MenuSubjectsUI ──► MenuLevelsUI ──► Level
     └──credits──► MenuCreditsUI           (sauté s'il n'y a qu'une seule année)
```

- **Niveaux d'études et années :** les entrées (`choice_entry_ui.tscn` : bouton, jauge, « Bientôt disponible ») sont posées dans les prefabs ; leurs libellés, couleurs et icônes se règlent dans l'éditeur.
- **Matières :** une entrée par matière est instanciée depuis `choice_entry_ui.tscn`.
- **Grille des levels :** `LevelPath` dispose les `level_node.tscn` en serpent entre deux châteaux et anime le déblocage du level suivant.
- **Lancement d'un level :** `MenuLevelsUI` émet `level_selected` (ou secoue le cadenas si le level est verrouillé) ; `GameUI` sélectionne le level et émet `level_requested`.

### 4.2 Écran de level : `Level`

[level.gd](../scripts/level/level.gd), dans `level/level.tscn`, ne connaît ni le `GameManager` ni le debug :

- **Le mini-jeu :** il demande le prefab au registre `MiniGamePrefabs`, l'instancie et appelle `initialize(data)`.
- **La progression :** il anime la jauge sur `progress_changed`.
- **La fin :** sur `completed`, il affiche le bandeau « BRAVO ! » puis le bouton **Valider**, et émet `validation_available`. Valider émet `validated(level_index)` ; le retour émet `exited`.

### 4.3 Contrat d'un mini-jeu

Chaque interface hérite de la classe abstraite [`MiniGameUI`](../scripts/ui/mini_game_ui.gd) :

```gdscript
signal completed
signal progress_changed(completed_count: int, total_count: int)
@abstract func initialize(mini_game_data: MiniGameData) -> void
```

Le registre [`mini_game_prefabs.tres`](../content/prefabs/ui/mini_games/mini_game_prefabs.tres) associe chaque script de données à son prefab.

| Mini-jeu | Prefab et script | Données (`scripts/mini_games/`) |
|---|---|---|
| Mots croisés | `crossword_ui.tscn`, `crossword_cell.tscn` | `crossword/` : `CrosswordData`, `CrosswordEntry`, `CrosswordGenerator` |
| Quiz | `memo_ui.tscn` | `memo/` : `MemoData`, `MemoQuestion` |
| Cryptogramme | `crypto_ui.tscn`, `crypto_cell.tscn` | `crypto/` : `CryptoData`, `CryptoSentence` |

**La grille des mots croisés est calculée dans l'éditeur, pas pendant la partie** (plugin Crossword ou import CSV).

**Pour ajouter un mini-jeu :**
1. Créer une sous-classe de `MiniGameData` (avec `get_kind_name()` et `get_kind_id()`).
2. Créer une interface qui hérite de `MiniGameUI`, et son prefab.
3. Ajouter l'association script de données → prefab dans `mini_game_prefabs.tres`.
4. Facultatif : écrire un `MiniGameCheat` et l'ajouter à `DebugHelper._make_cheat()`.

### 4.4 Composants et utilitaires

- **`ButtonPressAnimation`** : composant à placer comme enfant d'un bouton dans un prefab (écrasement à l'appui, grossissement au survol, son). Un bouton sans ce composant n'a ni animation ni son.
- **`JuicyButton`** (`@tool`) : bouton du thème avec icônes, étincelles et reflet, visible tel quel dans l'éditeur.
- **`UIFeedback`** : animations à base de Tween (`pop_in`, `punch`, `shake`, `breathe`, `float_text`) ; **`Confetti`** : particules de victoire.
- **Thème** : `content/ui/game_theme.tres`, généré par `ThemeBuilder` à partir des PNG extraits des maquettes ; les prefabs choisissent une variation (`theme_type_variation`).
- **Décor** : `AnimatedBackground` (3D low poly construit en code par `LowPoly`), couleurs de ciel par niveau d'études réglables dans l'Inspector.

---

## 5. Outils de l'éditeur (`addons/`)

| Plugin | Accès | Rôle |
|---|---|---|
| **Crossword** (`crossword_editor/`) | Onglet de l'éditeur | Aperçu et génération de la grille, détection des mots isolés et des conflits. |
| **CSV Mini-Game Importer** (`csv_mini_game_importer/`) | Projet → Outils | Convertit un CSV en `CrosswordData`, `MemoData` ou `CryptoData` (voir son `README.md`). |
| **Outils du jeu** (`dev_tools/`) | Projet → Outils → Outils du jeu | Régénère le thème, extrait les PNG d'UI, lance la visite automatique avec captures. |
| **gdUnit4** (`gdUnit4/`, v6.2.2) | Onglet GdUnit | Framework de tests (section 7). |

---

## 6. Debug (`scripts/helpers/`)

- **`DebugHelper`** (`content/prefabs/ui/debug_helper.tscn`) : barre en bas de la fenêtre, au thème par défaut de Godot, créée par `Main` dans l'éditeur seulement. **F1** l'affiche ou la masque.
- **Options :** remplissage automatique, validation automatique, affichage de la réponse, **Unlock all levels**.
- **Liaison :** le helper écoute `LevelManager.level_started` ; le code du jeu ne le référence pas.
- **Cheats :** `CrosswordCheat`, `MemoCheat`, `CryptoCheat` (base `MiniGameCheat`) jouent le mini-jeu à la place du joueur et fournissent la réponse affichée.

---

## 7. Tests (`tests/`)

| Dossier | Contenu |
|---|---|
| `unit/` | `GameState`, `CrosswordGenerator`, `TextUtil`, parser CSV |
| `integration/` | Un level de quiz joué de bout en bout, la navigation depuis `main.tscn`, les cheats du panneau F1 |
| `content/` | Validation des vraies données de `data/` et des UID de toutes les scènes et ressources |
| `fixtures/` | `TestData` : petites données construites en code |

Lancer les tests : onglet **GdUnit** de l'éditeur, ou

```
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Ils tournent en CI à chaque push (`.github/workflows/tests.yml`).

---

## 8. Conventions principales

- **Pas de commentaires** dans le GDScript, sauf une ligne `##` sur chaque export du groupe **« Réglages »** (ce qu'un non-développeur peut ajuster ; affichée en infobulle dans l'Inspector).
- **Les `@export` sont toujours assignés** dans l'Inspector : pas de vérification de nullité.
- **Prefabs plutôt que code** : toute interface ajustable est une scène ; les comportements s'ajoutent comme composants visibles dans les prefabs.
- **Les UI** sont des `Control` avec un point d'entrée `initialize(...)` et remontent leurs actions par signaux.
- **`class_name` en PascalCase** et typage statique.
- **Les nouveaux fichiers** `.tscn` et `.tres` doivent être enregistrés une fois dans l'éditeur pour recevoir un UID.
