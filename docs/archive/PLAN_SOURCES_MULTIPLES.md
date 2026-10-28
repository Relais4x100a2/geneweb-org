# Plan : Transformation du champ Source en système multi-sources

## Objectif

Transformer le champ `epers_src : 'string` (une seule source) en un système multi-sources similaire aux témoins, permettant d'ajouter plusieurs sources à chaque événement.

**Ensuite** : Permettre d'ajouter des métadonnées détaillées à chaque source (auteur, date, URL, etc.).

---

## PHASE 1 : Système multi-sources simple (chaînes de caractères)

### 🎯 Objectif Phase 1

Transformer `epers_src : 'string` en `epers_sources : 'string list` (ou `'string array`), permettant d'ajouter plusieurs sources sous forme de chaînes.

### 📋 Checklist Phase 1

#### 1. **Modification du type de base**

**Fichier** : `lib/def/def.ml`
- [ ] Ligne ~181 : Remplacer `epers_src : 'string;` par `epers_sources : 'string list;`
- [ ] **Rétrocompatibilité** : On pourrait garder temporairement `epers_src` comme champ optionnel pour la migration, mais il est plus propre de faire la coupure maintenant
- [ ] Mettre à jour `lib/show/def_show.mli` si nécessaire

**⚠️ Note importante** : Cela cassera la compatibilité avec les anciennes bases. Il faudra soit :
- Accepter de convertir les anciennes bases (script de migration)
- OU utiliser un champ optionnel temporaire pour la transition

**Recommandation** : Utiliser `epers_sources : 'string list` et écrire une fonction de migration qui convertit `epers_src` en liste.

#### 2. **Recherche systématique de tous les usages**

```bash
# Trouver tous les endroits qui utilisent epers_src
grep -r "epers_src\|\.epers_src\|e_src\|event\.src\|\.src" lib/ --include="*.ml" -n

# Trouver dans les templates
grep -r "e_src\|event\.src\|\.src" hd/etc/ --include="*.txt" -n

# Trouver dans les plugins
grep -r "epers_src\|e_src" plugins/ --include="*.ml" -n
```

**Fichiers à vérifier systématiquement** :
- [ ] `lib/util/futil.ml` : Fonctions `map_pers_event`
- [ ] `lib/hasher.ml` : Hachage des événements
- [ ] `lib/updateIndOk.ml` : Reconstruction depuis formulaire
- [ ] `lib/updateInd.ml` : Affichage dans formulaire
- [ ] `lib/perso.ml` : Évaluations pour templates
- [ ] `lib/event.ml` : Gestion des événements
- [ ] `lib/db/driver.ml` : Accès base de données
- [ ] `lib/db/` : Sérialisation/désérialisation
- [ ] `plugins/gwxjg/` : Plugin JSON
- [ ] Tous les templates d'affichage

#### 3. **Mise à jour des constructeurs**

**Fichiers principaux** :
- [ ] `lib/util/futil.ml` : `map_pers_event` - remplacer `epers_src` par `epers_sources`
- [ ] `lib/updateIndOk.ml` : Création d'événements - remplacer par liste
- [ ] `lib/updateFamOk.ml` : Si applicable pour événements familiaux
- [ ] `lib/fixbase.ml` : `mk_pevent` - initialiser avec `[]`
- [ ] `bin/gwc/db1link.ml` : Constructeurs lors de l'import
- [ ] `bin/ged2gwb/ged2gwb.ml` : Import GEDCOM
- [ ] Tous les autres endroits trouvés par grep

**Exemple de conversion** :
```ocaml
(* AVANT *)
epers_src = "";

(* APRÈS *)
epers_sources = [];
```

#### 4. **Mise à jour des pattern-matchings**

**Fichiers principaux** :
- [ ] `lib/util/futil.ml` : Pattern matching dans `map_pers_event`
- [ ] `lib/hasher.ml` : Hachage du champ
- [ ] Tous les endroits qui pattern-match sur `gen_pers_event`

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

#### 5. **Mise à jour du traitement des formulaires**

**Fichier** : `lib/updateIndOk.ml`

**Avant** (lignes ~199-203) :
```ocaml
let epers_src =
  match get_nth conf "e_src" cnt with
  | Some src -> only_printable src
  | None -> ""
```

**Après** : Créer une fonction similaire à `reconstitute_pevents` pour les sources
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

#### 6. **Mise à jour des templates d'édition**

**Fichier** : `hd/etc/updind.txt`

