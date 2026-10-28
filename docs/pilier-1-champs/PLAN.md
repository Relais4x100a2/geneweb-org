# Plan : Transformation du champ Source en système multi-sources

## Objectif

Transformer le champ `epers_src : 'string` (une seule source) en un système multi-sources similaire aux témoins, permettant d'ajouter plusieurs sources à chaque événement.

**Ensuite** : Permettre d'ajouter des métadonnées détaillées à chaque source (auteur, date, URL, etc.).

---

## PHASE 1 : Système multi-sources simple (chaînes de caractères)

### Objectif Phase 1

Transformer `epers_src : 'string` en `epers_sources : 'string list` (ou `'string array`), permettant d'ajouter plusieurs sources sous forme de chaînes.

### Checklist Phase 1

#### 1. Modification du type de base

**Fichier** : `lib/def/def.ml`
- Ligne ~181 : Remplacer `epers_src : 'string;` par `epers_sources : 'string list;`
- **Rétrocompatibilité** : Utiliser un champ optionnel temporaire pour la migration, ou accepter de convertir les anciennes bases
- Mettre à jour `lib/show/def_show.mli` si nécessaire

**Note importante** : Cela cassera la compatibilité avec les anciennes bases. Il faudra soit :
- Accepter de convertir les anciennes bases (script de migration)
- OU utiliser un champ optionnel temporaire pour la transition

**Recommandation** : Utiliser `epers_sources : 'string list` et écrire une fonction de migration qui convertit `epers_src` en liste.

#### 2. Recherche systématique de tous les usages

```bash
# Trouver tous les endroits qui utilisent epers_src
grep -r "epers_src\|\.epers_src\|e_src\|event\.src\|\.src" lib/ --include="*.ml" -n

# Trouver dans les templates
grep -r "e_src\|event\.src\|\.src" hd/etc/ --include="*.txt" -n

# Trouver dans les plugins
grep -r "epers_src\|e_src" plugins/ --include="*.ml" -n
```

**Fichiers à vérifier systématiquement** :
- `lib/util/futil.ml` : Fonctions `map_pers_event`
- `lib/hasher.ml` : Hachage des événements
- `lib/updateIndOk.ml` : Reconstruction depuis formulaire
- `lib/updateInd.ml` : Affichage dans formulaire
- `lib/perso.ml` : Évaluations pour templates
- `lib/event.ml` : Gestion des événements
- `lib/db/driver.ml` : Accès base de données
- `lib/db/` : Sérialisation/désérialisation
- `plugins/gwxjg/` : Plugin JSON
- Tous les templates d'affichage

#### 3. Mise à jour des constructeurs

**Fichiers principaux** :
- `lib/util/futil.ml` : `map_pers_event` - remplacer `epers_src` par `epers_sources`
- `lib/updateIndOk.ml` : Création d'événements - remplacer par liste
- `lib/updateFamOk.ml` : Si applicable pour événements familiaux
- `lib/fixbase.ml` : `mk_pevent` - initialiser avec `[]`
- `bin/gwc/db1link.ml` : Constructeurs lors de l'import
- `bin/ged2gwb/ged2gwb.ml` : Import GEDCOM
- Tous les autres endroits trouvés par grep

**Exemple de conversion** :
```ocaml
(* AVANT *)
epers_src = "";

(* APRÈS *)
epers_sources = [];
```

#### 4. Mise à jour des pattern-matchings

**Fichiers principaux** :
- `lib/util/futil.ml` : Pattern matching dans `map_pers_event`
- `lib/hasher.ml` : Hachage du champ
- Tous les endroits qui pattern-match sur `gen_pers_event`

**Exemple** :
```ocaml
(* AVANT *)
let map_pers_event ?(fd = identity) fp fs e =
  {
    (* ... *)
    epers_src = fs e.epers_src;
    (* ... *)
  }

(* APRÈS *)
let map_pers_event ?(fd = identity) fp fs e =
  {
    (* ... *)
    epers_sources = List.map fs e.epers_sources;
    (* ... *)
  }
```

