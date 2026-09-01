# CSV Mini-Game Importer

Ajoute une entrée dans le menu **Projet > Outils** :

- **Importer un mini-jeu (CSV)…**

On choisit un fichier `.csv` (n'importe où sur le disque). Le plugin **détecte
automatiquement** le type de mini-jeu et génère la ressource correspondante :

| Type détecté | Ressource | Format CSV |
|---|---|---|
| Mots croisés | `CrosswordData` | `mot ; indice` |
| Mémo (quiz)  | `MemoData`     | `Question ; A ; B ; C ; D ; Réponse ; nom image` |
| Crypto       | `CryptoData`   | `phrase ; indice` (+ ligne `ratio ; 0.4` optionnelle) |

### Détection

Basée sur la 1ʳᵉ ligne et le nombre de colonnes :

1. 1ʳᵉ cellule = `ratio` → **crypto** ;
2. une cellule d'en-tête vaut `question` / `réponse` → **mémo** ;
3. 1ʳᵉ cellule = `mot` / `word` → **mots croisés** ;
4. 1ʳᵉ cellule = `phrase` / `texte` → **crypto** ;
5. sinon, par nombre de colonnes : ≥ 6 → **mémo** ; ≤ 2 → **crypto** si la 1ʳᵉ
   colonne contient des phrases (espaces), sinon **mots croisés**.

Pour lever toute ambiguïté sur un fichier à 2 colonnes sans en-tête, ajouter une
ligne d'en-tête (`mot;indice` ou `phrase;indice`).

## Panneau récapitulatif

Après lecture du CSV, un panneau s'affiche :

- **type détecté** en tête (`Type détecté : Mémo (quiz)`) ;
- un **marqueur de statut** : vert `OK — aucun avertissement`, ou orange
  `ATTENTION — …` listant les avertissements (images manquantes, lignes ignorées,
  mots/phrases sans indice, lignes en erreur) ;
- une ligne de synthèse (nombre de mots / quiz / phrases) ;
- **la liste numérotée des entrées détectées** (scroll list), chacune avec son état
  à droite : `image : <nom>` / `image manquante : <nom>` / `pas d'image`, ou
  `indice : <texte>` / `pas d'indice` ;
- en bas, les lignes en erreur qui ont été ignorées.

La fenêtre est bornée à 50 % de la taille de l'éditeur ; la liste défile à l'intérieur.

On confirme avec **Enregistrer la ressource…**, puis on choisit l'emplacement du `.tres`
(proposé dans `res://data/`). Le FileSystem est rescané automatiquement.
Si le type n'est pas reconnu ou qu'aucune entrée valide n'est trouvée, le panneau
l'indique et le bouton d'enregistrement est désactivé.

## Notes CSV

- Ne pas placer les `.csv` sources dans le projet : Godot les importerait comme
  fichiers de traduction. Ils sont lus depuis le disque, hors `res://`.
- Séparateur `,`, `;` ou tabulation (détecté sur la 1ʳᵉ ligne). BOM UTF-8 ignoré.
  Les guillemets `"` protègent un champ contenant le séparateur.

## Format mémo

Colonnes : `Question ; A ; B ; C ; D ; Réponse ; nom image`.
Une ligne = une question (en-tête `Question;…` et lignes vides ignorés).
Toutes les questions vont dans une seule ressource `MemoData`
(`questions: Array[MemoQuestionData]`), jouées à la suite.

```
Question;A;B;C;D;Réponse;nom image
Quel est l'état de l'eau à 0 °C ?;Solide;Liquide;Gazeux;Plasma;A;glace.png
Pourquoi s'alimenter ?;Pour jouer.;Pour vivre et grandir.;Pour grandir.;Pour boire.;Pour vivre et grandir.;
```

- `A`..`D` : le texte des quatre choix, dans l'ordre d'affichage (pas de mélange).
- `Réponse` : la lettre `A`, `B`, `C` ou `D`, ou le texte exact du bon choix.
- `nom image` : optionnel, vide = pas d'image. Résolution, dans l'ordre :
  1. relatif **au dossier du CSV** (`<dossier du csv>/<nom image>`) ;
  2. `res://content/sprites/memo/<nom image>`.
  `.png` ajouté si le nom n'a pas d'extension ; un chemin `res://…` ou absolu est
  pris tel quel. Image **dans le projet** → référencée par fichier ; image **hors
  projet** → chargée et **intégrée** dans le `.tres`.

## Format crypto

Une ligne par phrase (`texte ; indice`, indice optionnel) :

```
ratio;0.4
phrase;indice
La dilatation thermique;Phénomène physique
L'énergie ne se perd jamais;Premier principe
```

- Le texte est stocké en entier ; le masquage aléatoire des lettres est fait au runtime.
- Ligne `ratio;<0..1>` optionnelle en tête → `hidden_letter_ratio` (défaut 0.4).
- En-tête `phrase;…` / `texte;…` ignoré.

## Format mots croisés

Une ligne par mot (`mot ; indice`) :

```
mot;indice
Orange;Agrume
Biologie;Science du vivant
```

- En-tête `mot;…` / `word;…` ignoré. Le mot est mis en majuscules.
- Toutes les entrées vont dans une `CrosswordData` (`clues: Array[WordData]`) ;
  la grille est générée au runtime par `CrosswordGenerator`.
