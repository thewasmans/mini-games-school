# Fonctionnement du jeu

Ce jeu éducatif propose des mini-jeux de révision : mots croisés, quiz et cryptogrammes. Ils sont classés par niveau d'études, par année et par matière. Le joueur avance level par level. Terminer un level débloque le suivant.

Ce document décrit le parcours du joueur, les règles de chaque mini-jeu, l'organisation du contenu et les outils disponibles dans l'éditeur Godot.

---

## 1. Parcours du joueur

```
Menu principal ─► Niveau d'études ─► Année ─► Matière ─► Grille des levels ─► Level (mini-jeu)
   │                (Primaire,        (P1…P6,   (Biologie,    (carte 3D d'îles     │
   └─► Crédits       Secondaire,       S1…S6,    Chimie,       et îles bonus)       └─► retour à la grille
					 Supérieur)        Q1…Q6)    Physique…)
```

1. **Menu principal**
   - **PLAY** lance le parcours.
   - **CRÉDITS** affiche les contributeurs et les logos des partenaires.
2. **Niveau d'études** : Primaire, Secondaire ou Supérieur. Une jauge sous chaque bouton montre la progression dans ce niveau (levels terminés sur levels disponibles).
3. **Année** : P1 à P6 pour le Primaire, S1 à S6 pour le Secondaire, quadrimestres Q1 à Q6 pour le Supérieur. Si un niveau d'études n'a qu'une seule année, ce menu est sauté.
4. **Matière** : par exemple Biologie, Chimie ou Physique.
5. **Grille des levels** : une carte 3D low poly. Chaque level est une île flottante reliée à la suivante par un chemin de pierres, de la maison de départ jusqu'au château d'arrivée. On fait défiler la carte en glissant ou à la molette. Une île verrouillée n'est pas jouable, le level en cours est mis en évidence, et un level terminé affiche ses étoiles. Entre certains levels, une **île bonus** avec un château donne des indices (voir la section 3).
6. **Level** :
   - **Titre :** il rappelle le niveau d'études, l'année, la matière et le thème, par exemple « Secondaire - S4 - Biologie - La cellule ».
   - **Jauge d'étoiles :** une jauge qui monte à chaque bonne réponse, avec trois étoiles posées dessus. Une étoile s'allume quand la jauge l'atteint.
   - **Indice :** le bouton ampoule dépense un indice. Il révèle une lettre (mots croisés, cryptogramme) ou écarte une mauvaise réponse (quiz). Une réponse obtenue avec un indice rapporte moins de points, mais ne compte pas comme une erreur.
   - **Fin :** quand le mini-jeu est réussi, le bouton **Valider** termine le level et ramène à la grille.
   - **Retour :** le bouton retour quitte le level sans le terminer.

**Contenu à venir :** un niveau d'études, une année ou une matière sans level a son bouton désactivé. Le libellé **« Bientôt disponible »** s'affiche dessous.

---

## 2. Les mini-jeux

Chaque level contient un mini-jeu. Une fois le mini-jeu réussi, le bouton Valider du level apparaît.

### Mots croisés

- **Choisir un mot :** le joueur clique sur une case de la grille. Le mot qui passe par cette case est sélectionné et son indice s'affiche, avec la direction (horizontal ou vertical). Si deux mots se croisent sur la case, un nouveau clic passe de l'un à l'autre.
- **Saisir le mot :** le joueur tape le mot, et les lettres apparaissent dans la grille au fur et à mesure.
- **Vérification :** le mot est vérifié dès que toutes ses lettres sont tapées.
  - S'il est faux, il tremble et s'affiche en rouge, et le joueur peut corriger.
  - S'il est juste, ses lettres passent au style « validé » avec une petite animation.
- **Changer de mot :** ce que le joueur a tapé dans un mot est gardé s'il passe à un autre mot.
- **Fin :** une vague d'animation et des confettis saluent la grille complète.

