# Audit — Signalement d'un livre (avant implémentation)

Périmètre de cette session : **dépôt frontend uniquement**
(`plumora_app`, Flutter/Riverpod/Dio/GoRouter). Le dépôt backend
(`Plumora-backend`, Spring Boot) n'est pas présent dans cet espace de
travail et n'a donc pas pu être audité directement — l'analyse
« backend » ci-dessous s'appuie uniquement sur les artefacts déjà
présents côté frontend : `docs/data-model.md`, `docs/api-contract.md`,
et le code qui consomme déjà des routes `/reports` et
`/admin/reports`. Aucun fichier backend n'a été modifié.

## Ce qui existe déjà côté backend (déduit des artefacts frontend)

`docs/data-model.md` documente une table `reports` :

```
### reports
- id_report UUID PK
- reporter_id UUID FK users(id_user)
- book_id UUID FK books(id_book)
- reason VARCHAR(100) NOT NULL
- description TEXT
- status VARCHAR(30) NOT NULL
- created_at TIMESTAMP NOT NULL
- resolved_at TIMESTAMP
```

Le côté **administration** est entièrement implémenté côté frontend et
consomme donc forcément des routes backend déjà existantes :

- `lib/features/admin/data/models/admin_report_model.dart` — enum
  `AdminReportStatus` : `OPEN`, `IN_REVIEW`, `RESOLVED`, `DISMISSED`
  (+ `UNKNOWN` côté client pour une valeur non reconnue).