**Avant** (lignes ~495-503) :
```html
<div class="row mt-0">
  <label for="e_srcxcnt" class="col-2 col-form-label">[*source/sources]0</label>
  <div class="col-10">
    <input class="form-control" name="e_srcxcnt" id="e_srcxcnt" placeholder="[*source/sources]0" value="%event.e_src;">
  </div>
</div>
```

**Après** : Créer une macro `one_source` similaire à `one_witness`

```html
%define;one_source(xcnt, scnt)
  <div class="row mt-2">
    <label for="excnt_srcscnt" class="col-2 col-form-label">[*source/sources]0 scnt</label>
    <div class="col-10">
      <input class="form-control" name="excnt_srcscnt" id="excnt_srcscnt" placeholder="[*source/sources]0" value="%source;">
      <button type="button" class="btn btn-sm btn-danger mt-1" onclick="removeSource(xcnt, scnt)">Supprimer</button>
    </div>
  </div>
%end;

%define;insert_source(xcnt, scnt)
  <div class="row mt-3 mb-1">
    <label for="excnt_ins_srcscnt_n" class="col-form-label col-2">[*insert]</label>
    <div class="form-inline col-10">
      <div class="input-group">
        <select class="form-control" id="excnt_ins_srcscnt_n" name="excnt_ins_srcscnt_n">
          %for;i;1;11;<option>%i;</option>%end;
        </select>
        <div class="input-group-append">
          <label class="btn btn-outline-primary">[*source/sources]0
            <input class="ml-1" type="checkbox" name="excnt_ins_srcscnt" value="on">
          </label>
          <button type="submit" class="btn btn-outline-primary">OK</button>
        </div>
      </div>
    </div>
  </div>
%end;

(* Dans one_pevent et one_specific_pevent *)
%if;has_sources;
  %foreach;source;
    %apply;one_source(xcnt, scnt)
    %if;is_last;%apply;insert_source(xcnt, scnt)%end;
  %end;
%else;
  %apply;insert_source(xcnt, "0")
%end;
```

**Fichier JavaScript** : `hd/etc/templm/js_upd.js`
- [ ] Ajouter une fonction `addSource(xcnt, scnt)` similaire à `addWitness`
- [ ] Ajouter une fonction `removeSource(xcnt, scnt)` pour supprimer une source

#### 7. **Mise à jour de l'affichage dans les templates**

**Fichier** : `lib/updateInd.ml`
- [ ] Créer une variable `sources` pour chaque événement (liste)
- [ ] Ajouter `has_sources : bool` pour vérifier si la liste n'est pas vide
- [ ] Exposer chaque source individuellement via `foreach;source;`

**Fichier** : `lib/perso.ml`
- [ ] Mettre à jour `eval_str_event_field` pour gérer `sources` (liste)
- [ ] Ajouter `has_sources` dans `eval_bool_event_field`
- [ ] Mettre à jour `eval_event_field_var` pour exposer les sources

**Templates d'affichage** :
- [ ] `hd/etc/templm/perso.txt` : Afficher toutes les sources
- [ ] `hd/etc/modules/chronologie.txt` : Afficher les sources dans la timeline
- [ ] `hd/etc/perso_short.txt` : Affichage court
- [ ] `hd/etc/deslist.txt` : Liste de descendants
- [ ] `hd/etc/perso_utils.txt` : Tooltips

**Exemple dans perso.txt** :
```html
%if;event.has_sources;
  <div style="margin-left:30px">
    <strong>[*source/sources]1[:]</strong>
    <ul>
      %foreach;source;
        <li>%source;</li>
      %end;
    </ul>
  </div>
%end;
```

#### 8. **Mise à jour des fonctions de hachage**

**Fichier** : `lib/hasher.ml`
- [ ] Remplacer `feed_string epers_src` par `(list feed_string) epers_sources`

#### 9. **Mise à jour du tuple event_item**

**Fichier** : `lib/event.ml`
- [ ] Remplacer `Driver.istr` (source unique) par `Driver.istr list` (liste de sources)
- [ ] Mettre à jour tous les endroits qui créent ou pattern-match sur `event_item`

**⚠️ ATTENTION** : Cela change la structure du tuple, tous les endroits doivent être mis à jour !

#### 10. **Mise à jour des plugins**

**Fichier** : `plugins/gwxjg/gwxjg_data.ml`
- [ ] Mettre à jour `mk_pevent` pour gérer la liste de sources
- [ ] Mettre à jour `mk_event` pour exposer les sources

