# Housing : plan d'implémentation

Ce plan met en œuvre la spec [housing.md](housing.md). Il suit l'architecture du projet : managers, `GameState` en `RefCounted`, données en `.tres` rangées dans `data/`, prefabs faits main, pas de commentaires, tests gdUnit4.

Le travail est découpé en 4 phases. Chaque phase se termine sur un jeu jouable et des tests verts.

| Phase | Contenu | Visible en jeu |
|---|---|---|
| 1 | Données, rencontres de mots, état du housing, sauvegarde | Rien (logique et tests) |
| 2 | Écran de fin de level avec les jauges, pastille de points d'action | Les jauges montent en fin de level |
| 3 | Maison 3D, character controller, placement, rénovation, inventaire | La maison est jouable |
| 4 | Contenu de la pièce Chimie (21 objets) | Pièce Chimie complète |

---

## Phase 1 : logique

### 1.1 Données (`scripts/data/housing/`)

- **`HousingItemData`** (`Resource`) : `word` (mot principal), `variants: PackedStringArray` (MOLES…), `title`, `description` (pancarte), `mnemonic`, `slot: Slot` (`FLOOR`, `WALL`, `CEILING`), `footprint: Vector2i` (cases occupées), `model: PackedScene`.
- **`HousingRoomData`** (`Resource`) : `items: Array[HousingItemData]`, `grid_size: Vector2i`, `renovations: Array[HousingRenovationData]`.
- **`HousingRenovationData`** (`Resource`) : `title`, `cost`, `cells: Array[Vector2i]` (cases libérées), `model_before`, `model_after`.
- **`SubjectData.housing_room: HousingRoomData`** : une pièce par matière, comme `map_theme`.
- Rangement : `data/<niveau>/<année>/<matière>/housing/room.tres` et `housing/<mot>.tres`.

### 1.2 Mots contenus dans un mini-jeu (données statiques)

- **`MiniGameData.answer_words() -> PackedStringArray`** (virtuelle), normalisée avec `TextUtil.to_answer` :
  - `CrosswordData` : les mots de la grille ;
  - `MemoData` : les mots des questions et des bonnes réponses ;
  - `CryptoData` : les mots des phrases.
- **`HousingCatalog`** (`RefCounted`, `scripts/state/`) : construit une fois depuis `GameData`. Pour chaque objet, la liste des levels de sa matière qui contiennent son mot, et la taille de sa jauge : `10 × min(nombre de levels, 3)`. Les deux valeurs sont des réglages de `HousingCatalog`.

### 1.3 Rencontres pendant la partie

- **`MiniGameUI.answer_words(answer_key) -> PackedStringArray`** (virtuelle) : les mots couverts par une réponse.
  - Mots croisés : le mot de l'entrée.
  - Quiz : les mots de la question et de la bonne réponse.
  - Cryptogramme : le mot de la phrase qui contient la lettre cachée. Un mot n'est rencontré que quand toutes ses lettres cachées sont trouvées ; un mot sans lettre cachée est rencontré quand la phrase est résolue.
- **`MiniGameUI.found_answers`** : à chaque réponse trouvée, les mots couverts, le nombre d'erreurs et l'indice éventuel.
- **`Level.word_points()`** : pour chaque mot, le **minimum** des points (`points_for(...)`) des réponses qui le couvrent. Un mot n'est jugé bon que si toutes ses lettres le sont. `LevelManager` le lit à la validation ; le signal `validated` ne change pas.

### 1.4 État du housing (`scripts/state/housing_state.gd`)

`HousingState` (`RefCounted`), créé par `GameManager` à côté de `GameState`, exposé par `Manager.housing_state`.

