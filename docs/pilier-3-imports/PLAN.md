# Plan : Imports Automatisés (Excel/API)

## Objectif

Créer un système d'import automatisé de données dans GeneWeb depuis des fichiers Excel ou via une API, permettant d'importer rapidement de grandes quantités de données généalogiques.

---

## PHASE 1 : Import depuis Excel

### 1. Choix de la bibliothèque OCaml

**Options :**
- `xlsx` : Bibliothèque OCaml pour lire les fichiers Excel
- `ocaml-xlsx` : Alternative
- Parser CSV si Excel exporte en CSV

**Recommandation** : Utiliser `xlsx` si disponible, sinon parser CSV.

### 2. Structure du parser Excel

**Fichier** : `lib/import/excel_parser.ml`

```ocaml
type excel_row = {
  first_name : string option;
  surname : string option;
  birth_date : string option;
  birth_place : string option;
  (* ... autres champs ... *)
}

val parse_excel_file : string -> excel_row list
```

### 3. Mapping des colonnes

Permettre la configuration du mapping entre colonnes Excel et champs GeneWeb :
- Configuration par fichier de mapping
- Interface pour définir le mapping
- Support de plusieurs formats de colonnes

### 4. Validation des données

**Fichier** : `lib/import/validator.ml`

- Validation des dates (format, cohérence)
- Validation des noms (non vides, caractères valides)
- Validation des relations (parents existants, etc.)
- Détection des doublons

### 5. Transformation des données

**Fichier** : `lib/import/transformer.ml`

- Conversion des dates au format `cdate`
- Normalisation des noms et lieux
- Création des structures `gen_person`
- Gestion des relations

---

## PHASE 2 : Import via API

### 1. Client API

**Fichier** : `lib/import/api_client.ml`

```ocaml
type api_config = {
  base_url : string;
  api_key : string option;
  timeout : int;
}

val fetch_persons : api_config -> person_data list
val fetch_events : api_config -> event_data list
val fetch_families : api_config -> family_data list
```

### 2. Format de données API

Définir le format JSON attendu :
```json
{
  "persons": [
    {
      "first_name": "Jean",
      "surname": "Dupont",
      "birth_date": "1980-01-15",
      "birth_place": "Paris"
    }
  ],
  "events": [...],
  "families": [...]
}
```

### 3. Authentification

- Support de l'authentification par clé API
- Support de l'authentification OAuth si nécessaire
- Gestion des tokens et refresh

### 4. Gestion des erreurs réseau

- Retry automatique en cas d'échec
- Timeout configurable
- Gestion des erreurs HTTP

---

## PHASE 3 : Import dans la base GeneWeb

### 1. Importeur principal

**Fichier** : `lib/import/importer.ml`

```ocaml
type import_result = {
  success : int;
  errors : string list;
  warnings : string list;
}

val import_persons : person_data list -> import_result
val import_events : event_data list -> import_result
val import_families : family_data list -> import_result
```

### 2. Gestion des conflits

- Détection des doublons (par nom, dates, etc.)
- Options de résolution :
  - Ignorer les doublons
  - Fusionner les données
  - Créer de nouvelles entrées
- Interface pour résoudre les conflits manuellement

### 3. Transaction et rollback

- Utiliser des transactions pour garantir la cohérence
- Possibilité de rollback en cas d'erreur
- Log des opérations pour audit

### 4. Progression et reporting

- Affichage de la progression de l'import
- Rapport détaillé des erreurs et avertissements
- Statistiques de l'import

---

## PHASE 4 : Interface utilisateur

### 1. Exécutable en ligne de commande

**Fichier** : `bin/gwimport/gwimport.ml`

```bash
gwimport --excel file.xlsx --base mybase.gwb
gwimport --api https://api.example.com --base mybase.gwb
```

### 2. Interface web (optionnel)

- Page d'upload de fichiers Excel
- Configuration du mapping
- Prévisualisation des données avant import
- Lancement de l'import
- Affichage des résultats

### 3. Configuration

**Fichier** : `import_config.json` (exemple)

```json
{
  "excel": {
    "mapping": {
      "first_name": "A",
      "surname": "B",
      "birth_date": "C"
    },
    "skip_first_row": true
  },
  "api": {
    "base_url": "https://api.example.com",
    "api_key": "..."
  }
}
```

---

## PHASE 5 : Fonctionnalités avancées

### 1. Import incrémental

- Détection des modifications depuis le dernier import
- Mise à jour uniquement des données modifiées
- Support de timestamps

### 2. Import de médias

- Import de photos depuis Excel (URLs)
- Import de documents
- Association aux personnes/événements

### 3. Validation avancée

- Vérification de cohérence généalogique
- Détection d'anomalies (dates impossibles, etc.)
- Suggestions de corrections

### 4. Export de mapping

- Exporter le mapping configuré
- Partager les configurations entre utilisateurs
- Templates de mapping pour cas courants

---

## Checklist de Développement

### Phase 1 : Excel
- [ ] Choisir et intégrer la bibliothèque Excel
- [ ] Créer `lib/import/excel_parser.ml`
- [ ] Implémenter le parsing des fichiers Excel
- [ ] Créer le système de mapping des colonnes
- [ ] Tester avec différents formats Excel

### Phase 2 : API
- [ ] Créer `lib/import/api_client.ml`
- [ ] Implémenter la communication HTTP
- [ ] Gérer l'authentification
- [ ] Parser les réponses JSON
- [ ] Tester avec différentes APIs

### Phase 3 : Import
- [ ] Créer `lib/import/validator.ml`
- [ ] Créer `lib/import/transformer.ml`
- [ ] Créer `lib/import/importer.ml`
- [ ] Implémenter la gestion des conflits
- [ ] Implémenter les transactions
- [ ] Tester l'import complet

### Phase 4 : Interface
- [ ] Créer `bin/gwimport/gwimport.ml`
- [ ] Implémenter les options en ligne de commande
- [ ] Créer l'interface web (si nécessaire)
- [ ] Créer le système de configuration
- [ ] Tester l'interface utilisateur

### Phase 5 : Avancé
- [ ] Implémenter l'import incrémental
- [ ] Implémenter l'import de médias
- [ ] Améliorer la validation
- [ ] Créer les templates de mapping

---

## Points d'Attention

1. **Performance** : Les imports peuvent être volumineux, optimiser pour la vitesse
2. **Validation** : Valider rigoureusement pour éviter la corruption des données
3. **Sécurité** : Valider les entrées, éviter les injections
4. **Erreurs** : Gérer gracieusement les erreurs, fournir des messages clairs
5. **Rollback** : Permettre l'annulation en cas de problème

## Dépendances Externes

- Bibliothèque Excel : `xlsx` ou équivalent
- Bibliothèque HTTP : `cohttp` ou `httpaf`
- Bibliothèque JSON : `yojson` ou `jsonm`
- Bibliothèque CSV : `csv` (si nécessaire)

## Critères de Succès

- [ ] On peut importer un fichier Excel avec des personnes
- [ ] On peut importer depuis une API
- [ ] Les données sont validées avant import
- [ ] Les conflits sont détectés et gérés
- [ ] Les erreurs sont clairement rapportées
- [ ] L'import est rapide même pour de gros volumes
- [ ] L'interface est intuitive

