# Plan d'Action : Exploration et Modifications GeneWeb

## Vue d'ensemble

Ce document décrit un plan d'action progressif pour explorer et modifier la base de code GeneWeb, en commençant par l'**identification** (lecture seule) puis en procédant à une **première modification de test**.

---

## PHASE 1 : IDENTIFICATION (Lecture seule)

### 1.1. Structures de données principales

#### Fichiers clés pour les définitions de types

**Fichier principal : `lib/def/def.ml`**
- **Localisation** : `/home/guillaumecayeux/code_dev/geneweb-org/lib/def/def.ml`
- **Rôle** : Contient toutes les définitions de types OCaml pour les structures principales
- **Types importants définis** :
  - `gen_person` (lignes 244-283) : Structure complète d'une personne
    - Champs de base : `first_name`, `surname`, `occ`, `image`, `sex`, `access`
    - Dates principales : `birth`, `baptism`, `death`, `burial` (avec place, note, src pour chacune)
    - Événements : `pevents : ('person, 'string) gen_pers_event list`
    - Relations : `rparents`, `related`
  - `gen_pers_event` (lignes 175-183) : Structure d'un événement personnel
    - `epers_name : 'string gen_pers_event_name`
    - `epers_date : cdate`
    - `epers_place : 'string`
    - `epers_reason : 'string`
    - `epers_note : 'string`
    - `epers_src : 'string`
    - `epers_witnesses : ('person * witness_kind) array`
  - `gen_family` (lignes 296-309) : Structure d'une famille
  - `gen_fam_event` (lignes 202-210) : Structure d'un événement familial
  - `gen_pers_event_name` (lignes 122-173) : Enumération des types d'événements personnels
    - Exemples : `Epers_Birth`, `Epers_Baptism`, `Epers_Death`, `Epers_Graduate`, etc.
    - Possibilité d'événements personnalisés : `Epers_Name of 'string`

**Fichier : `lib/db/dbdisk.ml`**
- **Localisation** : `/home/guillaumecayeux/code_dev/geneweb-org/lib/db/dbdisk.ml`
- **Rôle** : Définit les types de données "disque" (sérialisés)
- **Types importants** :
  - `dsk_person = (int, int, int) Def.gen_person` : Version sérialisée d'une personne
  - `dsk_family`, `dsk_ascend`, etc. : Autres types sérialisés

#### Points clés à retenir

1. **Architecture polymorphique** : Les types utilisent des paramètres de type (`'person`, `'string`, `'iper`) permettant de travailler avec soit :
   - Des identifiants entiers (`int`) pour le format disque
   - Des pointeurs vers objets en mémoire
   - Des chaînes de caractères pour le format texte

2. **Événements** : Les événements sont stockés dans une liste (`pevents`) au sein de chaque personne, chaque événement contenant :
   - Un nom (type énuméré ou personnalisé)
   - Date, lieu, raison, note, source
   - Liste de témoins

3. **Naissance** : La naissance a un statut spécial :
   - Elle peut être stockée soit comme champ dédié (`birth`, `birth_place`, `birth_note`, `birth_src`) dans `gen_person`
   - Soit comme événement dans `pevents` avec `Epers_Birth`

---

### 1.2. Sérialisation/Désérialisation de la base de données binaire (.b)

#### Fichiers clés pour la sérialisation

**Fichier principal : `lib/db/database.ml`**
- **Localisation** : `/home/guillaumecayeux/code_dev/geneweb-org/lib/db/database.ml`
- **Rôle** : Gestion de la lecture de la base de données
- **Points importants** :
  - Fonction `with_database` (ligne 938) : Point d'entrée pour ouvrir une base
  - Format binaire décrit dans les commentaires (lignes 19-52) :
    - Fichier `base` : Contient les données principales avec des offsets
    - Fichier `base.acc` : Accès direct aux tableaux (index)
  - Utilise `input_value` et `Iovalue.input` pour désérialiser les structures OCaml

