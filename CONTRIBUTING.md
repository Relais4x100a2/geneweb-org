# Guide de Contribution au Fork GeneWeb

Ce document décrit comment contribuer au développement du fork GeneWeb organisé autour de 3 piliers.

## Structure du Projet

Le projet est organisé en branches Git et documentation :

### Branches

- **`base/v7.0.0`** : Base stable depuis le tag v7.0.0 d'upstream
- **`develop`** : Branche d'intégration principale pour les 3 piliers
- **`feature/fields-enhancement`** : Développement du pilier 1 (champs)
- **`feature/organizations`** : Développement du pilier 2 (organisations)
- **`feature/imports`** : Développement du pilier 3 (imports)

### Documentation

Toute la documentation est dans le répertoire `docs/` :
- `docs/README.md` : Index de la documentation
- `docs/connaissances-acquises.md` : Connaissances de base sur GeneWeb
- `docs/pilier-*/` : Documentation spécifique à chaque pilier

## Workflow de Développement

### 1. Choisir un Pilier

Avant de commencer, identifiez sur quel pilier vous travaillez :
- **Pilier 1** : Modification/ajout/transformation de champs
- **Pilier 2** : Création d'entité "Organisation"
- **Pilier 3** : Imports automatisés (Excel/API)

Consultez la documentation du pilier dans `docs/pilier-*/README.md` et `docs/pilier-*/PLAN.md`.

### 2. Créer une Branche de Fonctionnalité

Depuis la branche `develop`, créez une branche pour votre fonctionnalité :

```bash
git checkout develop
git pull origin develop
git checkout -b feature/nom-de-la-fonctionnalite
```

**Convention de nommage** :
- `feature/` pour les nouvelles fonctionnalités
- `fix/` pour les corrections de bugs
- `docs/` pour la documentation uniquement

### 3. Développer

- Suivez les guidelines OCaml définies dans `.cursor/rules/ocaml-guidelines.mdc`
- Respectez le processus de modification de types documenté dans `docs/connaissances-acquises.md`
- Documentez vos décisions et progrès dans les fichiers appropriés du pilier

### 4. Tester

Avant de soumettre votre code :

```bash
# Compiler le projet
make gwd

# Résoudre toutes les erreurs de compilation
# Les erreurs OCaml sont très utiles pour trouver ce qui manque

# Redémarrer le serveur après compilation
./stop-gwd.sh && ./start-gwd.sh

# Tester en mode édition (saisie et sauvegarde)
# Tester en mode lecture (affichage dans différents templates)
```

### 5. Commiter

Faites des commits atomiques avec des messages clairs :

```bash
git add .
git commit -m "feat(pilier-1): ajout système multi-sources pour événements"
```

**Convention de messages** :
- `feat(pilier-X):` pour les nouvelles fonctionnalités
- `fix(pilier-X):` pour les corrections
- `docs(pilier-X):` pour la documentation
- `refactor(pilier-X):` pour les refactorisations

### 6. Pousser et Créer une Pull Request

```bash
git push origin feature/nom-de-la-fonctionnalite
```

Créez une Pull Request vers la branche `develop` (ou vers la branche `feature/*` du pilier si elle existe).

## Standards de Code OCaml

### Principes Fondamentaux

1. **Simplicité et lisibilité** : Le code est lu 100 fois plus qu'il n'est écrit
2. **Pattern-matching exhaustif** : Toujours compléter les pattern-matchings
3. **Types explicites** : Préférer les types variant aux booléens quand la sémantique n'est pas claire
4. **Fonctions petites** : Subdiviser en petites fonctions faciles à comprendre
5. **Factorisation** : Ne jamais copier-coller du code

### Conventions

- **Noms de variables** : utiliser des underscores (`int_of_string`, pas `intOfString`)
- **Pattern-matching** : toujours inclure le `|` sur la première clause
- **Indentation** : 1 ou 2 espaces, jamais de tabs
- **Largeur** : 80 colonnes maximum
- **Commentaires** : seulement quand nécessaire

Voir `.cursor/rules/ocaml-guidelines.mdc` pour les détails complets.

## Processus de Modification de Types

Lors de la modification d'un type (record, variant, tuple), suivre systématiquement la checklist dans `docs/connaissances-acquises.md` :

1. ✅ Mise à jour du type de base (`lib/def/def.ml`)
2. ✅ Recherche systématique de tous les usages (`grep`)
3. ✅ Mise à jour des constructeurs
4. ✅ Mise à jour des pattern-matchings
5. ✅ Mise à jour des tuples (si applicable)
6. ✅ Mise à jour des interfaces (`.mli`)
7. ✅ Mise à jour des formulaires
8. ✅ Mise à jour du traitement des formulaires
9. ✅ Mise à jour de l'affichage en mode lecture
10. ✅ Compilation et tests

**⚠️ Important** : Ne pas oublier les templates d'affichage, notamment `chronologie.txt` qui est souvent oublié !

## Checklist Avant Merge

Avant de merger votre code dans `develop`, vérifiez :

- [ ] Le code compile sans erreurs ni avertissements
- [ ] Tous les tests passent
- [ ] Le serveur redémarre correctement
- [ ] Les fonctionnalités sont testées en mode édition ET lecture
- [ ] Tous les templates d'affichage sont mis à jour
- [ ] La documentation est à jour
- [ ] Les commits sont atomiques et bien nommés
- [ ] Le code respecte les guidelines OCaml

## Gestion des Conflits

En cas de conflit lors du merge :

1. Mettre à jour votre branche depuis `develop` :
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/votre-branche
   git merge develop
   ```

2. Résoudre les conflits manuellement

3. Tester après résolution des conflits

4. Pousser les modifications

## Questions et Support

Pour toute question :
- Consultez la documentation dans `docs/`
- Consultez les guidelines dans `.cursor/rules/`
- Vérifiez les plans détaillés dans `docs/pilier-*/PLAN.md`

## Ressources

- **Documentation principale** : `docs/README.md`
- **Connaissances acquises** : `docs/connaissances-acquises.md`
- **Guidelines OCaml** : `.cursor/rules/ocaml-guidelines.mdc`
- **Développement GeneWeb** : `.cursor/rules/geneweb-ocaml-development.mdc`
