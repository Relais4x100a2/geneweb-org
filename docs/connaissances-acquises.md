# Connaissances Acquises - Exploration GeneWeb

Ce document synthétise les connaissances acquises lors de l'exploration initiale du code GeneWeb. Ces connaissances serviront de base pour les développements futurs des 3 piliers.

## Structure des Types de Données

### Fichier Principal : `lib/def/def.ml`

**Types clés identifiés :**

1. **`gen_person`** : Structure complète d'une personne
   - Champs de base : `first_name`, `surname`, `occ`, `image`, `sex`, `access`
   - Dates principales : `birth`, `baptism`, `death`, `burial` (avec place, note, src pour chacune)
   - Événements : `pevents : ('person, 'string) gen_pers_event list`
   - Relations : `rparents`, `related`

2. **`gen_pers_event`** : Structure d'un événement personnel
   - `epers_name : 'string gen_pers_event_name`
   - `epers_date : cdate`
   - `epers_place : 'string`
   - `epers_reason : 'string`
   - `epers_note : 'string`
   - `epers_src : 'string`
   - `epers_witnesses : ('person * witness_kind) array`

3. **`gen_family`** : Structure d'une famille
4. **`gen_fam_event`** : Structure d'un événement familial
5. **`gen_pers_event_name`** : Enumération des types d'événements personnels
   - Exemples : `Epers_Birth`, `Epers_Baptism`, `Epers_Death`, `Epers_Graduate`, etc.
   - Possibilité d'événements personnalisés : `Epers_Name of 'string`

### Architecture Polymorphique

Les types utilisent des paramètres de type (`'person`, `'string`, `'iper`) permettant de travailler avec :
- Des identifiants entiers (`int`) pour le format disque
- Des pointeurs vers objets en mémoire
- Des chaînes de caractères pour le format texte

## Sérialisation/Désérialisation de la Base de Données

### Format Binaire (.b)

**Fichiers clés :**
- `lib/db/database.ml` : Lecture de la base de données
- `lib/db/outbase.ml` : Écriture de la base de données
- `lib/db/iovalue.ml` : Sérialisation binaire des valeurs OCaml

**Caractéristiques :**
- Format magique : `magic_GnWb0024` (version actuelle)
- Utilise le mécanisme de sérialisation natif d'OCaml (`Marshal`)
- Les structures sont stockées avec des identifiants entiers (`iper`, `ifam`) au lieu de pointeurs
- Les chaînes sont dédupliquées dans un tableau de strings séparé
- Les offsets permettent un accès rapide sans charger toute la base

**⚠️ Important :** Modifier les types dans `def.ml` cassera la compatibilité avec les bases existantes. Il faut soit :
- Créer une nouvelle version de format (magic number)
- Écrire une fonction de migration
- Utiliser des champs optionnels pour rétrocompatibilité

## Système de Templates (.gw)

**Répertoires clés :**
- `hd/etc/` : Templates principaux
- `hd/etc/templm/` : Templates mobiles et macros réutilisables

**Fichiers importants :**
- `hd/etc/updind.txt` : Template pour la mise à jour/édition d'une personne
- `hd/etc/templm/perso.txt` : Macros pour l'affichage des événements
- `lib/updateInd.ml` : Interprète les templates et lie les variables aux données
- `lib/updateIndOk.ml` : Traite les données soumises depuis le formulaire

**Variables disponibles :**
- Variables pour la naissance : `birth_place`, `birth_note`, `birth_src`, `birth` (date)
- Gestion des événements : `event` pour les `pevents`

## Processus de Modification de Types

### Checklist Systématique

Lors de la modification d'un type (record, variant, tuple), il faut systématiquement :

1. **Mise à jour du type de base** (`lib/def/def.ml`)
   - Modifier la définition du type
   - Utiliser `option` pour rétrocompatibilité quand c'est possible
   - Mettre à jour les interfaces correspondantes (`.mli`)

2. **Recherche systématique de tous les usages**
   ```bash
   grep -r "type_name" lib/ --include="*.ml" -n
   ```

3. **Mise à jour des constructeurs**
   - Tous les endroits qui créent une valeur de ce type
   - Utiliser `grep` pour trouver tous les constructeurs
   - Ne PAS oublier les fonctions utilitaires (`map_*`, `mk_*`)