La grille s'adapte à la taille de l'écran. Elle est calculée à l'avance dans l'éditeur, et pas pendant la partie (voir la section 4).

### Quiz (mémo)

- **La question :** une question s'affiche, accompagnée d'une image ou de l'image par défaut, avec 4 réponses.
- **Mauvaise réponse :** le bouton tremble, devient rouge et se désactive. Le joueur peut réessayer avec les autres réponses.
- **Bonne réponse :** le bouton s'anime en vert et la question suivante arrive.
- **Fin :** des confettis s'affichent après la dernière question.

### Cryptogramme

- **Le principe :** une phrase s'affiche avec une partie des lettres cachées. La proportion de lettres cachées est réglable, et les lettres sont tirées au hasard à chaque partie. Un indice aide à retrouver la phrase.
- **Saisie :**
  - Le joueur tape une lettre dans chaque case vide. Le curseur passe automatiquement à la case suivante, et Retour arrière revient à la case précédente.
  - Une lettre tapée prend le même style que les lettres déjà visibles, pour que la phrase reste lisible. Cliquer dessus la rend de nouveau modifiable.
- **Vérification :** quand toutes les cases sont remplies, la phrase est vérifiée.
  - Les lettres justes passent en vert.
  - Seules les lettres fausses passent en rouge, et un bouton **« Corriger les erreurs »** apparaît. Ce bouton efface les lettres fausses, place le curseur sur la première et disparaît.
- **Suite :** quand la phrase est juste, le bouton **Valider** passe à la phrase suivante. Des confettis s'affichent après la dernière.

---

## 3. Progression

- Dans chaque matière, le premier level est toujours débloqué. Terminer un level débloque le suivant et le sélectionne.
- **Points et étoiles :** chaque bonne réponse (une question du quiz, un mot des mots croisés, une lettre du cryptogramme) rapporte des points selon le nombre d'erreurs faites dessus : 10 sans erreur, 5 après 1 erreur, 2 après 2 erreurs, 0 au-delà. Avec un indice, elle rapporte au plus 4 points. Un level sans faute remplit la jauge (3 étoiles) ; avec trop de fautes, la jauge n'atteint aucune étoile. La jauge monte avec les points gagnés, par rapport au score maximum du level. Les étoiles sont posées sur la jauge à 30 %, 60 % et 90 % : une étoile n'est gagnée que si la jauge l'a atteinte à la fin du level. Rejouer un level ne garde que le meilleur résultat.
- **Îles bonus :** une île est placée après chaque groupe de levels (5 par défaut, réglable par matière avec « Bonus Island Interval »). Quand tous les levels du groupe sont terminés, toucher l'île donne autant d'indices que la moyenne d'étoiles du groupe, arrondie à l'inférieur : 1 indice pour une moyenne de 1 étoile, 3 pour 3 étoiles. Après avoir amélioré ses étoiles, on peut revenir chercher les indices manquants.
- **Indices :** ils sont communs à toutes les matières. La pastille de la grille des levels en affiche le nombre.
- La progression est suivie séparément pour chaque combinaison de niveau d'études, d'année et de matière.
- Les jauges du menu des niveaux d'études additionnent les levels terminés de toutes les années et de toutes les matières.
- **La progression n'est pas sauvegardée** : elle repart de zéro à chaque lancement du jeu.

---

## 4. Ajouter du contenu

Tout le contenu se règle dans l'Inspector de Godot, sans toucher au code.

### Organisation des données

Le fichier `data/game_data.tres` (`GameData`) contient un champ par année, regroupés en trois catégories :

| Catégorie dans l'Inspector | Champs | Niveau d'études |
|---|---|---|
| Level Primary   | `primary_1` … `primary_6`           | Primaire   |
| Level Secondary | `secondary_1` … `secondary_6`       | Secondaire |
| Level Higher    | `quadrimester_1` … `quadrimester_6` | Supérieur  |

Le contenu s'emboîte ainsi :

