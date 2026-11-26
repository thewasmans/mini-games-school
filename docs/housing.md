# Housing : la maison du grand-père

Ce document fixe la conception du housing. Il fusionne deux sources :

- **« Housing »** : le document de référence. En cas de contradiction, c'est lui qui l'emporte.
- **« Mécanique de progression : le Labo modulaire »** : une proposition de mise en œuvre, reprise seulement là où elle respecte « Housing ».

La revue de « Housing » a ajouté une contrainte qui prime sur tout le reste :

> Une seule grande maison à gérer, avec une pièce par matière et des objets à découvrir. Pas plus loin, pour ne pas perdre les élèves.

La section 8 liste ce qui a été écarté et pourquoi, la section 9 les décisions prises, la section 10 la taille des jauges pour la chimie.

---

## 1. Intention

Le housing donne à l'élève un espace **fun et détendu, sans apprentissage direct**. Il le pousse pourtant à refaire des mini-jeux : c'est là qu'il gagne les points et les objets qui font avancer la maison.

> Boucle : **je joue → je gagne des points et je remplis les jauges des objets → j'aménage ma maison → il me manque des points ou des objets → je rejoue**

**Point de vigilance principal** : l'élève ne doit pas bâcler les mini-jeux pour revenir au housing. Les gains récompensent la réussite (étoiles), pas la vitesse. Il faudra le vérifier en test avec des élèves.

## 2. Histoire

Un enfant hérite de la maison-laboratoire de son grand-père, une maison flottante dans les airs, laissée à l'abandon. L'élève l'aide à la restaurer grâce aux mots et aux concepts appris dans les mini-jeux.

## 3. La maison

- **Une seule maison**, en 3D, dans la direction artistique du jeu (low poly, diorama, palette chaude).
- **Une pièce par matière** du programme de la FWB : Chimie, Biologie, Physique… La pièce d'une matière s'ouvre quand l'élève commence cette matière.
- Les pièces sont **abîmées** au départ : vitres sales, coins encombrés, planchers cassés. Les **rénover** avec des points libère de la place.
- Le joueur **incarne l'enfant**, piloté par un **character controller à la troisième personne** : caméra derrière l'enfant, joystick virtuel à gauche de l'écran, glisser à droite pour tourner la caméra (écran portrait). On passe d'une pièce à l'autre en marchant par les portes. L'enfant interagit avec ce qui est devant lui : un emplacement vide, un objet, une partie à rénover.
- La maison n'est **pas le point d'entrée** du jeu : on y accède depuis les menus, et un bouton **Jouer** reste toujours visible.
- Chaque pièce affiche un indicateur, par exemple « Chimie : 4 / 21 objets ».

## 4. Les objets

- **Un mot ou un concept = un objet** (tableau, statue, instrument, meuble…), lié au mot par un **lien mnémotechnique**.
- Chaque objet a une **jauge de découverte**. Elle monte **chaque fois que l'élève rencontre le mot** dans un mini-jeu ; quand elle est pleine, l'objet est **débloqué** (section 4 bis).
- Chaque objet porte une **petite pancarte** qui explique le concept. La toucher affiche la définition et propose de rejouer le level d'origine.
- Les objets pas encore débloqués apparaissent en **silhouette grisée** dans l'inventaire de la pièce, avec leur jauge, les levels où l'on rencontre le mot et un bouton **Jouer**. Ce sont les « objets à découvrir ».
- Chaque objet **occupe de la place** sur une grille et ne peut pas se superposer à un autre. Certains objets se disputent le même type d'emplacement (un seul lustre au plafond) : il faut retirer l'ancien pour poser le nouveau.
- Les **objets évolutifs** sont conservés parce qu'ils illustrent bien cette contrainte : lustre à 2, 3 puis 4 boules pour binaire, ternaire et quaternaire.

## 4 bis. Les jauges de découverte

- **Une jauge par objet**, donc par mot.
- **Taille selon la fréquence du mot** : 10 points par level de la matière qui contient le mot, avec un maximum de 3 levels (réglage). Un mot présent dans 1 level a une jauge de 10, dans 2 levels de 20, dans 3 levels ou plus de 30. Un mot rare se débloque vite, un mot fréquent demande de le retrouver dans plusieurs levels.
- **Une rencontre** = une réponse trouvée qui contient le mot :
  - mots croisés : le mot de la grille ;
  - quiz : une question dont la question ou la bonne réponse contient le mot ;
  - cryptogramme : une phrase qui contient le mot, une fois la phrase trouvée.
