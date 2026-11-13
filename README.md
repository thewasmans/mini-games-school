# Mini Games School

Jeu éducatif réalisé avec **Godot 4.7** (GDScript) qui propose des mini-jeux de révision classés par niveau d'études, année scolaire et matière.

- **Mots croisés** (`crossword`) : retrouver des mots à partir de leurs indices.
- **Mémo / quiz** (`memo`) : questions à choix multiples, avec image en option.
- **Crypto** (`crypto`) : déchiffrer une phrase codée.

Le jeu est pensé en format portrait (540 × 960) et s'exporte vers Windows, Linux, le Web et Android.

## Liens

- **Jouer sur itch.io** : https://the-wasmans.itch.io/mini-game-school
- **Documentation du projet (Notion)** : https://app.notion.com/p/Mini-jeux-sciences-39ef76320d2b80788e59d4293c7f76c2

## Démarrage

1. Installer [Godot 4.7](https://godotengine.org/download).
2. Cloner le dépôt :
   ```bash
   git clone https://github.com/thewasmans/mini-games-school.git
   ```
3. Ouvrir `project.godot` dans Godot, puis lancer le jeu avec **F5**. La scène principale est `scenes/main.tscn`.

Le dépôt n'a ni tests automatisés ni linter : on vérifie les changements en lançant le projet dans l'éditeur.

## Organisation du contenu

Le contenu pédagogique est rangé de manière hiérarchique :

```
Niveau d'études (Primaire, Secondaire, Supérieur)
└── Année scolaire (P1…P6, S1…S6, Q1…Q6)
    └── Matière (ex. Biologie)
        └── Niveaux
            └── Mini-jeux
```

Les données sont des ressources Godot (`.tres`) rangées dans `data/` (par exemple `data/secondaire/s4/`). Le point d'entrée est `data/game_data.tres`, qu'on modifie dans l'Inspector.

## Ajouter du contenu

### Importer un mini-jeu depuis un CSV

Le plugin **CSV Mini-Game Importer** ajoute l'entrée **Projet > Outils > Importer un mini-jeu (CSV)…**. Il détecte le type de mini-jeu et génère la ressource correspondante :

| Mini-jeu | Format CSV |
|---|---|
| Mots croisés | `mot ; indice` |
| Mémo (quiz) | `Question ; A ; B ; C ; D ; Réponse ; nom image` |
| Crypto | `phrase ; indice` (+ ligne `ratio ; 0.4` optionnelle) |

Le format complet et les règles de détection sont décrits dans [addons/csv_mini_game_importer/README.md](addons/csv_mini_game_importer/README.md).

### Éditer les mots croisés

Les grilles sont générées dans l'éditeur, pas pendant le jeu. L'onglet principal **Crossword** (plugin `addons/crossword/`) permet de prévisualiser une grille et de la régénérer. La position de chaque mot est enregistrée dans la ressource.

## Architecture

Le projet utilise un système de **managers** :

- `GameManager` (`scripts/managers/game_managers.gd`) crée le `GameState` à partir du `GameData`, puis initialise chaque manager dans l'ordre.
- Les managers (`GameUIManager`, `LevelManager`, …) héritent de la classe abstraite `Manager` et ont accès à `game_state` et `game_data`.
- `GameData` (`Resource`) contient la configuration et le contenu modifiables, et `GameState` l'état du joueur pendant la partie (niveaux débloqués, progression).

| Dossier | Contenu |
|---|---|
| `scenes/` | Scène principale |
| `scripts/managers/` | `GameManager` et managers |
| `scripts/data/`, `scripts/state/` | Classes de données et d'état |
| `scripts/mini_games/` | Logique et données de chaque mini-jeu |
| `scripts/ui/` | Scripts des menus et des interfaces de mini-jeux |
| `scripts/helpers/` | Outils de debug et triches de test |
| `content/` | Prefabs, thème, sprites, sons, shaders, matériaux |
| `data/` | Ressources `GameData` et contenu pédagogique |
| `addons/` | Plugins d'éditeur (mots croisés, import CSV) |

Pour les détails et conventions de code (pas de commentaires, enregistrement d'un nouveau manager, etc.), voir [CLAUDE.md](CLAUDE.md).

## Build et déploiement

Les presets d'export (`export_presets.cfg`) produisent les builds dans `build/<plateforme>/`.

Le workflow GitHub Actions [`.github/workflows/build-deploy.yml`](.github/workflows/build-deploy.yml) se lance à chaque Pull Request mergée dans `develop`, ou à la main via *Run workflow*. Il exporte les quatre plateformes et les publie sur itch.io avec butler.

Secrets à configurer dans *Settings > Secrets and variables > Actions* :

| Secret | Rôle |
|---|---|
| `BUTLER_API_KEY` | Clé API itch.io |
| `ITCH_USERNAME` | Identifiant itch.io |
| `ITCH_GAME` | Slug du jeu sur itch.io |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_USER`, `ANDROID_KEYSTORE_PASSWORD` | Optionnels : signature release de l'APK (sinon clé debug) |

## Workflow Git

- Branche principale : `develop`.
- Une branche `feature/<nom>` par changement, intégrée par Pull Request vers `develop`.