**Fichier : `lib/db/outbase.ml`**
- **Localisation** : `/home/guillaumecayeux/code_dev/geneweb-org/lib/db/outbase.ml`
- **Rôle** : Gestion de l'écriture de la base de données
- **Points importants** :
  - Fonction `output_array` : Sérialise les tableaux
  - Utilise `output_value` et `Dutil.output_value_no_sharing` pour sérialiser
  - Format magique : `magic_GnWb0024` (version actuelle)

**Fichier : `lib/db/iovalue.ml`**
- **Rôle** : Sérialisation binaire des valeurs OCaml (Marshall)

#### Comment la sérialisation fonctionne

1. **Format binaire OCaml** : GeneWeb utilise le mécanisme de sérialisation natif d'OCaml (`Marshal`), avec quelques optimisations :
   - Les structures sont stockées avec des identifiants entiers (`iper`, `ifam`) au lieu de pointeurs
   - Les chaînes sont dédupliquées dans un tableau de strings séparé
   - Les offsets permettent un accès rapide sans charger toute la base

2. **Modification des structures** :
   - ⚠️ **Attention** : Modifier les types dans `def.ml` cassera la compatibilité avec les bases existantes !
   - Il faudra soit :
     - Créer une nouvelle version de format (magic number)
     - Écrire une fonction de migration
     - Utiliser des champs optionnels pour rétrocompatibilité

3. **Fichiers de patch** : Le système utilise des "patches" (fichier `patches`) pour les modifications temporaires avant commit.

---

### 1.3. Templates (.gw) pour l'interface utilisateur

#### Structure des templates

**Répertoire principal : `hd/etc/`**
- **Fichiers clés** :
  - `updind.txt` : Template pour la mise à jour/édition d'une personne
  - `perso.txt` : Template pour l'affichage d'une personne
  - `templm/updind.txt` : Version mobile du template de mise à jour

**Répertoire : `hd/etc/templm/`**
- Contient les templates mobiles et les macros réutilisables
- `perso.txt` : Macros pour l'affichage des événements

#### Templates pour les événements de naissance

**Fichier : `hd/etc/updind.txt`** (lignes 960-980)
- Section pour l'édition de la naissance :
  - Champ `birth_place` : Lieu de naissance
  - Fonction `date()` pour la date de naissance
  - Fonctions `note("birth")` et `source("birth")` pour notes et sources
  - Gestion des événements `pevent` avec support pour `#birt` (birth event)

**Fichier : `hd/etc/templm/perso.txt`** (lignes 935-960)
- Macro `birth_event()` : Affichage de l'événement de naissance
- Utilise les variables `event.name`, `event.has_date`, `event.place`, etc.

**Fichier : `lib/updateInd.ml`**
- **Localisation** : `/home/guillaumecayeux/code_dev/geneweb-org/lib/updateInd.ml`
- **Rôle** : Interprète les templates `updind.txt` et lie les variables aux données
- **Points importants** :
  - `eval_simple_var` (ligne 41) : Évalue les variables du template
  - Variables pour la naissance : `birth_place`, `birth_note`, `birth_src`, `birth` (date)
  - Gestion des événements (ligne 98+) : `event` pour les `pevents`

---

### 1.4. Fichiers de mise à jour (update)

#### Fichiers clés

**`lib/updateIndOk.ml`**
- **Rôle** : Traite les données soumises depuis le formulaire `updind.txt`
- **Action** : Crée/modifie une personne dans la base

**`lib/updateInd.ml`**
- **Rôle** : Génère le formulaire d'édition
- **Action** : Lit la personne et remplit les champs du template

**`lib/update.ml`**
- **Rôle** : Module principal de mise à jour
- **Action** : Orchestre les différentes opérations

---

## PHASE 2 : PREMIÈRE MODIFICATION (Test)

### 2.1. Modification proposée : Ajouter un champ "test_field" à l'événement de naissance

#### Stratégie : Commencer par les événements plutôt que les champs directs

**Pourquoi ?** : Les événements (`pevents`) sont plus flexibles et moins risqués que de modifier directement `gen_person`.

**Problème** : Modifier `gen_pers_event` casserait toutes les bases existantes.

**Solution recommandée** : Ajouter le champ de manière optionnelle avec rétrocompatibilité, OU tester avec un événement personnalisé existant.