#### 5. Mise à jour du traitement des formulaires

**Fichier** : `lib/updateIndOk.ml`

Créer une fonction similaire à `reconstitute_pevents` pour les sources :
```ocaml
let reconstitute_sources conf cnt =
  let rec loop i =
    let key = "e" ^ string_of_int cnt ^ "_src" ^ string_of_int i in
    match get_nth conf key cnt with
    | Some src when src <> "" ->
        let src = only_printable src in
        src :: loop (i + 1)
    | _ -> []
  in
  (* Support pour l'ancien format e_src (rétrocompatibilité) *)
  match get_nth conf "e_src" cnt with
  | Some old_src when old_src <> "" ->
      only_printable old_src :: loop 0
  | _ -> loop 0

let epers_sources = reconstitute_sources conf cnt
```

#### 6. Mise à jour des templates d'édition

**Fichier** : `hd/etc/updind.txt`

Créer une macro `one_source` similaire à `one_witness` pour permettre l'ajout de plusieurs sources.

#### 7. Mise à jour de l'affichage dans les templates

**Fichier** : `lib/updateInd.ml`
- Créer une variable `sources` pour chaque événement (liste)
- Ajouter `has_sources : bool` pour vérifier si la liste n'est pas vide
- Exposer chaque source individuellement via `foreach;source;`

**Fichier** : `lib/perso.ml`
- Mettre à jour `eval_str_event_field` pour gérer `sources` (liste)
- Ajouter `has_sources` dans `eval_bool_event_field`
- Mettre à jour `eval_event_field_var` pour exposer les sources

**Templates d'affichage** :
- `hd/etc/templm/perso.txt` : Afficher toutes les sources
- `hd/etc/modules/chronologie.txt` : Afficher les sources dans la timeline
- `hd/etc/perso_short.txt` : Affichage court
- `hd/etc/deslist.txt` : Liste de descendants
- `hd/etc/perso_utils.txt` : Tooltips

#### 8. Mise à jour des fonctions de hachage

**Fichier** : `lib/hasher.ml`
- Remplacer `feed_string epers_src` par `(list feed_string) epers_sources`

#### 9. Mise à jour du tuple event_item

**Fichier** : `lib/event.ml`
- Remplacer `Driver.istr` (source unique) par `Driver.istr list` (liste de sources)
- Mettre à jour tous les endroits qui créent ou pattern-match sur `event_item`

**ATTENTION** : Cela change la structure du tuple, tous les endroits doivent être mis à jour !

#### 10. Mise à jour des plugins

**Fichier** : `plugins/gwxjg/gwxjg_data.ml`
- Mettre à jour `mk_pevent` pour gérer la liste de sources
- Mettre à jour `mk_event` pour exposer les sources

**Fichier** : `plugins/gwxjg/gwxjg_ezgw.ml`
- Mettre à jour `Event.src` pour retourner une liste

#### 11. Migration des anciennes données

**Option A : Script de migration**
- Créer une fonction qui lit `epers_src` et le convertit en `[epers_src]` si non vide
- Exécuter lors du chargement de l'ancienne base

**Option B : Compatibilité temporaire**
- Garder `epers_src` comme champ optionnel
- Migrer vers `epers_sources` progressivement

---

## PHASE 2 : Ajout de métadonnées aux sources

### Objectif Phase 2

Transformer `epers_sources : 'string list` en `epers_sources : source_info list` où chaque source peut contenir des métadonnées détaillées, avec distinction entre les informations sur le document (réutilisables) et les informations sur l'extrait spécifique.

### Structure proposée

**Compromis entre précision et facilité d'utilisation :**