**Fichier** : `plugins/gwxjg/gwxjg_ezgw.ml`
- [ ] Mettre à jour `Event.src` pour retourner une liste

#### 11. **Migration des anciennes données**

**Option A : Script de migration**
- [ ] Créer une fonction qui lit `epers_src` et le convertit en `[epers_src]` si non vide
- [ ] Exécuter lors du chargement de l'ancienne base

**Option B : Compatibilité temporaire**
- [ ] Garder `epers_src` comme champ optionnel
- [ ] Migrer vers `epers_sources` progressivement

---

## PHASE 2 : Ajout de métadonnées aux sources

### 🎯 Objectif Phase 2

Transformer `epers_sources : 'string list` en `epers_sources : source_info list` où chaque source peut contenir des métadonnées détaillées.

### Structure proposée

```ocaml
type 'string source_info = {
  src_text : 'string;              (* Le texte de la source *)
  src_author : 'string option;     (* Auteur de la source *)
  src_date : 'string option;       (* Date de publication *)
  src_place : 'string option;      (* Lieu de publication *)
  src_url : 'string option;        (* URL si source en ligne *)
  src_page : 'string option;       (* Numéro de page *)
  src_repository : 'string option; (* Dépôt/archive où se trouve la source *)
  src_note : 'string option;       (* Note supplémentaire *)
}
```

### 📋 Checklist Phase 2

#### 1. **Modification du type**

**Fichier** : `lib/def/def.ml`
- [ ] Définir le type `source_info`
- [ ] Modifier `epers_sources : 'string list` en `epers_sources : ('string source_info) list`

#### 2. **Migration depuis Phase 1**

- [ ] Créer une fonction de migration qui convertit les chaînes en `source_info` :
```ocaml
let string_to_source_info s = {
  src_text = s;
  src_author = None;
  src_date = None;
  src_place = None;
  src_url = None;
  src_page = None;
  src_repository = None;
  src_note = None;
}
```

#### 3. **Mise à jour des templates d'édition**

**Fichier** : `hd/etc/updind.txt`
- [ ] Modifier `one_source` pour inclure tous les champs :
```html
%define;one_source(xcnt, scnt)
  <hr>
  <div class="form-group mt-2">
    <div class="row">
      <h5 class="col-form-label col-2">[*source/sources]0 scnt</h5>
    </div>
    <div class="row">
      <label for="excnt_srcscnt_text" class="col-2 col-form-label">[*source/sources]0</label>
      <div class="col-10">
        <input class="form-control" name="excnt_srcscnt_text" id="excnt_srcscnt_text" 
               placeholder="[*source/sources]0" value="%source.text;">
      </div>
    </div>
    <div class="row mt-1">
      <label for="excnt_srcscnt_author" class="col-2 col-form-label">Auteur</label>
      <div class="col-10">
        <input class="form-control" name="excnt_srcscnt_author" id="excnt_srcscnt_author" 
               placeholder="Auteur" value="%source.author;">
      </div>
    </div>
    <div class="row mt-1">
      <label for="excnt_srcscnt_date" class="col-2 col-form-label">Date</label>
      <div class="col-4">
        <input class="form-control" name="excnt_srcscnt_date" id="excnt_srcscnt_date" 
               placeholder="Date" value="%source.date;">
      </div>
      <label for="excnt_srcscnt_place" class="col-2 col-form-label">Lieu</label>
      <div class="col-4">
        <input class="form-control" name="excnt_srcscnt_place" id="excnt_srcscnt_place" 
               placeholder="Lieu" value="%source.place;">
      </div>
    </div>
    <div class="row mt-1">
      <label for="excnt_srcscnt_url" class="col-2 col-form-label">URL</label>
      <div class="col-10">
        <input class="form-control" name="excnt_srcscnt_url" id="excnt_srcscnt_url" 
               placeholder="https://..." value="%source.url;">
      </div>
    </div>
    <div class="row mt-1">
      <label for="excnt_srcscnt_page" class="col-2 col-form-label">Page</label>
      <div class="col-4">
        <input class="form-control" name="excnt_srcscnt_page" id="excnt_srcscnt_page" 
               placeholder="Page" value="%source.page;">
      </div>
      <label for="excnt_srcscnt_repository" class="col-2 col-form-label">Dépôt</label>
      <div class="col-4">
        <input class="form-control" name="excnt_srcscnt_repository" id="excnt_srcscnt_repository" 
               placeholder="Archive" value="%source.repository;">
      </div>
    </div>
    <div class="row mt-1">
      <label for="excnt_srcscnt_note" class="col-2 col-form-label">Note</label>
      <div class="col-10">
        <textarea class="form-control" name="excnt_srcscnt_note" id="excnt_srcscnt_note" 
                  rows="2" placeholder="Note">%source.note;</textarea>
      </div>
    </div>
  </div>
%end;
```

