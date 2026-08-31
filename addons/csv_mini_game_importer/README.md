# CSV Mini-Game Importer

Ajoute deux entrées dans le menu **Projet > Outils** :

- **Importer un mémo (CSV)…** → génère une ressource `MemoData`
- **Importer un crypto (CSV)…** → génère une ressource `CryptoData`

On choisit un fichier `.csv` (n'importe où sur le disque). Un panneau récapitulatif
s'affiche alors :

- un **marqueur de statut** en haut : vert `OK — aucun avertissement`, ou orange
  `ATTENTION — …` listant les avertissements (images manquantes, lignes ignorées,
  lignes en erreur) ;
- une ligne de synthèse (nombre de quiz / phrases détectés) ;
- **la liste numérotée des quiz détectés** (scroll list), chacun avec son état à droite :
  `image : <nom>` (vert), `image manquante : <nom>` (orange) ou `pas d'image` (gris) —
  pour le crypto : `indice : <texte>` ou `pas d'indice` ;
- en bas de la liste, les lignes en erreur (réponse non reconnue) qui ont été ignorées.

La fenêtre est bornée à 50 % de la taille de l'éditeur (elle ne peut pas grandir
au-delà) ; la liste défile à l'intérieur.

On confirme avec **Enregistrer la ressource…**, puis on choisit l'emplacement du `.tres`
(proposé dans `res://data/`). Le FileSystem est rescané automatiquement.

Si aucune entrée valide n'est trouvée, le panneau l'indique et le bouton
d'enregistrement est désactivé.

Ne pas placer les `.csv` sources dans le projet : Godot les importerait comme fichiers
de traduction. Ils sont lus depuis le système de fichiers, hors `res://`.

Séparateur `,`, `;` ou tabulation (détecté automatiquement sur la 1ʳᵉ ligne).
Le BOM UTF-8 éventuel est ignoré. Les guillemets `"` protègent un champ contenant
le séparateur.

## Format mémo

Colonnes : `Question ; A ; B ; C ; D ; Réponse ; nom image`.
Une ligne = une question (l'en-tête `Question;…` et les lignes vides sont ignorés).
Toutes les questions du fichier vont dans une seule ressource `MemoData`
(`questions: Array[MemoQuestionData]`), jouées à la suite.

```
Question;A;B;C;D;Réponse;nom image
Quel est l'état de l'eau à 0 °C ?;Solide;Liquide;Gazeux;Plasma;A;glace.png
Pourquoi s'alimenter ?;Pour jouer.;Pour vivre et grandir.;Pour grandir.;Pour boire.;Pour vivre et grandir.;
```

- `A`..`D` : le texte des quatre choix, dans l'ordre d'affichage (pas de mélange).
- `Réponse` : la lettre `A`, `B`, `C` ou `D`, ou le texte exact du bon choix.
- `nom image` : optionnel, vide = pas d'image. La résolution essaie, dans l'ordre :
  1. relatif **au dossier du CSV** (`<dossier du csv>/<nom image>`) ;
  2. `res://content/sprites/memo/<nom image>`.
  L'extension `.png` est ajoutée si le nom n'en a pas. Un chemin `res://…` ou un
  chemin absolu sont pris tels quels.
  Une image **dans le projet** (`res://…`) est référencée par fichier ; une image
  **hors projet** est chargée et **intégrée** dans le `.tres` (donnée embarquée).

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
