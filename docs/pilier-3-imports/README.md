# Pilier 3 : Imports Automatisés (Excel/API)

## Objectif

Créer un système d'import automatisé de données dans GeneWeb depuis des fichiers Excel ou via une API, permettant d'importer rapidement de grandes quantités de données généalogiques.

## Vue d'ensemble

Ce pilier se concentre sur :
- L'import depuis fichiers Excel (.xlsx, .xls)
- L'import via API REST
- La validation et transformation des données
- La gestion des erreurs et des conflits

## Cas d'usage

### Import Excel

- Import de listes de personnes depuis tableurs
- Import d'événements depuis fichiers structurés
- Import de données depuis d'autres logiciels de généalogie exportés en Excel

### Import API

- Synchronisation avec d'autres systèmes
- Import depuis bases de données externes
- Intégration avec services généalogiques en ligne

## Formats Supportés

### Excel

- Format de fichier : `.xlsx`, `.xls`
- Colonnes attendues : Prénom, Nom, Date de naissance, Lieu de naissance, etc.
- Support de plusieurs feuilles (une par type d'entité)

### API

- Format : REST API (JSON)
- Endpoints pour personnes, événements, familles
- Authentification et sécurité

## Architecture

### Composants Principaux

1. **Parser Excel** : Lecture et parsing des fichiers Excel
2. **Parser API** : Communication avec l'API externe
3. **Validateur** : Validation des données importées
4. **Transformateur** : Transformation des données au format GeneWeb
5. **Importeur** : Insertion des données dans la base GeneWeb

### Fichiers à Créer

- `lib/import/excel_parser.ml` : Parser pour fichiers Excel
- `lib/import/api_client.ml` : Client API
- `lib/import/validator.ml` : Validation des données
- `lib/import/transformer.ml` : Transformation des données
- `lib/import/importer.ml` : Import dans la base
- `bin/gwimport/gwimport.ml` : Exécutable principal

## Branche Git

Développement sur la branche : `feature/imports`

## Documentation

- [PLAN.md](./PLAN.md) : Plan détaillé de l'implémentation
- [../connaissances-acquises.md](../connaissances-acquises.md) : Connaissances de base sur GeneWeb