#### 4. **Mise à jour du traitement des formulaires**

**Fichier** : `lib/updateIndOk.ml`
- [ ] Modifier `reconstitute_sources` pour lire tous les champs :
```ocaml
let reconstitute_source conf cnt scnt =
  let key = "e" ^ string_of_int cnt ^ "_src" ^ string_of_int scnt in
  let text = match get_nth conf (key ^ "_text") scnt with
    | Some t when t <> "" -> only_printable t
    | _ -> match get_nth conf key scnt with
      | Some t when t <> "" -> only_printable t  (* Rétrocompatibilité *)
      | _ -> ""
  in
  if text = "" then None
  else Some {
    src_text = text;
    src_author = opt_map only_printable (get_nth conf (key ^ "_author") scnt);
    src_date = opt_map only_printable (get_nth conf (key ^ "_date") scnt);
    src_place = opt_map only_printable (get_nth conf (key ^ "_place") scnt);
    src_url = opt_map only_printable (get_nth conf (key ^ "_url") scnt);
    src_page = opt_map only_printable (get_nth conf (key ^ "_page") scnt);
    src_repository = opt_map only_printable (get_nth conf (key ^ "_repository") scnt);
    src_note = opt_map only_printable_or_nl (get_nth conf (key ^ "_note") scnt);
  }

let reconstitute_sources conf cnt =
  let rec loop i =
    match reconstitute_source conf cnt i with
    | Some src -> src :: loop (i + 1)
    | None -> []
  in
  loop 0
```

#### 5. **Mise à jour de l'affichage**

**Fichier** : `lib/perso.ml`
- [ ] Mettre à jour les évaluations pour exposer les champs de `source_info`
- [ ] Créer des variables : `source.text`, `source.author`, `source.date`, etc.

**Templates** :
- [ ] Afficher les métadonnées de manière structurée
- [ ] Option pour affichage simple (juste le texte) ou détaillé (toutes les métadonnées)

---

## 🚀 Ordre de mise en œuvre recommandé

### Phase 1 (Priorité haute)
1. ✅ Commencer par Phase 1 (système multi-sources simple)
2. ✅ Tester et valider le système multi-sources
3. ✅ S'assurer que tout fonctionne correctement

### Phase 2 (Après validation Phase 1)
1. ✅ Ensuite seulement, ajouter les métadonnées (Phase 2)
2. ✅ Migration progressive des données

---

## 📝 Notes importantes

1. **Rétrocompatibilité** : Penser à gérer l'ancien format `e_src` dans `reconstitute_sources`
2. **Performance** : Les listes sont OK, mais si on a beaucoup de sources, considérer `array`
3. **Affichage** : Prévoir un mode d'affichage compact et un mode détaillé
4. **Validation** : Vérifier que les URLs sont valides (optionnel mais recommandé)

## 🔍 Fichiers à modifier (liste non exhaustive)

### Phase 1
- `lib/def/def.ml`
- `lib/util/futil.ml`
- `lib/hasher.ml`
- `lib/updateIndOk.ml`
- `lib/updateInd.ml`
- `lib/perso.ml`
- `lib/event.ml`
- `lib/db/driver.ml`
- `hd/etc/updind.txt`
- `hd/etc/templm/perso.txt`
- `hd/etc/modules/chronologie.txt`
- `plugins/gwxjg/`

### Phase 2
- Tous les fichiers de Phase 1 +
- Templates d'édition plus détaillés
- Fonctions de migration

---

## ✅ Critères de succès

### Phase 1
- [ ] On peut ajouter plusieurs sources à un événement
- [ ] Les sources sont sauvegardées correctement
- [ ] Les sources s'affichent correctement en mode lecture
- [ ] L'ancien format `e_src` est migré automatiquement

### Phase 2
- [ ] Chaque source peut contenir des métadonnées détaillées
- [ ] Les métadonnées sont sauvegardées et affichées
- [ ] L'affichage est clair et structuré

