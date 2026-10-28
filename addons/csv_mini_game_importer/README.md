# CSV Mini-Game Importer

**Projet → Outils → Importer un mini-jeu (CSV)…**

1. Choisis un fichier `.csv` **en dehors du projet** (sinon Godot l'importe comme traduction).
2. Le type de mini-jeu est détecté, un récapitulatif liste les entrées et les avertissements.
3. Enregistre le `.tres` (par défaut dans `res://data/minigames/`), puis ajoute-le à un `LevelData` dans `data/game_data.tres`.

Le titre du thème est déduit du nom du fichier (`la_cellule.csv` → « La cellule »). Il se modifie ensuite dans l'Inspector.

## Format

- Séparateur `;` (la virgule ou la tabulation sont aussi acceptées si la première ligne ne contient pas de `;`).
- Encodage UTF-8. Les lignes vides et celles qui commencent par `#` sont ignorées.
- Un champ peut être entouré de guillemets pour contenir un `;` : `"Vrai; ou faux ?"`.
- La première ligne peut être un en-tête. S'il commence par `mot`, `question` ou `phrase`, il fixe le type.

### Mots croisés — `mot ; indice`

```
mot;indice
Noyau;Il contient l'ADN de la cellule
Membrane;Elle entoure la cellule
```

Accents, espaces et tirets sont retirés de la réponse (`Arc-en-ciel` → `ARCENCIEL`). La grille est générée à l'import ; les mots qui ne croisent rien sont signalés comme isolés.

### Quiz — `Question ; A ; B ; C ; D ; Réponse ; nom image`

```
Question;A;B;C;D;Réponse;nom image
Quelle est l'unité de base du vivant ?;L'atome;La cellule;L'organe;Le tissu;B;cellule.png
```

- **Réponse** : `A`, `B`, `C`, `D`, `1`…`4`, ou le texte exact de la bonne réponse.
- **nom image** : optionnel. Cherché dans `res://content/images/` et ses sous-dossiers, avec ou sans extension (`png`, `jpg`, `jpeg`, `webp`, `svg`). Une image introuvable affiche l'image par défaut.

### Cryptogramme — `phrase ; indice`

```
ratio;0.4
phrase;indice
La cellule est l'unité de base du vivant.;Une phrase à connaître par cœur
```

La ligne `ratio` (optionnelle, 0.4 par défaut) règle la proportion de lettres cachées.

## Détection sans en-tête

1. Une ligne `ratio` → cryptogramme.
2. 6 colonnes ou plus → quiz.
3. Première colonne contenant des espaces sur la majorité des lignes → cryptogramme, sinon mots croisés.
