# Pilier 2 : Création d'entité "Organisation"

## Objectif

Ajouter un nouveau type d'entité principale dans GeneWeb pour représenter les organisations (entreprises, écoles, associations, etc.) et permettre de lier ces organisations aux personnes et événements.

## Vue d'ensemble

Ce pilier se concentre sur :
- La création d'un nouveau type d'entité "Organisation"
- L'intégration dans le modèle de données GeneWeb
- Les liens avec les personnes et événements
- Les fonctionnalités CRUD complètes pour les organisations

## Cas d'usage

Les organisations permettront de modéliser :
- **Entreprises** : Lieux d'emploi, carrières professionnelles
- **Écoles** : Établissements d'enseignement, diplômes
- **Associations** : Adhésions, participations
- **Institutions** : Hôpitaux, administrations, etc.

## Liens avec les entités existantes

### Liens avec les Personnes

- **Employé de** : Relation d'emploi avec une organisation
- **Membre de** : Adhésion à une association
- **Diplômé de** : Diplôme obtenu d'une école

### Liens avec les Événements

- **Événement lié à une organisation** : Un événement peut être associé à une organisation
  - Exemple : "Diplôme obtenu à l'École X"
  - Exemple : "Emploi commencé à l'Entreprise Y"

## Outil de Migration/Nettoyage

Un **wizard de migration** sera développé pour aider à transformer en masse des événements existants en organisations. Cet outil permettra :

- Détection automatique des événements candidats (entreprises, écoles, etc.)
- Transformation interactive avec prévisualisation
- Déduplication et fusion d'organisations similaires
- Nettoyage et validation des données

**Voir** : [PLAN.md](./PLAN.md) Phase 7 pour les détails.

## Architecture Cible

### Types de données

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
  (* ... autres champs ... *)
}
```

### Structure de base de données

- Ajouter les tables d'organisations dans la structure de base de données
- Créer un nouveau fichier de données `base.org` ou intégrer dans `base`
- Gérer les identifiants d'organisations (`iorg`)

### Fonctions CRUD

- `lib/organization.ml` : Fonctions de manipulation
- `lib/updateOrgOk.ml` : Traitement des formulaires
- `lib/updateOrg.ml` : Génération des formulaires

### Templates

- `hd/etc/org.txt` : Affichage d'une organisation
- `hd/etc/updorg.txt` : Formulaire d'édition
- Intégration dans les pages personnes et événements

## Branche Git

Développement sur la branche : `feature/organizations`

**Note** : Le wizard de migration sera développé dans la même branche, après que le système d'organisations de base soit fonctionnel (Phase 7).

## Documentation

- [PLAN.md](./PLAN.md) : Plan détaillé de l'implémentation
- [../connaissances-acquises.md](../connaissances-acquises.md) : Connaissances de base sur GeneWeb

