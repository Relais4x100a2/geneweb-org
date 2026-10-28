# Pilier 1 : Modification/Ajout/Transformation de Champs

## Objectif

Améliorer et étendre les champs existants dans GeneWeb pour permettre une meilleure structuration et gestion des données généalogiques.

## Vue d'ensemble

Ce pilier se concentre sur :
- La transformation du système de sources (multi-sources avec métadonnées)
- L'ajout de nouveaux champs aux événements
- La transformation de champs existants pour une meilleure structuration

## Projets Principaux

### 1. Système Multi-Sources avec Métadonnées Détaillées

Transformer le champ `epers_src : 'string` en un système multi-sources permettant :
- D'ajouter plusieurs sources à chaque événement
- **Distinction document/extrait** : Informations réutilisables sur le document + informations spécifiques à l'extrait (page, numéro, lien)
- **Mode simple et mode avancé** : Saisie rapide ou formulaire détaillé
- **Réutilisation de documents** : Sélectionner un document existant et ajouter seulement les infos d'extrait

**Voir** : [PLAN.md](./PLAN.md) Phase 1 et 2 pour le plan détaillé

### 2. Adresses Historiques et Géolocalisation

Améliorer la gestion des adresses :
- **Adresse historique** : Adresse telle que citée dans la source
- **Adresse actuelle** : Adresse moderne équivalente (si différente)
- **Coordonnées géographiques** : Pour affichage sur cartes (OpenStreetMap, Google Maps)
- **Géocodage automatique** : Obtenir les coordonnées depuis l'adresse

**Voir** : [PLAN.md](./PLAN.md) Phase 3 pour le plan détaillé

### 3. Formalisation des Événements Personnalisés

Uniformiser les événements personnalisés tout en gardant la liberté :
- **Catégorisation** : Suggérer des catégories (Éducation, Profession, Militaire, etc.)
- **Auto-complétion** : Suggérer des événements similaires déjà utilisés
- **Mode libre** : Toujours permettre la saisie libre pour les cas particuliers

### 4. Enrichissement du Système de Témoins

Étendre les témoins pour plus de flexibilité :
- **Organisations comme témoins** : Permettre d'ajouter des organisations (pas seulement des personnes)
- **Rôles variés** : Témoin, Officier, Célébrant, Greffier, etc. (pas seulement "témoin")
- **Intégration avec Relations** : Lier les témoins aux relations existantes

**Voir** : [PLAN.md](./PLAN.md) Phase 4 pour le plan détaillé

### 5. Assistance LLM pour Génération de Données

Outil optionnel pour assister la saisie :
- **Extraction depuis texte** : Analyser un texte libre et extraire les informations
- **Complétion intelligente** : Suggérer des complétions cohérentes
- **Normalisation** : Proposer des normalisations de données
- **Configuration flexible** : Support LLM local (Ollama) ou externe (OpenAI, Anthropic)
- **Sécurité** : Validation manuelle obligatoire, pas d'envoi automatique

**Voir** : [PLAN.md](./PLAN.md) Phase 5 pour le plan détaillé

## Architecture

Les modifications suivront le processus standard de modification de types GeneWeb :
1. Modification des types dans `lib/def/def.ml`
2. Mise à jour de tous les constructeurs et pattern-matchings
3. Mise à jour des templates d'édition et d'affichage
4. Mise à jour des fonctions de sérialisation
5. Tests et validation

## Branche Git

Développement sur la branche : `feature/fields-enhancement`

## Documentation

- [PLAN.md](./PLAN.md) : Plan détaillé des modifications
- [../connaissances-acquises.md](../connaissances-acquises.md) : Connaissances de base sur GeneWeb