4. **Mise à jour des pattern-matchings**
   - Tous les `match ... with` qui pattern-match sur le type
   - Tous les `function` qui pattern-match sur le type
   - Les fonctions dans `lib/util/futil.ml` (map, etc.)
   - Les fonctions de hachage dans `lib/hasher.ml`
   - Les fonctions de sérialisation dans `lib/db/`
   - Les plugins (ex: `plugins/gwxjg/`)

5. **Mise à jour des tuples**
   - Si le type est utilisé dans un tuple, mettre à jour TOUS les endroits qui créent ou pattern-match sur le tuple

6. **Mise à jour des interfaces** (`.mli`)
   - Vérifier que les signatures correspondent aux implémentations

7. **Mise à jour des formulaires** (`hd/etc/updind.txt`, etc.)
   - Ajouter les champs d'input dans les templates
   - Vérifier que les noms correspondent aux clés utilisées dans le code

8. **Mise à jour du traitement des formulaires**
   - `lib/updateIndOk.ml` : lire les valeurs du formulaire
   - `lib/updateInd.ml` : afficher les valeurs dans le formulaire

9. **Mise à jour de l'affichage en mode lecture**
   - `lib/perso.ml` : ajouter les évaluations dans `eval_str_*_field` et `eval_bool_*_field`
   - Vérifier TOUS les templates d'affichage :
     * `hd/etc/templm/perso.txt` : affichage principal
     * `hd/etc/modules/chronologie.txt` : timeline (⚠️ souvent oublié)
     * `hd/etc/perso_short.txt` : vue courte
     * `hd/etc/deslist.txt` : liste de descendants
     * `hd/etc/perso_utils.txt` : tooltips

10. **Compilation et tests**
    - Compiler : `make gwd` ou `make build-geneweb`
    - Résoudre TOUTES les erreurs de compilation
    - **Redémarrer le serveur** après compilation : `./stop-gwd.sh && ./start-gwd.sh`
    - Tester en mode édition (saisie et sauvegarde)
    - Tester en mode lecture (affichage dans différents templates)

## Fichiers Clés par Fonctionnalité

### Types de données
- `lib/def/def.ml` : Définitions principales
- `lib/db/dbdisk.ml` : Types sérialisés

### Sérialisation
- `lib/db/database.ml` : Lecture
- `lib/db/outbase.ml` : Écriture
- `lib/db/iovalue.ml` : Utilitaires de sérialisation

### Interface utilisateur
- `hd/etc/updind.txt` : Formulaire d'édition personne
- `lib/updateInd.ml` : Interprétation du template
- `lib/updateIndOk.ml` : Traitement du formulaire

### Événements
- `lib/event.ml` : Fonctions de manipulation d'événements
- `lib/util/futil.ml` : Utilitaires pour les personnes/événements

### Affichage
- `lib/perso.ml` : Évaluations de champs pour templates
- `hd/etc/templm/perso.txt` : Template principal d'affichage
- `hd/etc/modules/chronologie.txt` : Timeline (souvent oublié !)

## Commandes Utiles

```bash
# Trouver toutes les utilisations d'un type
grep -r "gen_pers_event" lib/ --include="*.ml" -n

# Trouver toutes les créations d'événements
grep -r "epers_name\|epers_date\|epers_place" lib/ --include="*.ml" -n

# Lister tous les templates
find hd/etc -name "*.txt" -type f
```

## Leçons Apprises

1. **Les tuples sont fragiles** : Quand un type est dans un tuple, tous les endroits qui créent ou pattern-match sur ce tuple doivent être mis à jour
2. **Les templates multiples** : Il existe plusieurs templates d'affichage, tous doivent être mis à jour
3. **Les plugins** : Les plugins comme `gwxjg` ont leur propre logique et doivent être mis à jour aussi
4. **Les erreurs de compilation sont nos amies** : Elles indiquent exactement ce qui manque
5. **Toujours redémarrer le serveur** : Les modifications ne sont actives qu'après redémarrage
6. **Utiliser `grep` systématiquement** : Pour trouver tous les usages d'un type/module/fonction

## Patterns à Reconnaître

- `gen_pers_event` est utilisé dans un tuple `event_item` dans `lib/event.ml`
- Ce tuple est passé aux templates via `lib/perso.ml`
- Les templates utilisent `eval_str_event_field` et `eval_bool_event_field` pour accéder aux champs
- Il y a plusieurs templates : `perso.txt`, `chronologie.txt`, `perso_short.txt`, etc.