```ocaml
(* Informations sur le document source (réutilisables) *)
type 'string source_document = {
  doc_title : 'string;              (* Titre du document *)
  doc_author : 'string option;      (* Auteur du document *)
  doc_date : 'string option;        (* Date de publication/création *)
  doc_place : 'string option;       (* Lieu de publication *)
  doc_url : 'string option;         (* URL du document complet *)
  doc_repository : 'string option;  (* Dépôt/archive où se trouve le document *)
  doc_reference : 'string option;   (* Référence/cote du document *)
}

(* Informations sur l'extrait spécifique utilisé *)
type 'string source_extract = {
  extract_page : 'string option;    (* Numéro de page, ex: "p. 45" ou "pp. 45-47" *)
  extract_number : 'string option;  (* Numéro d'acte, folio, etc. *)
  extract_link : 'string option;    (* Lien précis vers l'extrait (URL, DOI, etc.) *)
  extract_note : 'string option;    (* Note spécifique à cet extrait *)
}

(* Source complète avec document et extrait *)
type 'string source_info = {
  src_document : 'string source_document;  (* Informations sur le document *)
  src_extract : 'string source_extract;     (* Informations sur l'extrait *)
  src_note : 'string option;                (* Note générale sur cette source *)
}
```

**UX proposée :**
- **Mode simple** : Un seul champ texte (comme actuellement) pour saisie rapide
- **Mode avancé** : Formulaire détaillé avec onglets "Document" et "Extrait"
- **Réutilisation de documents** : Possibilité de sélectionner un document déjà enregistré et d'ajouter seulement les infos d'extrait
- **Auto-complétion** : Suggérer des documents existants lors de la saisie du titre

### Avantages de cette structure

1. **Réutilisabilité** : Les informations sur le document ne sont saisies qu'une fois
2. **Précision** : Les informations sur l'extrait permettent de citer précisément
3. **Flexibilité** : Mode simple pour saisie rapide, mode avancé pour précision
4. **Traçabilité** : Lien direct vers l'extrait source

### Checklist Phase 2

1. **Modification du type**
   - Définir le type `source_info` dans `lib/def/def.ml`
   - Modifier `epers_sources : 'string list` en `epers_sources : ('string source_info) list`

2. **Migration depuis Phase 1**
   - Créer une fonction de migration qui convertit les chaînes en `source_info`

3. **Mise à jour des templates d'édition**
   - Modifier `one_source` pour inclure tous les champs

4. **Mise à jour du traitement des formulaires**
   - Modifier `reconstitute_sources` pour lire tous les champs

5. **Mise à jour de l'affichage**
   - Mettre à jour les évaluations pour exposer les champs de `source_info`
   - Afficher les métadonnées de manière structurée

---

## Ordre de mise en œuvre recommandé

### Phase 1 (Priorité haute)
1. Commencer par Phase 1 (système multi-sources simple)
2. Tester et valider le système multi-sources
3. S'assurer que tout fonctionne correctement

### Phase 2 (Après validation Phase 1)
1. Ensuite seulement, ajouter les métadonnées (Phase 2)
2. Migration progressive des données

---

## Notes importantes

1. **Rétrocompatibilité** : Penser à gérer l'ancien format `e_src` dans `reconstitute_sources`
2. **Performance** : Les listes sont OK, mais si on a beaucoup de sources, considérer `array`
3. **Affichage** : Prévoir un mode d'affichage compact et un mode détaillé
4. **Validation** : Vérifier que les URLs sont valides (optionnel mais recommandé)

---

## PHASE 3 : Adresses historiques et géolocalisation

### Objectif Phase 3

Permettre de distinguer l'adresse historique (telle que citée dans la source) de l'adresse actuelle, et ajouter les coordonnées géographiques pour l'affichage sur cartes.

### Structure proposée

```ocaml
type 'string address_info = {
  addr_historical : 'string;        (* Adresse telle que citée dans la source *)
  addr_current : 'string option;    (* Adresse actuelle (si différente) *)
  addr_coordinates : coordinates option;  (* Coordonnées géographiques *)
  addr_note : 'string option;       (* Note sur l'évolution de l'adresse *)
}

type coordinates = {
  latitude : float;
  longitude : float;
  precision : float option;          (* Précision en mètres *)
}
```

