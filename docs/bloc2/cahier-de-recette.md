# Cahier de recette — Signalement d'un livre

Convention de statut, appliquée strictement :

- **Automatisé (passé)** : couvert par un test automatisé du dépôt
  frontend qui a été exécuté avec succès dans cette session
  (`flutter test`). Ne dit rien sur le backend réel.
- **Prêt pour recette manuelle** : implémenté et compilé sans erreur,
  mais jamais exécuté contre le backend réel (aucun accès à un backend
  vivant dans cet environnement) — à exécuter manuellement avant de
  marquer « Réussi ».
- **Réussi** : exécuté manuellement de bout en bout contre le backend
  réel, avec capture d'écran à l'appui. Aucun scénario de ce document
  n'a ce statut à l'issue de cette session — voir
  `docs/bloc2/signalement-implementation.md` pour les captures encore
  à fournir.

## REC-034 — Création d'un signalement

**Statut : Prêt pour recette manuelle** (précédemment bloqué — aucune
interface n'existait côté frontend).

Préconditions :
- Utilisateur connecté.
- Livre disponible (visible dans le catalogue).

Étapes :
1. Ouvrir la fiche du livre (`/catalog/books/{id}`).
2. Cliquer sur « Signaler ce livre » (sous le bouton favoris).
3. Choisir un motif (tuile parmi les 7 proposées).
4. Saisir une description (obligatoire si le motif est « Autre »,
   facultative sinon).
5. Cliquer sur « Envoyer le signalement ».

Résultat attendu :
- Confirmation affichée (`SnackBar` : « Votre signalement a bien été
  transmis. Il sera examiné par un administrateur. »).
- Signalement créé avec le statut `OPEN`.
- Signalement visible dans `/admin/reports`.

Couverture automatisée : `test/report_book_dialog_test.dart` (ouverture
depuis la fiche livre, sélection du motif, appel API avec le bon
`bookId`/JSON, fermeture de la feuille après succès) et
`test/report_repository_test.dart` (requête HTTP réelle vers
`POST /books/{bookId}/reports`). Non couvert par l'automatisation : la
présence effective du signalement dans `/admin/reports` après un appel
réseau réel (nécessite le backend).

## Scénarios complémentaires

### Formulaire sans motif
**Statut : Automatisé (passé).**
Cliquer sur « Envoyer le signalement » sans sélectionner de motif →
message « Choisis un motif de signalement. », aucun appel réseau.
Couvert par `report_book_dialog_test.dart` (`submitting without a
reason shows a validation error`).

### Description trop longue / motif « Autre » sans description
**Statut : Automatisé (passé).**
Le champ description est limité à 1000 caractères (compteur natif
Flutter). Le motif « Autre » sans description suffisante (< 10
caractères) affiche « Précise ce motif (10 caractères minimum). » et
bloque l'envoi. Couvert par `report_book_dialog_test.dart` (`reason
OTHER requires a description of at least 10 characters`).

### Utilisateur non connecté
**Statut : Prêt pour recette manuelle.**
Un visiteur non authentifié qui ouvre une fiche livre (route publique)
et clique sur « Signaler ce livre » est redirigé vers `/login` avant
même l'ouverture du formulaire (`_openReportDialog` vérifie
`authControllerProvider` en amont). Non couvert par un test automatisé
dédié dans cette session (nécessiterait un routeur complet monté sur
`BookDetailScreen`, hors périmètre du temps disponible) — **à vérifier
manuellement**. Le repli défensif (401 renvoyé par le backend en cours
de session, ex. token expiré pendant la consultation de la page) est
lui automatisé : voir ligne « 401 » ci-dessous.

### Doublon éventuel (409)
**Statut : Prêt pour recette manuelle — règle non confirmée côté
backend** (voir `docs/bloc2/signalement-audit.md`, section « Règle
métier »). Le mapping d'erreur frontend est automatisé
(`report_book_dialog_test.dart`, « a 409 error shows... ») mais ne
peut être déclenché en conditions réelles que si le backend applique
effectivement cette règle.

### Erreurs réseau et serveur
**Statut : Automatisé (passé)** pour le mapping de message (401, 403,
404, 409, erreur réseau) — voir la boucle de tests paramétrés dans
`report_book_dialog_test.dart`. L'erreur serveur générique (500) tombe
dans le même mapping par défaut (« Une erreur est survenue. Réessayez
plus tard. ») mais n'a pas de cas de test dédié séparé du réseau.

### Modération par un administrateur
**Statut : Hors périmètre de cette session** (fonctionnalité
préexistante, non modifiée). L'écran `/admin/reports`
(`admin_reports_screen.dart`) existait déjà avant ce travail et n'a pas
été touché.

### Passage OPEN → IN_REVIEW
**Statut : Hors périmètre de cette session** — préexistant
(`AdminRepository.markReportInReview`, bouton « Passer en cours »).

### Passage IN_REVIEW → RESOLVED ou DISMISSED
**Statut : Hors périmètre de cette session** — préexistant
(`AdminRepository.resolveReport` / `rejectReport`, boutons « Résoudre »
/ « Rejeter »).

## Ce qui reste à faire avant de marquer REC-034 « Réussi »

1. Un backend réel exposant `POST /books/{bookId}/reports` conforme au
   contrat proposé dans `docs/api-contract.md` (à confirmer/adapter
   avec l'équipe backend — voir les limites documentées dans
   `docs/bloc2/signalement-implementation.md`).
2. Exécution manuelle du scénario REC-034 contre ce backend, captures
   d'écran à l'appui (liste dans
   `docs/bloc2/signalement-implementation.md`).
3. Vérification manuelle du scénario « utilisateur non connecté »
   (redirection effective vers `/login`).