#### Option 1 : Ajouter un champ optionnel à `gen_pers_event` (RECOMMANDÉE)

**Modification à faire** :
1. Dans `lib/def/def.ml`, ligne 175-183, modifier :
```ocaml
type ('person, 'string) gen_pers_event = {
  epers_name : 'string gen_pers_event_name;
  epers_date : cdate;
  epers_place : 'string;
  epers_reason : 'string;
  epers_note : 'string;
  epers_src : 'string;
  epers_witnesses : ('person * witness_kind) array;
  (* NOUVEAU CHAMP - optionnel pour rétrocompatibilité *)
  epers_test_field : 'string option;  (* None par défaut = compatible avec l'ancien format *)
}
```

**Avantages** :
- Type `option` = rétrocompatible (anciennes données ont `None`)
- Ne casse pas les bases existantes
- Permet de tester le cycle complet

**Inconvénients** :
- Nécessite de gérer `None` partout où on utilise ce champ
- Tous les endroits qui créent `gen_pers_event` doivent être mis à jour

#### Option 2 : Utiliser un événement personnalisé existant (PLUS SIMPLE POUR TEST)

**Modification à faire** :
1. Ne pas modifier les structures de données
2. Utiliser `Epers_Name of 'string` pour créer un événement personnalisé
3. Stocker "test_field: valeur" dans le champ `epers_note` ou `epers_reason`

**Avantages** :
- Aucun risque de casser la compatibilité
- Permet de tester l'ajout d'événements via l'interface

**Inconvénients** :
- Pas une vraie modification de structure
- Ne teste pas la sérialisation de nouveaux champs

---

### 2.2. Étapes détaillées pour Option 1 (ajout de champ optionnel)

#### Étape 2.2.1 : Modifier la définition du type

**Fichier** : `lib/def/def.ml`
**Ligne** : 175-183
**Action** : Ajouter le champ `epers_test_field : 'string option;` à la structure `gen_pers_event`

#### Étape 2.2.2 : Mettre à jour tous les constructeurs de `gen_pers_event`

**Fichiers à modifier** :
- `lib/util/futil.ml` : Fonctions de mapping
- `lib/updateIndOk.ml` : Création d'événements depuis formulaire
- `lib/updateFamOk.ml` : Événements familiaux (si applicable)
- Tous les endroits où on fait `{ epers_name = ...; epers_date = ...; ... }`

**Méthode** : Utiliser `grep` pour trouver toutes les occurrences :
```bash
grep -r "epers_name\|gen_pers_event" lib/ --include="*.ml"
```

#### Étape 2.2.3 : Ajouter le champ dans le template

**Fichier** : `hd/etc/updind.txt`
**Action** : Ajouter un champ input pour `test_field` dans la section des événements de naissance

#### Étape 2.2.4 : Lier le template à la variable

**Fichier** : `lib/updateInd.ml`
**Action** : Ajouter dans `eval_simple_var` une gestion de `test_field` pour les événements

**Fichier** : `lib/updateIndOk.ml`
**Action** : Lire la valeur du formulaire et l'ajouter lors de la création de l'événement

#### Étape 2.2.5 : Gérer l'affichage (optionnel pour test)

**Fichier** : `hd/etc/templm/perso.txt` ou `hd/etc/perso.txt`
**Action** : Afficher le champ `test_field` si présent

---

### 2.3. Étapes pour Option 2 (événement personnalisé - PLUS SIMPLE)

#### Étape 2.3.1 : Modifier le template pour ajouter un champ

**Fichier** : `hd/etc/updind.txt`
**Action** : Ajouter un champ texte dans la section naissance

#### Étape 2.3.2 : Lire la valeur dans updateIndOk.ml

**Fichier** : `lib/updateIndOk.ml`
**Action** : Lire le paramètre du formulaire et l'ajouter comme note ou créer un événement personnalisé

**Avantage** : Pas de modification de structures = pas de risque de casser la compatibilité

---

## PHASE 3 : COMPILATION

### 3.1. Prérequis