### Fonctionnalités

1. **Saisie de l'adresse historique** : Champ texte libre (comme actuellement)
2. **Géocodage automatique** : Utiliser un service de géocodage (Nominatim, Google Maps, etc.) pour obtenir les coordonnées
3. **Adresse actuelle** : Champ optionnel pour saisir l'adresse moderne équivalente
4. **Affichage sur carte** : Intégration avec OpenStreetMap ou Google Maps pour visualiser les lieux
5. **Validation** : Vérifier que les coordonnées correspondent bien à l'adresse

### Fichiers à créer/modifier

- `lib/def/def.ml` : Ajouter `address_info` aux champs de lieu
- `lib/geocoding/geocoder.ml` : Service de géocodage
- `lib/geocoding/map_display.ml` : Affichage sur cartes
- `hd/etc/templm/map.txt` : Template pour affichage carte
- Templates d'édition : Ajouter champs adresse historique/actuelle

### Checklist Phase 3

- [ ] Définir le type `address_info` et `coordinates`
- [ ] Modifier les champs de lieu dans `gen_pers_event` et `gen_person`
- [ ] Créer le service de géocodage
- [ ] Implémenter la validation des coordonnées
- [ ] Créer l'interface de saisie (historique/actuelle)
- [ ] Intégrer l'affichage sur carte
- [ ] Tester avec différents services de géocodage

---

## PHASE 4 : Formalisation des événements personnalisés et enrichissement des témoins

### Objectif Phase 4

Formaliser et uniformiser les événements personnalisés tout en gardant la liberté aux utilisateurs, et enrichir le système de témoins pour inclure les organisations et d'autres rôles.

### Structure proposée pour les événements personnalisés

```ocaml
(* Catégories d'événements pour aider à la formalisation *)
type event_category =
  | Education
  | Profession
  | Militaire
  | Religieux
  | Juridique
  | Social
  | Autre of string

(* Événement personnalisé avec catégorie *)
type 'string custom_event = {
  evt_name : 'string;               (* Nom de l'événement *)
  evt_category : event_category option;  (* Catégorie pour uniformisation *)
  evt_description : 'string option; (* Description libre *)
}
```

**Stratégie d'uniformisation :**
- **Suggestion automatique** : Proposer des catégories et noms standardisés lors de la saisie
- **Auto-complétion** : Suggérer des événements similaires déjà utilisés
- **Validation optionnelle** : Permettre de valider ou ignorer les suggestions
- **Mode libre** : Toujours permettre la saisie libre pour les cas particuliers

### Enrichissement des témoins

```ocaml
type witness_role =
  | Witness                    (* Témoin classique *)
  | Official                   (* Officier d'état civil, notaire, etc. *)
  | Celebrant                  (* Célébrant religieux *)
  | Registrar                  (* Greffier, secrétaire *)
  | OtherRole of string        (* Autre rôle personnalisé *)

type ('person, 'organization) witness =
  | PersonWitness of 'person * witness_role
  | OrganizationWitness of 'organization * witness_role

(* Modifier gen_pers_event *)
type ('person, 'string) gen_pers_event = {
  (* ... champs existants ... *)
  epers_witnesses : ('person, 'organization) witness array;
}
```

### Intégration avec Relations

- Permettre de lier les témoins aux relations existantes
- Créer automatiquement des relations depuis les témoins si nécessaire
- Synchroniser les rôles entre témoins et relations

### Checklist Phase 4

- [ ] Définir `event_category` et `custom_event`
- [ ] Modifier `gen_pers_event_name` pour supporter les catégories
- [ ] Créer le système de suggestion/auto-complétion
- [ ] Définir `witness_role` et `witness`
- [ ] Modifier `epers_witnesses` pour supporter organisations et rôles
- [ ] Mettre à jour les templates d'édition des témoins
- [ ] Intégrer avec le système de Relations
- [ ] Créer l'interface de sélection de rôle
- [ ] Tester la formalisation des événements personnalisés