- `lib/features/admin/data/services/admin_api_service.dart` appelle :
  - `GET /admin/reports` (liste)
  - `GET /admin/reports/{id}` (détail — méthode `getReportDetail`,
    définie mais actuellement inutilisée dans l'UI)
  - `PATCH /admin/reports/{id}/resolve` (`{ "reason"? }`)
  - `PATCH /admin/reports/{id}/reject` (`{ "reason"? }`)
  - `PATCH /reports/{id}/status` (`{ "status": "IN_REVIEW" }`) — route
    générique **hors** préfixe `/admin/**` mais documentée dans le
    code comme réservée ADMIN côté serveur.
- `lib/features/admin/presentation/admin_reports_screen.dart` —
  écran de modération complet (filtres par statut, actions
  passer-en-cours / résoudre / rejeter / archiver le livre associé).

**Conclusion : le module de signalement existe déjà côté backend et
côté administration frontend.** Aucun second module ne doit être créé.
Aucune de ces routes/statuts n'a été renommée dans ce travail.

## Ce qui manque (confirmé par recherche exhaustive)

Recherche `report|signal` (insensible à la casse) sur `lib/` : **aucune
route de création, aucun modèle, aucun écran/dialogue accessible à un
lecteur** n'existe. Le module de signalement est un module
**purement administrateur en lecture/traitement** — il n'y a jamais eu
de moyen, côté app, de créer un signalement. C'est exactement le trou
que l'audit produit RNCP avait relevé.

`docs/api-contract.md` ne contient aucune section « Reports » — les
routes ci-dessus sont utilisées par le code mais n'étaient pas
documentées. Ce travail ajoute cette documentation (contrat déclaré
côté frontend, à faire valider par l'équipe backend).

## Route de création retenue

`POST /api/v1/books/{bookId}/reports`, conformément à la consigne et
au préfixe `/api/v1` déjà utilisé par toutes les routes de
`docs/api-contract.md`. C'est la route la plus cohérente avec les
conventions déjà en place dans ce dépôt (`POST /books/{bookId}/reviews`,
`POST /books/{bookId}/favorites`, `POST /books/{bookId}/beta-campaigns`
suivent toutes le même gabarit `/books/{bookId}/<sous-ressource>`).

Cette route n'existe dans aucun test ni aucune doc frontend
préexistante — elle est donc **proposée** ici, pas confirmée contre le
code backend réel. Voir la section « Limites » de
`docs/bloc2/signalement-implementation.md`.

## Motifs (`reason`)

Aucun enum de motifs n'est référencé nulle part côté frontend (le seul
champ `reason` existant, sur `AdminReport`, est une simple `String`
libre lue depuis le JSON). Conformément à la consigne, la liste
proposée dans le brief est reprise telle quelle :

`INAPPROPRIATE_CONTENT`, `HARASSMENT`, `HATE_SPEECH`, `PLAGIARISM`,
`COPYRIGHT`, `MISLEADING_INFORMATION`, `OTHER`.

La colonne `reason` étant un `VARCHAR(100) NOT NULL` sans contrainte
`CHECK` documentée dans `docs/data-model.md`, ces valeurs sont
envoyées comme chaînes libres — compatibles telles quelles même si le
backend n'a *pas* d'enum strict. À confirmer avec l'équipe backend.

## Règle métier — doublons et auto-signalement

Aucune règle de doublon ni d'auto-signalement n'est documentée ou
déductible du code frontend existant (l'admin ne fait que lister et
traiter, jamais créer). **Aucune règle n'est donc inventée côté
backend** (hors périmètre de ce dépôt de toute façon). Côté frontend,
le mapping d'erreur `409 → "Vous avez déjà signalé ce livre."` est
ajouté *au cas où* le backend applique la règle raisonnable suggérée
par le brief (un seul signalement `OPEN` par lecteur et par livre) —
si le backend ne renvoie jamais 409 sur cette route, ce message ne
sera simplement jamais déclenché ; s'il renvoie 409 pour une autre
raison, le message reste plausible. Rien n'empêche l'auteur de
signaler son propre livre côté frontend (aucune règle de ce type n'a
été trouvée ; à trancher côté backend).

## Fichiers frontend audités

| Fichier | Rôle |
|---|---|
| `lib/features/catalog/presentation/book_detail_screen.dart` | Écran détail livre (lecteur) — pas de menu `...`, deux zones d'action (`_ActionColumn` avec Lire/Favoris, `_ReviewsCard` avec Donner mon avis) |
| `lib/features/reading/presentation/review_dialog.dart` | Dialogue simple (`AlertDialog`) : modèle de référence léger |
| `lib/features/beta_reading/presentation/create_beta_comment_bottom_sheet.dart` | Bottom sheet auto-porteur (état de soumission interne, sélecteur d'enum en tuiles) : **modèle retenu** pour le dialogue de signalement |
| `lib/features/reading/data/{models,services,repositories}/review_*.dart` | Gabarit exact de la couche data (modèle + `ApiService` Dio + `Repository` Riverpod) reproduit pour `report_*.dart` |
| `lib/features/admin/data/models/admin_report_model.dart` | Enum de statuts déjà existant, réutilisé tel quel (aucun renommage) |
| `lib/features/profile/presentation/profile_screen.dart` (lignes ~200-214) | Bouton déconnexion actuel — `OutlinedButton.icon` bordure/texte `context.colors.destructive`, aucun effet différencié au clic |
| `lib/features/auth/presentation/widgets/auth_screen_shell.dart` (`PlumoraTextField`), `lib/features/auth/presentation/login_screen.dart` (`_LoginTextField`), `lib/features/auth/presentation/register_screen.dart` (`_RegisterTextField`) | Trois implémentations distinctes de champ mot de passe, aucune n'a de bouton afficher/masquer |
| `lib/core/errors/app_error.dart` | Mapping générique d'erreurs HTTP réutilisé, complété localement dans le dialogue de signalement avec les messages spécifiques demandés (401/403/404/409 propres au contexte signalement) |

## Fichiers à créer/modifier (plan)

**Créés** :
- `lib/features/reading/data/models/report_model.dart`
- `lib/features/reading/data/services/report_api_service.dart`
- `lib/features/reading/data/repositories/report_repository.dart`
- `lib/features/reading/presentation/report_book_dialog.dart`
- `test/report_book_dialog_test.dart`, `test/report_repository_test.dart`
- `docs/bloc2/signalement-audit.md` (ce fichier)
- `docs/bloc2/signalement-implementation.md`
- `docs/bloc2/cahier-de-recette.md`

**Modifiés** :
- `lib/features/catalog/presentation/book_detail_screen.dart` (action « Signaler ce livre »)
- `docs/api-contract.md` (section Reports)
- `lib/features/auth/presentation/widgets/auth_screen_shell.dart`,
  `login_screen.dart`, `register_screen.dart` (toggle mot de passe —
  hors périmètre signalement, demandé dans la même session)
- `lib/features/profile/presentation/profile_screen.dart` (bouton
  déconnexion — idem)