**Outils nécessaires** :
- OCaml (version >= 4.08 selon `dune-project`)
- `opam` : Gestionnaire de paquets OCaml
- `dune` : Système de build (installé via opam)

**Vérification** :
```bash
ocaml --version
opam --version
dune --version
```

### 3.2. Installation des dépendances

**Commandes** :
```bash
# Initialiser opam (si pas déjà fait)
opam init

# Installer les dépendances du projet
opam install . --deps-only
# OU
make deps  # Si cette cible existe dans le Makefile
```

### 3.3. Configuration

**Étape** : Générer la configuration
```bash
ocaml ./configure.ml
```

Cette commande génère `Makefile.config` utilisé par le `Makefile` principal.

### 3.4. Compilation

#### Méthode 1 : Avec Dune (RECOMMANDÉE)

```bash
# Compiler tout le projet
dune build

# Compiler un module spécifique
dune build lib/def/def.cmx

# Nettoyer et recompiler
dune clean
dune build
```

#### Méthode 2 : Avec Makefile

```bash
# Compiler tout
make

# Voir les autres cibles disponibles
make help  # Si cette cible existe
```

### 3.5. Vérification après compilation

1. **Vérifier qu'il n'y a pas d'erreurs** :
   - Dune affiche les erreurs de type OCaml
   - Les erreurs de type sont souvent les plus importantes

2. **Vérifier la cohérence .ml/.mli** :
   - Les fichiers `.mli` (interfaces) doivent correspondre aux `.ml` (implémentations)
   - Dune vérifie automatiquement

3. **Tests** :
   - Si des tests existent : `dune runtest` ou `make test`

---

## CHECKLIST DE DÉMARRAGE

### Phase 1 : Exploration (Lecture seule)

- [ ] Lire `lib/def/def.ml` et comprendre la structure de `gen_person` et `gen_pers_event`
- [ ] Explorer `lib/db/database.ml` pour comprendre la sérialisation
- [ ] Examiner `lib/db/outbase.ml` pour comprendre l'écriture
- [ ] Lire `hd/etc/updind.txt` pour voir comment les formulaires sont structurés
- [ ] Examiner `lib/updateInd.ml` pour voir comment les templates sont interprétés
- [ ] Utiliser `grep` pour trouver tous les endroits où `gen_pers_event` est créé/modifié

### Phase 2 : Première modification

- [ ] Choisir l'option (1 ou 2) selon le niveau de risque accepté
- [ ] Faire une sauvegarde de la base de données de test
- [ ] Modifier le type dans `lib/def/def.ml` (si option 1)
- [ ] Mettre à jour tous les constructeurs trouvés avec grep
- [ ] Modifier les templates si nécessaire
- [ ] Compiler et corriger les erreurs
- [ ] Tester avec une base de données de test

### Phase 3 : Compilation

- [ ] Vérifier les prérequis (OCaml, opam, dune)
- [ ] Installer les dépendances
- [ ] Configurer avec `ocaml ./configure.ml`
- [ ] Compiler avec `dune build`
- [ ] Résoudre les erreurs de compilation une par une
- [ ] Vérifier que la base de test fonctionne toujours

---

## RESSOURCES ET FICHIERS CLÉS

### Fichiers à explorer en priorité

1. **Types de données** :
   - `lib/def/def.ml` : Définitions principales
   - `lib/db/dbdisk.ml` : Types sérialisés

2. **Sérialisation** :
   - `lib/db/database.ml` : Lecture
   - `lib/db/outbase.ml` : Écriture
   - `lib/db/iovalue.ml` : Utilitaires de sérialisation

3. **Interface utilisateur** :
   - `hd/etc/updind.txt` : Formulaire d'édition personne
   - `lib/updateInd.ml` : Interprétation du template
   - `lib/updateIndOk.ml` : Traitement du formulaire

4. **Événements** :
   - `lib/event.ml` : Fonctions de manipulation d'événements
   - `lib/util/futil.ml` : Utilitaires pour les personnes/événements

### Commandes utiles pour l'exploration