---

## PHASE 5 : Assistance LLM pour génération de données

### Objectif Phase 5

Permettre à l'utilisateur de connecter un LLM (local ou externe) via API pour générer automatiquement des données pertinentes à partir de textes libres ou d'informations partielles.

### Architecture proposée

```ocaml
type llm_config = {
  api_endpoint : string;
  api_key : string option;
  model : string;
  provider : llm_provider;
}

type llm_provider =
  | OpenAI
  | Anthropic
  | LocalOllama
  | Custom of string
```

### Cas d'usage

1. **Extraction d'informations depuis texte libre**
   - L'utilisateur colle un texte (acte, document, etc.)
   - Le LLM extrait : dates, lieux, personnes, événements
   - Propose un formulaire pré-rempli

2. **Complétion intelligente**
   - L'utilisateur saisit partiellement un champ
   - Le LLM suggère des complétions cohérentes avec le contexte

3. **Normalisation de données**
   - Le LLM suggère des normalisations (dates, lieux, noms)
   - Propose des corrections d'incohérences

4. **Génération de notes structurées**
   - À partir d'informations éparses, génère une note structurée

### UX proposée

**Interface discrète et optionnelle :**
- Bouton "Assistance IA" dans les formulaires
- Modal avec options :
  - Coller un texte à analyser
  - Demander des suggestions pour un champ
  - Normaliser les données saisies
- Prévisualisation avant application
- Validation manuelle obligatoire avant sauvegarde

### Sécurité et confidentialité

- **Local par défaut** : Encourager l'utilisation de LLM locaux (Ollama, etc.)
- **Configuration explicite** : L'utilisateur doit configurer l'API
- **Pas d'envoi automatique** : Toujours demander confirmation
- **Chiffrement optionnel** : Pour les données sensibles

### Fichiers à créer

- `lib/llm/llm_client.ml` : Client générique pour différentes APIs
- `lib/llm/extractors.ml` : Extracteurs d'informations depuis texte
- `lib/llm/normalizers.ml` : Normalisateurs de données
- `hd/etc/templm/llm_assistant.txt` : Interface web de l'assistant
- `bin/gwllm/gwllm.ml` : Configuration et test du LLM

### Checklist Phase 5

- [ ] Créer l'interface générique pour différents providers LLM
- [ ] Implémenter les extracteurs d'informations
- [ ] Créer l'interface web discrète
- [ ] Implémenter la prévisualisation et validation
- [ ] Documenter la configuration des APIs
- [ ] Tester avec différents providers (OpenAI, Ollama, etc.)
- [ ] Ajouter les garde-fous de sécurité

---

## Critères de succès

### Phase 1
- On peut ajouter plusieurs sources à un événement
- Les sources sont sauvegardées correctement
- Les sources s'affichent correctement en mode lecture
- L'ancien format `e_src` est migré automatiquement

### Phase 2
- Chaque source peut contenir des métadonnées détaillées (document + extrait)
- Les documents sources sont réutilisables
- Les métadonnées sont sauvegardées et affichées
- L'affichage est clair et structuré
- Mode simple et mode avancé fonctionnent

### Phase 3
- On peut saisir une adresse historique et une adresse actuelle
- Les coordonnées géographiques sont obtenues automatiquement
- L'affichage sur carte fonctionne
- La validation des coordonnées est opérationnelle

### Phase 4
- Les événements personnalisés peuvent être catégorisés
- Le système suggère des événements similaires
- Les témoins peuvent être des organisations
- Les rôles de témoins sont variés et personnalisables
- L'intégration avec Relations fonctionne

### Phase 5
- On peut connecter un LLM (local ou externe)
- L'extraction d'informations depuis texte fonctionne
- Les suggestions sont pertinentes
- La validation manuelle est obligatoire
- La configuration est sécurisée

