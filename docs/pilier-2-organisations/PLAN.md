# Plan : Création d'entité "Organisation"

## Objectif

Ajouter un nouveau type d'entité principale dans GeneWeb pour représenter les organisations (entreprises, écoles, associations, etc.) et permettre de lier ces organisations aux personnes et événements.

---

## PHASE 1 : Définition du type et structure de base

### 1. Définir le type dans `lib/def/def.ml`

```ocaml
type organization_type =
  | Company
  | School
  | Association
  | Institution
  | Other of string

type ('string) gen_organization = {
  org_name : 'string;
  org_type : organization_type;
  org_address : 'string;
  org_note : 'string;
  org_src : 'string;
  org_founded_date : cdate option;
  org_dissolved_date : cdate option;
  org_url : 'string option;
  org_email : 'string option;
  org_phone : 'string option;
}
```

### 2. Ajouter les types de liens avec personnes

```ocaml
type organization_link_type =
  | EmployeeOf
  | GraduatedFrom
  | MemberOf
  | FounderOf
  | OtherLink of string

type ('person, 'string) gen_organization_link = {
  ol_organization : 'person;  (* Référence à l'organisation *)
  ol_type : organization_link_type;
  ol_start_date : cdate option;
  ol_end_date : cdate option;
  ol_note : 'string;
}
```

### 3. Ajouter les liens dans `gen_person`

```ocaml
type ('iper, 'person, 'string) gen_person = {
  (* ... champs existants ... *)
  organization_links : ('person, 'string) gen_organization_link list;
}
```

### 4. Ajouter les liens dans `gen_pers_event`

```ocaml
type ('person, 'string) gen_pers_event = {
  (* ... champs existants ... *)
  epers_organization : 'person option;  (* Organisation liée à l'événement *)
}
```

---

## PHASE 2 : Intégration dans la base de données

### 1. Ajouter les tables dans `lib/db/database.ml`

- Créer un tableau d'organisations similaire aux tableaux de personnes et familles
- Gérer les identifiants d'organisations (`iorg`)
- Ajouter les fonctions de lecture

### 2. Ajouter l'écriture dans `lib/db/outbase.ml`

- Sérialiser les organisations
- Gérer les offsets et index

### 3. Mettre à jour le format magique

- Changer le magic number si nécessaire
- Ou utiliser un champ de version pour la compatibilité

---

## PHASE 3 : Fonctions CRUD

### 1. Créer `lib/organization.ml`

Fonctions principales :
- `get_organization` : Récupérer une organisation par ID
- `find_organization` : Rechercher une organisation
- `create_organization` : Créer une nouvelle organisation
- `update_organization` : Mettre à jour une organisation
- `delete_organization` : Supprimer une organisation (avec vérifications)

### 2. Créer `lib/updateOrgOk.ml`

- Traitement des formulaires de création/modification
- Validation des données
- Gestion des erreurs

### 3. Créer `lib/updateOrg.ml`

- Génération des formulaires d'édition
- Affichage des données existantes
- Gestion des liens avec personnes/événements

---

## PHASE 4 : Templates d'interface

### 1. Créer `hd/etc/org.txt`

Template d'affichage d'une organisation :
- Informations de base (nom, type, adresse)
- Dates de fondation/dissolution
- Liens avec personnes
- Événements associés

### 2. Créer `hd/etc/updorg.txt`

Formulaire d'édition :
- Champs de saisie pour tous les attributs
- Sélection du type d'organisation
- Gestion des dates

### 3. Intégrer dans les pages personnes

- Afficher les organisations liées dans `hd/etc/templm/perso.txt`
- Permettre l'ajout de liens depuis la page personne

### 4. Intégrer dans les événements

- Permettre de lier un événement à une organisation
- Afficher l'organisation dans les templates d'événements

---

## PHASE 5 : Nouveaux types d'événements

### 1. Ajouter des événements liés aux organisations

```ocaml
type 'string gen_pers_event_name =
  (* ... événements existants ... *)
  | Epers_Employment
  | Epers_Graduation
  | Epers_Membership
```

### 2. Mettre à jour les templates

- Ajouter les nouveaux événements dans les listes
- Créer des templates spécifiques si nécessaire

---

## PHASE 6 : Fonctions utilitaires

### 1. Recherche d'organisations

- Recherche par nom
- Recherche par type
- Recherche par lieu

### 2. Statistiques

- Nombre d'organisations par type
- Organisations les plus liées
- Évolution dans le temps

### 3. Export/Import

- Support GEDCOM pour les organisations
- Export vers formats standards

---

## Checklist de Développement