- **Points d'une rencontre** : le barème déjà utilisé par les étoiles, 10 sans erreur, 5 après 1 erreur, 2 après 2, 0 au-delà, 4 au plus avec un indice.
- **Un level compte une fois** : pour chaque level, la jauge garde la **meilleure** rencontre du mot dans ce level (comme les étoiles). La jauge vaut la somme de ces meilleurs scores. Rejouer le même level en boucle ne la remplit donc pas ; le rejouer **mieux** la fait monter.
- Exemple : MOLE (6 levels, jauge de 30). Trouvé sans faute au level 05 (10), avec 1 erreur au level 08 (5) : 15 / 30. Rejoué sans faute au level 08 : 20 / 30. Trouvé sans faute au level 10 : 30 / 30, la peluche de taupe est débloquée.
- La jauge **ne descend jamais**. Une jauge pleine reste pleine.
- La révision reste récompensée par les points d'action (section 5) et par l'amélioration des meilleures rencontres.
- **Fin de level** : un écran montre les jauges des mots rencontrés qui montent, et annonce « Nouvel objet ! » quand l'une d'elles se remplit. Les messages restent positifs.
- **Lien mot → objet** : chaque objet déclare son mot (et ses variantes éventuelles : MOLE, MOLES). La rencontre est détectée en comparant le texte normalisé (majuscules, sans accents) aux réponses. Aucun réglage n'est nécessaire dans les mini-jeux.
- **Garde-fou** : un test de contenu vérifie que chaque mot d'objet apparaît dans au moins un level de sa matière, sinon l'objet serait impossible à débloquer. La taille de la jauge est calculée à partir du contenu, jamais saisie à la main : ajouter un level qui contient le mot l'agrandit (jusqu'au maximum).
- **Sauvegarde** : par mot, le meilleur score de chaque level.

## 5. Les points d'action

Une **seule monnaie** : les points d'action.

| Action | Coût |
|---|---|
| Placer un objet | 1 |
| Retirer ou déplacer un objet | 1 |
| Rénover une partie de la pièce | selon la taille (ex. 3 à 5) |

Le joueur doit **réagencer** sa pièce pour tout faire tenir, ce qui coûte des points, donc l'amène à refaire des mini-jeux.

**Gains** : le nouveau rapporte plus que le rejoué, mais **la révision rapporte toujours** quelque chose, et davantage quand le level n'a pas été revu depuis longtemps.

| Situation | Points |
|---|---|
| Premier succès d'un level | 2 |
| Chaque nouvelle étoile gagnée sur un level | +1 |
| Rejouer un level réussi (au moins 1 étoile) | 1 |
| Rejouer un level pas revu depuis 7 jours ou plus | 2 |

Exemples : un nouveau level réussi avec 3 étoiles rapporte 5 points ; un level revu le lendemain rapporte 1 point, revu deux semaines plus tard 2 points. Les valeurs sont des réglages, à ajuster en test.

Il faut au moins 1 étoile pour gagner des points en rejouant : un level bâclé ne rapporte rien.

**Indices** : les points d'action et les indices (gagnés sur les îles bonus, dépensés dans les mini-jeux) sont deux monnaies **séparées**, sans conversion.

## 6. Exemple de partie (repris de « Housing »)

L'élève termine un mini-jeu sur les molécules. Il gagne des **points d'action**, et le mot TERNAIRE, déjà trouvé sans erreur au level 21, l'est maintenant au level 24 : sa jauge (2 levels, donc 20) est pleine, **le lustre ternaire est débloqué**.

Il va dans la pièce Chimie pour placer le lustre, mais le plafond a déjà un lustre binaire. Retirer l'ancien coûte 1 point. Il ne lui reste plus assez de points pour placer le nouveau : il refait un mini-jeu pour gagner le point qui manque.

## 7. Contenu de départ : la pièce Chimie

Correspondance mots → objets reprise du Labo modulaire (levels 05 à 24). Tous les objets vont dans la pièce Chimie : les sous-pièces Salon / Bureau / Labo sont abandonnées (voir section 8).