```
Année (SchoolYearData : nom, ex. « S4 »)
└─ Matières (SubjectData : nom, ex. « Biologie »)
   └─ Levels (LevelData)
	  └─ Mini-jeu (CrosswordData, MemoData ou CryptoData : année scolaire et titre du thème)
```

- **Un champ d'année peut rester vide.** L'année apparaît alors dans le menu comme « Bientôt disponible », avec un nom automatique (P1, S2, Q3…).
- **Donne un nom à chaque année que tu crées**, par exemple « S5 ». Ce nom s'affiche dans les menus et dans le titre des levels.
- L'ordre des levels dans une matière est l'ordre de la liste dans l'Inspector.

### Créer un mini-jeu à partir d'un CSV

Le plugin **CSV Mini-Game Importer** se trouve dans **Projet → Outils → Importer un mini-jeu (CSV)…**.

1. Choisis un fichier `.csv`. Garde-le **en dehors** du projet, sinon Godot l'importe comme fichier de traduction.
2. Le plugin détecte le type de mini-jeu :

   | Mini-jeu | Colonnes |
   |---|---|
   | Mots croisés | `mot ; indice` |
   | Quiz | `Question ; A ; B ; C ; D ; Réponse ; nom image` |
   | Cryptogramme | `phrase ; indice` (avec une ligne `ratio ; 0.4` optionnelle) |

3. Un récapitulatif liste les entrées détectées et les avertissements, par exemple une image introuvable ou un indice manquant.
4. Enregistre le `.tres`, puis ajoute-le à un level dans `game_data.tres`.

Pour les mots croisés, la grille est générée automatiquement à l'import. Le détail du format est dans `addons/csv_mini_game_importer/README.md`.

### Plugin Crossword (mots croisés)

L'onglet **Crossword** se trouve dans la barre du haut de l'éditeur, à côté de 2D, 3D, Script et AssetLib. Il affiche un aperçu de la grille d'un mot croisé.

- **Ouvrir un mot croisé**, au choix :
  - double-cliquer sur un fichier de mot croisé dans le Système de fichiers ;
  - glisser un fichier de mot croisé, ou un level, dans le panneau ;
  - utiliser le bouton **Ouvrir un mot croisé…**.
- **Régénérer la grille** : recalcule la place des mots et enregistre la ressource. Il faut le faire après avoir ajouté ou modifié des mots.
- **Grille complète** : affiche aussi les cases vides, en plus discret.
- **Liste des mots** : cliquer sur un mot le met en évidence dans la grille. Les mots isolés (sans croisement) sont en orange, et la barre d'état compte les cases en conflit.

---

## 5. Outils de test (Helper F1)

Quand le jeu est lancé depuis l'éditeur, la touche **F1** ouvre un panneau de test. Ce panneau n'existe pas dans le jeu exporté. Il propose :

- **Auto select / prefill** : remplit automatiquement le mini-jeu en cours.
- **Auto validate** : valide automatiquement le level quand le mini-jeu est réussi.
- **Show hints** : affiche la réponse attendue.
- **Unlock all levels** : débloque tous les levels jusqu'à la fermeture du jeu, sans les compter comme terminés.
- **+3 bonus** : ajoute trois indices.

---

## 6. Pour les développeurs

L'architecture technique est décrite dans `CLAUDE.md` à la racine du projet : les managers, `GameState` et `GameData`, et les conventions de code. Les points d'entrée :

| Rôle | Fichier |
|---|---|
| Lancement | `scripts/main.gd` → `GameManager.initialize()` |
| Menus et navigation | `scripts/ui/game_ui.gd` |
| Progression | `scripts/state/game_state.gd` |
| Données du jeu | `scripts/data/game_data.gd` |
| Écran de level | `scripts/level/level.gd` |
| Mini-jeux | `scripts/ui/crossword_ui.gd`, `memo_ui.gd`, `crypto_ui.gd` |
| Animations de feedback | `scripts/ui/ui_feedback.gd` |