- **Jauges** : `_best_points[item_id][level_key] = points`. `record_encounters(level_key, word_points)` garde le meilleur score par level ; `gauge(item) -> Vector2i(valeur, taille)` ; `is_unlocked(item)`. Signal `item_unlocked(item)`.
- **Points d'action** : `action_points`, `record_level_result(level_key, first_completion, new_stars, stars, now)` selon le barème de la spec (section 5), avec `_last_played[level_key]` (date Unix) pour le bonus « pas revu depuis 7 jours ». Barème en constantes réglables.
- **Maison** : `_placements[room_id]` (objet → case, orientation), `_renovated[room_id]` ; `place_item`, `remove_item`, `move_item`, `renovate`. Chacun vérifie le coût, la place libre (cases, type d'emplacement) et rend `false` si l'action est impossible. Un objet retiré retourne dans l'inventaire.
- **Sauvegarde** : `to_save_data()` / `load_save_data()`. `SaveManager` passe à la version 2 du fichier avec un bloc `housing` et lit encore la version 1.

Clés : un objet est identifié par sa matière (`Vector3i`, comme la progression) et son mot (`HousingItemData.word`), par exemple `1/3/1/MOLE`. Réordonner les objets d'une pièce ne casse pas la sauvegarde ; réordonner les matières la casse, comme pour la progression.

### 1.5 Branchement

- `LevelManager._on_level_validated` : appelle `game_state.complete_level`, puis `housing_state.record_level_result` et `record_encounters`.
- `GameState.complete_level` rend les étoiles nouvellement gagnées, nécessaires au barème.

### 1.6 Tests

- `unit/state/housing_state_test.gd` : meilleur score par level, rejouer en boucle ne remplit pas, taille 10/20/30, déblocage, barème des points, bonus 7 jours, placement (chevauchement, type d'emplacement, coût, points insuffisants), sauvegarde aller-retour.
- `unit/mini_games/answer_words_test.gd` : `answer_words()` des trois types de données et des trois UI, dont le cas du mot sans lettre cachée dans le cryptogramme.
- `content/housing_content_test.gd` : chaque mot d'objet apparaît dans au moins un level de sa matière ; deux objets d'une même pièce n'ont pas le même mot ; chaque pièce peut contenir au moins un objet de chaque type d'emplacement une fois rénovée.

---

## Phase 2 : retours en fin de level

- **`level/discovery_panel.tscn`** (`DiscoveryPanel`) : affiché sous la `VictoryBanner`. Il montre les objets dont la jauge a monté (silhouette, `JuicyProgressBar` animée, « Nouvel objet ! » et `Sfx.play("unlock")` quand elle se remplit) et les points d'action gagnés, avec les bonus formulés positivement (« Révision : +2 »).
- **Pastille de points d'action** : un `Pill` dans `top_bar.tscn`, à côté de la pastille d'étoiles. Il faut une variation de thème `PillAction` dans `theme_builder.gd`, avec une icône.
- **Entrée de la maison** : un bouton « Maison » sur le menu principal (`menu_start_ui.tscn`), le menu des matières et la carte des levels (`menu_levels_ui.tscn`). Le bouton **Jouer** de la maison ramène à la carte de la matière en cours.
- Tests d'intégration : valider un level fait apparaître le panneau, et un objet débloqué y est annoncé.

---

## Phase 3 : la maison 3D

### 3.1 Navigation

- **`HouseManager`** (nouveau `Manager`, après `LevelManager`) : instancie `content/prefabs/house/house.tscn` sous un nouveau nœud `House` de `main.tscn`, cache les menus et `Background`, et les réaffiche à la sortie. Il fonctionne comme `LevelManager` (`house_closed`, `play_requested(subject)`).

### 3.2 Scène

- **`house.tscn`** (`House`) : la maison flottante, une pièce par matière (`room.tscn`, `HouseRoom`) reliée par des portes. Les pièces sont construites avec `LowPoly`, dans la direction artistique du jeu (aplats, palette chaude, soleil doré). Une pièce sans contenu reste fermée (porte condamnée) ; une matière commencée ouvre sa pièce.
- **Grille de la pièce** : sol, murs et plafond découpés en cases selon `HousingRoomData.grid_size`. Les zones abîmées (`HousingRenovationData`) bloquent leurs cases tant qu'elles ne sont pas rénovées.

### 3.3 Character controller à la troisième personne

- **`player_character.tscn`** (`PlayerCharacter`, `CharacterBody3D`) : modèle low poly de l'enfant, animations simples (repos, marche) faites par code ou par `AnimationPlayer`.
- **Caméra** : `SpringArm3D` derrière l'enfant (évite les murs), un peu en hauteur pour garder la vue diorama. Elle se recentre doucement derrière lui quand il marche.
- **Contrôles tactiles (portrait)** : joystick virtuel dans la moitié basse gauche (`touch_joystick.tscn`, `TouchJoystick`, prefab réutilisable) ; glisser ailleurs fait tourner la caméra. Au clavier et à la souris dans l'éditeur : ZQSD / flèches et clic droit glissé.
- **Interaction** : un `Area3D` devant l'enfant détecte la case, l'objet ou la zone abîmée la plus proche ; un bouton contextuel apparaît (« Placer », « Ranger », « Déplacer », « Rénover : 4 »). La case visée est surlignée, en rouge si l'objet ne rentre pas.

### 3.4 Interface de la maison (`content/prefabs/ui/house/`)

- **Barre du haut** : retour, nom de la pièce, compteur « Chimie : 4 / 21 objets », points d'action, bouton **Jouer**.
- **Inventaire** (`house_inventory.tscn`) : objets débloqués non placés, et silhouettes des objets à découvrir avec leur jauge, les levels qui contiennent le mot et un bouton **Jouer** vers le premier d'entre eux.
- **Pancarte** (`item_sign.tscn`) : toucher un objet posé affiche son titre, sa définition, son lien mnémotechnique et « Rejouer le level ».

### 3.5 Tests

- Intégration : entrer dans la maison et en sortir, un objet placé apparaît dans la pièce, une action refusée faute de points ne change rien, le bouton Jouer ouvre la carte de la matière.
- Le character controller est testé à la main (autoshot pour les captures).

---

## Phase 4 : contenu Chimie

- 21 `HousingItemData` (table de la spec, section 7) et la pièce `data/secondaire/s4/chimie/housing/room.tres`.
- 21 modèles low poly.
- Les zones à rénover de la pièce et leurs coûts.
- Réglage de la taille de la grille pour que les 21 objets ne tiennent pas tous sans rénovation.
- Mise à jour de `fonctionnement_du_jeu.md`, `docs/architecture.md` et `CLAUDE.md`.

---

## Décisions

- **Modèles 3D** : construits en code avec `LowPoly`. C'est une version de test ; des modèles de graphiste pourront les remplacer via `HousingItemData.model`.
- **Entrée de la maison** : un bouton « Maison » sur le menu principal, le menu des matières et la carte des levels.

## Avancement

- **Phase 1 : faite.** Données (`scripts/data/housing/`), `TextUtil.words` / `word_at`, `answer_words()` des données et des UI de mini-jeux, `Level.word_points()`, `HousingCatalog`, `HousingState`, branchement dans `LevelManager`, sauvegarde version 2. Tests : `unit/state/housing_state_test.gd`, `unit/mini_games/answer_words_test.gd`, `content/housing_content_test.gd`, ajouts dans `level_flow_test.gd` et `navigation_test.gd`.
- **Phase 2 : faite, sauf le bouton « Maison »**, reporté en phase 3 pour qu'il ouvre quelque chose. Panneau `level/discovery_panel.tscn` (`DiscoveryPanel`) et ligne `level/discovery_row.tscn` (`DiscoveryRow`) : après Valider, `LevelManager` appelle `Level.show_rewards(...)` s'il y a des points ou une jauge qui monte, et ferme le level sur `Level.rewards_closed` (bouton Continuer). Pastille `panels/action_points_pill.tscn` (`ActionPointsPill`, icône `house` ajoutée à `UIDraw`) dans `top_bar.tscn`, mise à jour par `MenuUI.show_menu()` et `LevelManager`. Elle réutilise la variation `PillStars` : une variation dédiée `PillAction` reste à ajouter dans `theme_builder.gd` si on veut une autre couleur. Le panneau F1 ferme les récompenses tout seul quand « valider automatiquement » est coché.
- **Phase 3 : faite (première version jouable).**
  - Navigation : bouton Maison (`TopBar.show_house`, coché sur l'accueil, les matières et la carte des levels) → `GameUI.house_requested` → `GameUIManager` → `HouseManager.open_house()` (nouveau manager, nœud `House` de `main.tscn`). Retour : menus réaffichés ; Jouer : `GameUI.open_subject_levels()` sur la carte de la matière, focalisée sur le level choisi.
  - `content/prefabs/house/house.tscn` (`House`) : monde 3D dans un `SubViewport`, HUD (retour, nom de la pièce, compteur d'objets, points d'action, Jouer, joystick, boutons d'action contextuels), inventaire et pancarte.
  - `HouseWorld` construit en code le hall du grand-père et une pièce par matière qui a des données, alignés et reliés par des portes ; une pièce de matière pas encore commencée reste fermée (mur et cadenas). Collisions, débris des rénovations, objets posés, fantôme vert ou rouge du placement.
  - `PlayerCharacter` (`player_character.tscn`) : `CharacterBody3D`, caméra sur `SpringArm3D`, ZQSD/flèches ou joystick (`TouchJoystick`), glisser sur l'écran pour tourner la caméra. L'enfant agit sur la case devant lui.
  - Modèles : provisoires, construits par `HouseModels` (caisse et sphère colorées, cadre au mur, suspension au plafond) tant que `HousingItemData.model` est vide.
  - Limite connue : joystick et rotation de caméra ne se font pas en même temps sur écran tactile (un seul doigt suivi).
- **Phase 4 : contenu en partie fait.** Pièce `data/secondaire/s4/chimie/housing/room.tres` (grille 6 × 6, 3 zones à rénover) et les 21 objets de la spec (titre, définition, lien mnémotechnique, pluriels en variantes). Les lustres font 4 × 4 au plafond : un seul tient à la fois, comme dans l'exemple de « Housing ». Les 21 modèles low poly sont construits en code par `ChemistryModels` (`scripts/house/chemistry_models.gd`), choisis par mot quand `HousingItemData.model` est vide ; `HouseModels` garde une forme générique pour les objets sans modèle. Conventions : au sol, origine au centre de l'emprise ; au mur, origine en bas au centre contre le mur ; au plafond, origine au point d'accroche. Tous font face à l'avant de la pièce. Une nouvelle matière ajoute sa propre classe de modèles. Test : `housing_content_test.gd` vérifie que chaque objet a un modèle. Debug F1 : « Maison : tout débloquer » remplit toutes les jauges et donne 50 points d'action (rouvrir la maison pour voir les pièces s'ouvrir).