```bash
# Trouver toutes les utilisations de gen_pers_event
grep -r "gen_pers_event" lib/ --include="*.ml" -n

# Trouver toutes les créations d'événements
grep -r "epers_name\|epers_date\|epers_place" lib/ --include="*.ml" -n

# Trouver les références à Epers_Birth
grep -r "Epers_Birth" lib/ --include="*.ml" -n

# Lister tous les templates
find hd/etc -name "*.txt" -type f
```

---

## NOTES IMPORTANTES

### ⚠️ Compatibilité des bases de données

- **NE JAMAIS** modifier les structures de données sans plan de migration si vous avez des bases existantes
- Les modifications de `def.ml` nécessitent soit :
  - Une nouvelle version de format (changer le magic number)
  - Une fonction de migration
  - Des champs optionnels pour rétrocompatibilité

### 🔍 Stratégie de test

1. **Toujours** tester sur une base de données de test (copie)
2. **Vérifier** que l'ancien format peut encore être lu
3. **Tester** l'écriture et la lecture du nouveau format
4. **Vérifier** que les templates affichent correctement les nouvelles données

### 📚 Comprendre OCaml

- Les types avec `'a`, `'string`, `'person` sont des **types paramétrés** (polymorphisme)
- `option` est un type standard : `Some valeur` ou `None`
- Les `list` en OCaml sont des listes chaînées : `[]` (vide) ou `x :: xs` (tête + queue)

---

## PROCHAINES ÉTAPES APRÈS LE TEST

### ✅ État actuel : Première modification réussie

Le champ `epers_test_field` a été ajouté avec succès à `gen_pers_event` et est maintenant **fonctionnel de bout en bout** :
- ✅ Définition du type dans `lib/def/def.ml`
- ✅ Mise à jour de tous les constructeurs et pattern-matchings
- ✅ Formulaire d'édition fonctionnel (`hd/etc/updind.txt`)
- ✅ Traitement du formulaire (`lib/updateIndOk.ml`)
- ✅ Affichage en mode lecture dans tous les templates
- ✅ Compilation réussie et serveur redémarré

### 🎯 Prochaines étapes possibles

#### 1. Étendre le champ à d'autres types d'événements