| Mot | Objet | Lien mnémotechnique |
|---|---|---|
| NOMENCLATURE | Meuble d'apothicaire à tiroirs étiquetés | Chaque chose a son nom |
| BINAIRE | Lustre moléculaire à 2 boules | 2 éléments |
| TERNAIRE | Lustre à 3 boules | 3 éléments |
| QUATERNAIRE | Lustre à 4 boules | 4 éléments |
| ISOTOPE | Matriochkas identiques de poids différents | Même identité, masse différente |
| ACTEUR | Mini-scène de théâtre avec masque | L'ion qui joue dans la réaction |
| SPECTATEUR | Fauteuil avec pop-corn | L'ion qui regarde |
| IONIQUE | Aimants + et − sur le frigo | Attraction forte entre charges |
| SIGNIFICATIFS | Balance digitale à 0,001 g | Les chiffres qui comptent |
| MOLE | Peluche de taupe (*mole* en anglais) | Jeu de mots |
| AVOGADRO | Portrait d'Avogadro « 6,02×10²³ » | Le nombre dans la mole |
| STOECHIOMETRIE | Balance à deux plateaux en équilibre | Équilibrer les quantités |
| CNTP | Thermomètre et baromètre muraux | Température et pression |
| DENSITE | Lampe à lave | Liquides de densités différentes |
| AQUEUSE | Aquarium | Plein d'eau |
| DILUTION | Carafe de sirop et fontaine à eau | Ajouter du solvant |
| SOLUBILITE | Tasse de thé et morceaux de sucre | Jusqu'où ça se dissout |
| PRECIPITATION | Boule à neige | Particules solides qui tombent |
| ELECTROLYTE | Pile au citron qui allume une ampoule | Le citron conduit le courant |
| ELECTROLYSE | Appareil à deux tubes qui font des bulles | Eau décomposée en H₂ et O₂ |
| CONDUCTIBILITE | Guirlande lumineuse | Le courant passe |

## 8. Ce qui a été écarté du Labo modulaire

| Proposition du Labo modulaire | Décision | Raison |
|---|---|---|
| Modules par thématique branchés sur un hub | Écarté | Revue : une maison, une pièce par matière |
| Sous-pièces Salon / Bureau / Labo dans un thème | Écarté | Revue : pas plus loin que les pièces par matière |
| Extensions gagnées automatiquement à chaque level | Remplacé | « Housing » : la place se gagne en **rénovant** avec des points |
| Deux monnaies (cristaux 💎 et gouttes 💧), jauge de 100 | Remplacé | « Housing » : une seule monnaie, les points d'action ; la revue demande de simplifier |
| Placer, déplacer et annuler gratuitement | Remplacé | « Housing » : chaque action coûte des points, c'est le moteur du retour aux mini-jeux |
| Objet débloqué après 2 à 3 mini-jeux différents réussis | Repris sous forme de **jauge visible** | Décision de l'auteur de « Housing » : la jauge monte à chaque rencontre du mot, ce qui rend la règle visible et récompense la révision |
| Vue de haut façon carte du programme | Remplacé | « Housing » : l'enfant se déplace dans un espace 3D |
| Paires d'objets (acteur ↔ spectateur) comme mécanique | Écarté | Revue : ne pas ajouter de mécaniques ; les deux objets existent, sans règle de paire |
| Plantes qui fanent (répétition espacée) | Écarté | Absent de « Housing », ajoute une mécanique |
| Boutique de cosmétiques (couleurs, sols, murs) | Écarté | Liée aux gouttes, absente de « Housing » |
| Option enseignant pour limiter le housing | Reporté | Le jeu n'a pas d'espace enseignant |

**Repris du Labo modulaire** : le déblocage par répétition (sous forme de jauge), le lien mnémotechnique et la table mots → objets, la pancarte qui renvoie vers le mini-jeu, les silhouettes « à découvrir » avec bouton Jouer, les objets évolutifs, l'indicateur par pièce, le bouton Jouer toujours visible, l'idée que le nouveau rapporte plus que le rejoué, les bonus présentés positivement.

## 9. Décisions prises

- **Sauvegarde** : en place (`SaveManager`, `user://save.json`). Le housing y ajoutera son propre bloc (points, jauges des objets, placement, rénovations, date de dernière partie par level).
- **Révision** : elle rapporte toujours des points (section 5).
- **Points d'action et indices** : séparés.
- **Déplacement** : character controller à la troisième personne (section 3).
- **Déblocage des objets** : une jauge par objet, qui monte à chaque rencontre du mot ; chaque level compte une fois (meilleure rencontre), et la taille de la jauge dépend du nombre de levels qui contiennent le mot (section 4 bis). Les autres solutions étudiées (un objet par level, un objet par mot trouvé, des objets rares en plus) sont écartées.

## 10. Fréquence des mots de la pièce Chimie (S4)

Nombre de levels qui contiennent le mot, relevé approximatif sur le texte des fichiers (à confirmer par le test de contenu), et taille de jauge qui en découle.

| Mot | Levels | Jauge |
|---|---|---|
| SIGNIFICATIFS, CNTP | 1 | 10 |
| NOMENCLATURE, TERNAIRE, QUATERNAIRE, DENSITE, AQUEUSE, SOLUBILITE, ELECTROLYTE, CONDUCTIBILITE | 2 | 20 |
| BINAIRE, AVOGADRO, ELECTROLYSE, ISOTOPE, ACTEUR, SPECTATEUR, IONIQUE, STOECHIOMETRIE, DILUTION, PRECIPITATION, MOLE | 3 ou plus | 30 |

Le plan d'implémentation est dans [housing_plan.md](housing_plan.md).
