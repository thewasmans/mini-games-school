# Points d'attention

Ce document liste les risques connus qui n'ont pas encore de garde-fou automatique. Il s'adresse à toute personne qui modifie des prefabs ou du contenu. Quand un garde-fou est mis en place, retirer le point correspondant.

---

## 1. Les `@export` ne sont pas vérifiés

La convention du projet est qu'un `@export` est toujours assigné dans l'Inspector. Rien ne le contrôle pour l'instant :

- un export oublié (bouton, label, prefab, ressource) ne provoque **aucune erreur dans l'éditeur** ;
- l'erreur n'apparaît qu'en jeu, au moment où le code utilise la valeur (`Invalid access to property or key ... on a base object of type 'Nil'`), souvent loin de la scène fautive.

**Quand on modifie un prefab :**

- après avoir supprimé, remplacé ou recréé un nœud, vérifier dans l'Inspector du script racine qu'aucun export n'est vide ;
- lancer le jeu et parcourir l'écran modifié, ou lancer les tests (`tests/integration/` instancie les prefabs principaux).

**Piste retenue pour plus tard :** un contrôleur d'éditeur branché sur `EditorPlugin._build()`, qui bloque le lancement (F5) en listant les exports vides de chaque prefab. Les exports qui ont le droit d'être vides seraient déclarés dans leur script, par exemple :

```gdscript
const OPTIONAL_EXPORTS: Array[StringName] = [&"sound"]
```

---

## 2. Grilles de mots croisés

La grille est calculée **dans l'éditeur** (plugin Crossword ou import CSV), jamais pendant la partie. Si un mot est modifié directement dans l'Inspector sans régénérer la grille, la grille en jeu est fausse.

- Toujours passer par l'import CSV ou la régénération du plugin Crossword.
- Le test `tests/content/game_data_content_test.gd` détecte une grille absente ou dont deux mots se croisent sur des lettres différentes. Il ne détecte pas une grille cohérente mais périmée (par exemple un mot raccourci).

---

## 3. Fichiers créés ou modifiés en dehors de l'éditeur

- **UID :** un `.tscn` ou un `.tres` créé hors de l'éditeur (script, copie, merge) n'a pas d'UID tant qu'il n'a pas été enregistré une fois dans Godot ; ses références cassent s'il est déplacé. Le test `tests/content/resource_uid_test.gd` liste les fichiers et références sans UID ou avec un UID périmé.
- **Ressource ouverte dans l'éditeur :** l'éditeur garde en mémoire les ressources ouvertes. Après une modification externe (merge, script, `FakeDataBuilder`, import), recharger le projet avant d'enregistrer, sinon la version en mémoire écrase celle du disque.
- **`.tscn` écrit à la main :** dans un nœud, les propriétés propres à son script (par exemple `icon_left` d'un `JuicyButton`) doivent venir **après** la ligne `script = ...`, sinon Godot les ignore au chargement. L'éditeur respecte cet ordre de lui-même.

---

## 4. Export du jeu

Le projet n'a pas encore de `export_presets.cfg`. Au moment de le créer, ajouter `addons/gdUnit4/*, tests/*` dans le filtre d'exclusion de chaque preset, pour ne pas embarquer les tests dans le jeu.