**Objectif** : Ajouter le champ `test_field` (ou d'autres champs personnalisés) aux événements familiaux (`gen_fam_event`)

**Fichiers à modifier** :
- `lib/def/def.ml` : Ajouter le champ à `gen_fam_event`
- `lib/util/futil.ml` : Mettre à jour `map_fam_event`
- `lib/updateFamOk.ml` : Gérer le champ dans les formulaires familiaux
- `hd/etc/updfam.txt` : Ajouter le champ dans le template d'édition
- Templates d'affichage des événements familiaux

**Avantages** :
- Réutilise le processus déjà maîtrisé
- Permet d'avoir des champs personnalisés sur tous les événements

#### 2. Ajouter d'autres champs personnalisés

**Objectif** : Créer d'autres champs optionnels pour enrichir les événements

**Exemples de champs possibles** :
- `epers_source_structured : source_info option` : Source structurée (auteur, date, lieu)
- `epers_organization_link : organization_ref option` : Lien vers une organisation
- `epers_media_links : media_link list` : Liens vers des médias (photos, documents)

**Processus** :
- Suivre la même checklist que pour `test_field`
- Utiliser `grep` pour trouver tous les usages
- Mettre à jour systématiquement tous les endroits identifiés

#### 3. Créer une nouvelle entité "Organisation" (Objectif principal)

**Objectif** : Ajouter une entité formelle ou informelle (entreprise, école, association, etc.)

**Étapes principales** :

1. **Définir le type dans `lib/def/def.ml`** :
   ```ocaml
   type ('string) gen_organization = {
     org_name : 'string;
     org_type : organization_type;  (* Company, School, Association, etc. *)
     org_address : 'string;
     org_note : 'string;
     org_src : 'string;
     (* ... autres champs ... *)
   }
   ```

2. **Ajouter les tables dans la structure de base de données** :
   - `lib/db/database.ml` : Ajouter la lecture des organisations
   - `lib/db/outbase.ml` : Ajouter l'écriture des organisations
   - Créer un nouveau fichier de données `base.org` ou intégrer dans `base`

3. **Créer les fonctions CRUD** :
   - `lib/organization.ml` : Fonctions de manipulation
   - `lib/updateOrgOk.ml` : Traitement des formulaires
   - `lib/updateOrg.ml` : Génération des formulaires

4. **Créer les liens avec personnes et événements** :
   - Ajouter `organization_links : organization_ref list` dans `gen_person`
   - Ajouter `epers_organization : organization_ref option` dans `gen_pers_event`
   - Créer des types de liens : `EmployeeOf`, `GraduatedFrom`, `MemberOf`, etc.

5. **Créer les templates d'affichage** :
   - `hd/etc/org.txt` : Affichage d'une organisation
   - `hd/etc/updorg.txt` : Formulaire d'édition
   - Intégrer l'affichage dans les pages personnes et événements

6. **Créer de nouveaux types d'événements** liés aux organisations :
   - `Epers_Employment` : Emploi dans une organisation
   - `Epers_Graduation` : Diplôme d'une école
   - `Epers_Membership` : Adhésion à une association

**Complexité** : ⚠️ **Élevée** - Nécessite une modification majeure de la structure de données

**Recommandation** : Commencer par étendre les champs existants (étapes 1 et 2) avant de créer une nouvelle entité

#### 4. Améliorer le champ "source" structuré

**Objectif** : Transformer le champ `epers_src` (chaîne simple) en structure plus riche

**Approche** :
- Créer un type `source_info` avec champs : auteur, date, lieu, URL, etc.
- Remplacer `epers_src : 'string` par `epers_src : source_info option`
- Maintenir la rétrocompatibilité en convertissant les anciennes chaînes

**Avantages** :
- Permet une recherche et un filtrage plus précis
- Facilite la citation et la vérification des sources

### 📋 Checklist pour les prochaines modifications

Pour chaque nouvelle modification, suivre systématiquement :

- [ ] **Phase 1 : Planification**
  - [ ] Identifier tous les fichiers concernés avec `grep`
  - [ ] Créer une checklist spécifique à la modification
  - [ ] Vérifier la rétrocompatibilité

- [ ] **Phase 2 : Modification du modèle de données**
  - [ ] Modifier `lib/def/def.ml`
  - [ ] Mettre à jour les interfaces (`.mli`)
  - [ ] Mettre à jour tous les constructeurs
  - [ ] Mettre à jour tous les pattern-matchings

- [ ] **Phase 3 : Formulaires et traitement**
  - [ ] Ajouter les champs dans les templates d'édition
  - [ ] Mettre à jour `lib/update*.ml` pour la lecture
  - [ ] Mettre à jour `lib/update*Ok.ml` pour l'écriture

- [ ] **Phase 4 : Affichage**
  - [ ] Mettre à jour `lib/perso.ml` (évaluations de champs)
  - [ ] Mettre à jour TOUS les templates d'affichage
  - [ ] Vérifier `chronologie.txt` (souvent oublié !)

- [ ] **Phase 5 : Compilation et test**
  - [ ] Compiler avec `make gwd` ou `make build-geneweb`
  - [ ] Résoudre toutes les erreurs de compilation
  - [ ] Redémarrer le serveur : `./stop-gwd.sh && ./start-gwd.sh`
  - [ ] Tester en mode édition et lecture
  - [ ] Vérifier dans plusieurs templates différents

### 📚 Ressources et références

- **Règles de développement** : `.cursor/rules/geneweb-ocaml-development.mdc`
- **Guidelines OCaml** : `.cursor/rules/ocaml-guidelines.mdc`
- **Scripts utiles** : `start-gwd.sh` et `stop-gwd.sh` pour gérer le serveur
- **Plan sources multiples** : `PLAN_SOURCES_MULTIPLES.md` (plan détaillé pour transformer les sources en système multi-évalué)

---

## PROCHAINE MODIFICATION PRIORITAIRE : Sources Multiples

Voir le plan détaillé dans **`PLAN_SOURCES_MULTIPLES.md`** pour transformer le champ `epers_src` (une seule source) en système multi-sources avec métadonnées détaillées.