### Phase 1 : Types
- [ ] Définir `organization_type` dans `lib/def/def.ml`
- [ ] Définir `gen_organization` dans `lib/def/def.ml`
- [ ] Définir `organization_link_type` dans `lib/def/def.ml`
- [ ] Définir `gen_organization_link` dans `lib/def/def.ml`
- [ ] Ajouter `organization_links` dans `gen_person`
- [ ] Ajouter `epers_organization` dans `gen_pers_event`
- [ ] Mettre à jour les interfaces (`.mli`)

### Phase 2 : Base de données
- [ ] Ajouter tableau d'organisations dans `lib/db/database.ml`
- [ ] Ajouter fonctions de lecture dans `lib/db/database.ml`
- [ ] Ajouter sérialisation dans `lib/db/outbase.ml`
- [ ] Mettre à jour le format magique si nécessaire
- [ ] Tester la lecture/écriture

### Phase 3 : CRUD
- [ ] Créer `lib/organization.ml` avec fonctions de base
- [ ] Créer `lib/updateOrgOk.ml` pour traitement formulaires
- [ ] Créer `lib/updateOrg.ml` pour génération formulaires
- [ ] Tester création/modification/suppression

### Phase 4 : Templates
- [ ] Créer `hd/etc/org.txt` pour affichage
- [ ] Créer `hd/etc/updorg.txt` pour édition
- [ ] Intégrer dans pages personnes
- [ ] Intégrer dans événements
- [ ] Tester l'interface complète

### Phase 5 : Événements
- [ ] Ajouter nouveaux types d'événements
- [ ] Mettre à jour les templates d'événements
- [ ] Tester les nouveaux événements

### Phase 6 : Utilitaires
- [ ] Implémenter recherche
- [ ] Implémenter statistiques
- [ ] Implémenter export/import

### Phase 7 : Wizard de Migration/Nettoyage (Outil d'aide à la migration)

**Objectif** : Créer un outil interactif pour migrer en masse des événements existants vers des organisations.

#### Fonctionnalités du Wizard

1. **Détection automatique des candidats**
   - Identifier les événements qui pourraient être des organisations
   - Exemples : événements avec des noms d'entreprises, d'écoles, d'associations
   - Utiliser des patterns de détection (mots-clés, formats de noms)

2. **Interface interactive de sélection**
   - Afficher la liste des événements candidats
   - Permettre la sélection manuelle ou automatique
   - Prévisualisation des transformations avant application

3. **Transformation des événements**
   - Créer une organisation à partir d'un événement
   - Extraire les informations pertinentes (nom, date, lieu, etc.)
   - Créer un lien entre la personne et la nouvelle organisation
   - Option : supprimer l'événement original ou le conserver comme référence

4. **Déduplication**
   - Détecter les organisations en double
   - Proposer la fusion d'organisations similaires
   - Validation manuelle avant fusion

5. **Nettoyage et validation**
   - Vérifier la cohérence des données après migration
   - Signaler les incohérences
   - Proposer des corrections

#### Fichiers à créer

- `lib/migration/event_to_org.ml` : Logique de détection et transformation
- `lib/migration/deduplication.ml` : Détection et fusion des doublons
- `bin/gwmigrate/gwmigrate.ml` : Exécutable en ligne de commande
- `hd/etc/migrate_events.txt` : Interface web du wizard (optionnel)

#### Checklist Phase 7

- [ ] Créer `lib/migration/event_to_org.ml` avec fonctions de détection
- [ ] Implémenter l'algorithme de détection des candidats
- [ ] Créer les fonctions de transformation événement → organisation
- [ ] Implémenter la déduplication
- [ ] Créer l'interface en ligne de commande
- [ ] Créer l'interface web (optionnel)
- [ ] Implémenter la validation et le nettoyage
- [ ] Tester avec des bases réelles
- [ ] Documenter les patterns de détection

---

## Points d'Attention

1. **Compatibilité** : Les modifications doivent être rétrocompatibles avec les bases existantes
2. **Performance** : Les organisations peuvent être nombreuses, optimiser les requêtes
3. **Validation** : Valider les données avant sauvegarde
4. **Suppression** : Vérifier les liens avant suppression d'une organisation
5. **Migration** : Prévoir un script de migration si nécessaire

## Critères de Succès

- [ ] On peut créer une organisation
- [ ] On peut lier une personne à une organisation
- [ ] On peut lier un événement à une organisation
- [ ] Les organisations s'affichent correctement
- [ ] Les liens sont fonctionnels et affichés
- [ ] La recherche fonctionne
- [ ] Les données sont persistées correctement

