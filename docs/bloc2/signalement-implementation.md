# Implémentation — Signalement d'un livre

Voir `docs/bloc2/signalement-audit.md` pour l'audit qui a précédé ce
travail. **Périmètre : dépôt frontend uniquement** (voir la section
« Limites » ci-dessous pour ce qui reste côté backend).

## User story

> En tant qu'utilisateur authentifié, je veux signaler un livre dont
> le contenu me semble inapproprié, afin que les administrateurs
> puissent examiner le signalement et prendre une décision.

## Critères d'acceptation — état

| # | Critère | État |
|---|---|---|
| 1 | Action « Signaler ce livre » depuis la fiche livre | ✅ |
| 2 | Formulaire avec motif obligatoire, description conditionnelle, envoyer/annuler | ✅ |
| 3 | Envoi bloqué si données obligatoires absentes | ✅ |
| 4 | Confirmation avant/après envoi | ✅ (message de succès après envoi ; l'explication « Votre signalement sera examiné par un administrateur » sert de rappel avant envoi) |
| 5 | Statut initial `OPEN`, message de succès, fermeture, anti double-envoi | ✅ côté frontend (bouton désactivé pendant la requête) — le statut initial `OPEN` est déterminé par le backend, non par ce dépôt |
| 6 | Message d'erreur clair | ✅ |
| 7 | Non authentifié → connexion ou 401 | ✅ (redirection proactive vers `/login` + repli défensif sur un 401 renvoyé en cours de session) |
| 8 | Signalement visible côté admin | ✅ — réutilise `admin_reports_screen.dart`, préexistant et non modifié |
| 9 | Règles d'autorisation existantes conservées | ✅ — aucune route/règle existante modifiée |
| 10 | Web/mobile/desktop responsive | ✅ — testé à 390×844 et 1600×1000 (voir tests) |
| 11 | Accessibilité clavier + labels sémantiques | ✅ (voir section dédiée) |

## Architecture

Couche data (mêmes conventions que `reading/data/{models,services,repositories}/review_*.dart`) :

- `lib/features/reading/data/models/report_model.dart` — `ReportReason`
  (enum à 7 valeurs, `requiresDescription` pour `OTHER`),
  `ReportCreateRequest.toJson()`, `ReportModel.fromJson()` (tolérant
  aux variations de clés JSON, comme les autres modèles du projet).
- `lib/features/reading/data/services/report_api_service.dart` —
  `POST /books/{bookId}/reports` via Dio.
- `lib/features/reading/data/repositories/report_repository.dart` —
  providers Riverpod (`reportApiServiceProvider`,
  `reportRepositoryProvider`), passthrough simple (pas de repository
  intermédiaire avec logique — même choix que `ReviewRepository`).

Couche présentation :

- `lib/features/reading/presentation/report_book_dialog.dart` —
  `showReportBookDialog(context, bookId)` ouvre un
  `showModalBottomSheet` auto-porteur (état de soumission interne,
  comme `create_beta_comment_bottom_sheet.dart` — le modèle le plus
  proche déjà présent dans le projet). Sélecteur de motif en tuiles
  (icône + couleur + libellé, jamais couleur seule), champ description
  avec compteur de caractères natif (`maxLength: 1000`), bannière
  d'erreur inline.
- `lib/features/catalog/presentation/book_detail_screen.dart` —
  bouton discret « Signaler ce livre » (icône drapeau, texte
  secondaire, sous le bouton favoris dans `_ActionColumn`) ; vérifie la
  session avant d'ouvrir la feuille et affiche le `SnackBar` de succès.

Aucun état global superflu n'a été ajouté : le formulaire gère son
propre état de soumission/erreur en interne (comme le bottom sheet de
commentaire bêta-lecture), plutôt que de dupliquer les champs
`_xxxSubmitting`/`_xxxError` que `BookDetailScreen` maintient déjà pour
les avis/favoris.

## Endpoint

```
POST /api/v1/books/{bookId}/reports
```

Requête :
```json
{ "reason": "INAPPROPRIATE_CONTENT", "description": "Ce passage contient un contenu qui doit être examiné." }
```

Réponse attendue :
```json
{
  "id": "uuid",
  "bookId": "uuid",
  "reason": "INAPPROPRIATE_CONTENT",
  "description": "Ce passage contient un contenu qui doit être examiné.",
  "status": "OPEN",
  "createdAt": "2026-07-24T10:00:00Z"
}
```

Documenté dans `docs/api-contract.md` (nouvelle section « Reports »),
qui documente également — pour combler un angle mort préexistant — les
routes de modération déjà consommées par `admin_reports_screen.dart`
(`GET /admin/reports`, `PATCH /admin/reports/{id}/resolve|reject`,
`PATCH /reports/{id}/status`).

## Fichiers modifiés/créés (frontend uniquement)

**Créés** :
- `lib/features/reading/data/models/report_model.dart`
- `lib/features/reading/data/services/report_api_service.dart`
- `lib/features/reading/data/repositories/report_repository.dart`
- `lib/features/reading/presentation/report_book_dialog.dart`
- `test/report_repository_test.dart`
- `test/report_book_dialog_test.dart`
- `docs/bloc2/signalement-audit.md`
- `docs/bloc2/signalement-implementation.md` (ce fichier)
- `docs/bloc2/cahier-de-recette.md`

**Modifiés** :
- `lib/features/catalog/presentation/book_detail_screen.dart`
- `docs/api-contract.md`

Demandé dans la même session, hors périmètre signalement mais inclus
dans cette livraison :
- `lib/features/auth/presentation/widgets/auth_screen_shell.dart`,
  `lib/features/auth/presentation/login_screen.dart`,
  `lib/features/auth/presentation/register_screen.dart` — bouton
  afficher/masquer sur chaque champ mot de passe.
- `lib/features/profile/presentation/profile_screen.dart` — nouvel
  effet/couleur sur le bouton de déconnexion.
- `test/password_visibility_toggle_test.dart` — test dédié.

## Sécurité

- Aucune route existante modifiée ; aucune règle d'autorisation
  existante retirée.
- La création de signalement suit exactement le même schéma
  d'authentification que le reste de l'app : le token JWT est ajouté
  automatiquement par l'intercepteur Dio existant
  (`_JwtInterceptor`) — aucun code d'authentification n'a été
  dupliqué ou réimplémenté.
- Un visiteur non authentifié qui clique sur « Signaler ce livre » est
  redirigé vers `/login` **avant** tout appel réseau
  (`_openReportDialog` lit `authControllerProvider`). Si le token
  expire pendant la consultation de la page (session déjà ouverte), un
  401 renvoyé par le backend est intercepté et affiché comme « Votre
  session a expiré. Veuillez vous reconnecter. » plutôt que de planter
  silencieusement.
- Aucun secret, aucune donnée personnelle réelle n'a été ajouté au
  code ou aux tests (les emails/noms utilisés dans les tests sont
  fictifs : `ada@example.com`, etc., déjà le standard du dépôt).

## Accessibilité

- Bouton de fermeture (`X`) et boutons de motif : `Semantics(button:
  true, label: ...)` + `tooltip` explicite (« Fermer », libellé du
  motif) — jamais identifiés par la seule couleur (icône + texte +
  couleur sur chaque tuile de motif).
- Zones cliquables ≥ 44×44 px : boutons Annuler/Envoyer explicitement
  contraints à `minimumSize: Size(0, 44)`, tuiles de motif à
  `minHeight: 44`.
- Ordre de focus logique : ordre naturel du DOM/arbre de widgets
  (titre → fermer → motif → description → annuler/envoyer), aucun
  `FocusTraversalOrder` custom nécessaire.
- Fermeture au clavier (Web) : `CallbackShortcuts` sur
  `LogicalKeyboardKey.escape` ferme la feuille (désactivé pendant
  l'envoi, pour ne pas interrompre une requête en cours) — testé dans
  `report_book_dialog_test.dart`.
- Contraste : réutilise les couleurs sémantiques `PlumoraColors`
  (`destructive`, `onDestructive`, `textSecondary`) déjà validées pour
  le thème clair/sombre ailleurs dans l'app — aucune nouvelle couleur
  brute introduite.
- Le champ mot de passe afficher/masquer utilise `Semantics(button:
  true, label: 'Afficher/Masquer le mot de passe')` + `tooltip`
  identique, cohérent avec les autres icônes interactives du projet.

Guidelines `flutter_test` (`labeledTapTargetGuideline`,
`textContrastGuideline`, `androidTapTargetGuideline`) : **non
ajoutées** dans cette session — la suite existante (`test/`) n'en
utilise déjà aucune ailleurs dans le projet (aucun fichier de test
existant ne les référence), donc il n'y avait pas de convention à
suivre ; les ajouter aurait été un changement de portée plus large que
la fonctionnalité de signalement elle-même. Signalé ici comme point
d'amélioration possible plutôt que traité silencieusement.

## Tests ajoutés

- `test/report_repository_test.dart` (5 tests) — sérialisation JSON de
  `ReportCreateRequest`, requête HTTP réelle vers
  `POST /books/{bookId}/reports` (chemin, méthode, corps), propagation
  des erreurs 404/409 en `DioException`.
- `test/report_book_dialog_test.dart` (19 tests) — ouverture depuis la
  fiche livre, présence des 7 motifs, validation motif obligatoire,
  validation description obligatoire pour « Autre », désactivation du
  bouton + anti double-clic pendant l'envoi, appel API avec le bon
  `bookId`/JSON, fermeture après succès, fermeture par Échap,
  accessibilité du bouton de fermeture, messages d'erreur 401/403/404/
  409/réseau, rendu sans dépassement à 390×844 et 1600×1000.
- `test/password_visibility_toggle_test.dart` (2 tests) — bascule
  afficher/masquer sur le login, bascule indépendante entre mot de
  passe et confirmation sur l'inscription.

Total : 26 nouveaux tests, tous exécutés avec succès dans cette
session (voir sortie de `flutter test` dans le récapitulatif final).

## Limites restantes

1. **Le backend n'a pas été modifié ni vérifié.** L'entrée
   `POST /books/{bookId}/reports` documentée dans `docs/api-contract.md`
   est une **proposition** cohérente avec les conventions déjà en
   place (`POST /books/{bookId}/reviews`, etc.) et avec le schéma
   `reports` de `docs/data-model.md`, mais elle n'a jamais été
   confirmée contre le code source du backend réel (dépôt absent de
   cet environnement). À valider avec l'équipe backend avant mise en
   production.
2. **Règle de doublon (409) non confirmée.** Le message frontend existe
   et est testé, mais rien ne garantit que le backend renvoie
   effectivement un 409 dans ce cas — voir
   `docs/bloc2/signalement-audit.md`.
3. **Auto-signalement (un auteur signalant son propre livre)** : non
   bloqué côté frontend, faute de règle connue côté backend. À trancher
   séparément.
4. **`GET /admin/reports/{id}`** existe côté client
   (`AdminApiService.getReportDetail`) mais reste inutilisé par
   l'écran de modération — préexistant, non traité ici (hors
   périmètre signalement-création).
5. Pas de test automatisé pour la redirection `/login` d'un visiteur
   non authentifié cliquant sur « Signaler ce livre » (nécessiterait
   de monter `BookDetailScreen` sous un `GoRouter` complet) — à
   vérifier manuellement (voir cahier de recette).
6. Guidelines d'accessibilité `flutter_test` dédiées
   (`labeledTapTargetGuideline` etc.) non ajoutées — voir section
   Accessibilité ci-dessus.

## Procédure de recette manuelle

Voir `docs/bloc2/cahier-de-recette.md` (REC-034 et scénarios
complémentaires). Nécessite un backend réel exposant l'endpoint
proposé.

### Captures à réaliser manuellement

Aucune capture n'a été générée dans cette session (règle explicite :
ne pas fabriquer de fausses captures). À fournir manuellement, une
fois testé contre un backend réel :

1. Fiche du livre avec l'action « Signaler ce livre » visible.
2. Formulaire rempli (motif sélectionné + description).
3. Message de confirmation après envoi.
4. Signalement visible dans `/admin/reports`.
5. (Optionnel) Changement de statut par un administrateur
   (OPEN → IN_REVIEW → RESOLVED/DISMISSED).
