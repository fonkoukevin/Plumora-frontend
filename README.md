# Plumora — Application Frontend (Flutter)

Plumora est une plateforme d'écriture, de bêta-lecture, de publication et de
lecture de livres numériques. Ce dépôt contient **le frontend Flutter**
multiplateforme (Web, Android, iOS, Windows, macOS) qui consomme l'API REST
Spring Boot de Plumora (`/api/v1`, dépôt backend séparé).

Projet développé dans le cadre d'une certification RNCP niveau 7, avec pour
objectif de démontrer une architecture logicielle complète : API backend,
UX mobile/desktop, modélisation de données, intégration IA et déploiement
Docker.

## Sommaire

- [Aperçu du produit](#aperçu-du-produit)
- [Stack technique](#stack-technique)
- [Architecture du code](#architecture-du-code)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration (environnements)](#configuration-environnements)
- [Lancer l'application](#lancer-lapplication)
- [Qualité, tests et lint](#qualité-tests-et-lint)
- [Builds de production](#builds-de-production)
- [Déploiement Web (Docker)](#déploiement-web-docker)
- [Intégration continue (CI/CD)](#intégration-continue-cicd)
- [Backend et contrat d'API](#backend-et-contrat-dapi)
- [Structure du dépôt](#structure-du-dépôt)
- [Documentation complémentaire](#documentation-complémentaire)
- [Dépannage](#dépannage)

## Aperçu du produit

Plumora n'est pas qu'une app de lecture : elle réunit trois espaces autour
du même compte utilisateur, plus deux fonctionnalités IA ("Mukeme" / "Plumo
IA").

| Espace | Ce qu'on peut faire |
|---|---|
| **Auteur** | créer un livre, rédiger des chapitres, utiliser l'assistant d'écriture IA, envoyer un livre en bêta-lecture, recevoir les retours, publier directement (pas de validation admin en MVP) |
| **Lecteur** | découvrir le catalogue, obtenir des recommandations IA, lire, mettre en favoris, laisser des avis, signaler un livre |
| **Bêta-lecteur** | recevoir des invitations de bêta-lecture, lire les chapitres partagés en privé, laisser des commentaires structurés (type de retour, priorité, texte sélectionné) avant publication |
| **Admin** | gérer les utilisateurs, traiter les signalements, archiver un livre problématique |

Fonctionnalités IA (toujours via le backend, jamais d'appel direct à un
fournisseur IA depuis le frontend) :

- **Assistant d'écriture** : reformuler, améliorer le style, corriger les
  répétitions, rendre un texte plus émotionnel, réécrire un dialogue,
  résumer, continuer un texte, suggérer des titres, pré-analyser un
  manuscrit avant bêta-lecture.
- **Recommandation de lecture** : suggestions de livres du catalogue à
  partir d'une requête libre (humeur, durée, genre).

Hors périmètre MVP (volontairement non implémenté) : paiement, royalties
réelles, abonnement, validation de publication par un admin, chat,
marketplace.

## Stack technique

| Domaine | Choix |
|---|---|
| Framework | [Flutter](https://flutter.dev) (SDK Dart `^3.12.0`) |
| Gestion d'état | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| Navigation | [go_router](https://pub.dev/packages/go_router) — URLs "path" sur le web, garde de routes par rôle |
| Réseau HTTP | [Dio](https://pub.dev/packages/dio) + intercepteur JWT unique |
| Stockage sécurisé | `flutter_secure_storage` (Keychain / Keystore / DPAPI / WebCrypto selon la plateforme) |
| Authentification | email/mot de passe + Connexion Google (`google_sign_in_all_platforms`) |
| Éditeur de texte riche | `flutter_quill` (+ conversion Markdown via `markdown_quill` / `flutter_markdown_plus`) |
| Sélection de fichiers | `file_selector` (couverture de livre) |
| Polices | `google_fonts` |
| Qualité | `flutter_lints`, `dart format`, `flutter test` |

> Les packages `stacked`, `stacked_services` et `get_it` figurent dans
> `pubspec.yaml` mais ne sont plus utilisés dans le code applicatif actuel
> (l'app s'appuie entièrement sur Riverpod) — à retirer lors d'un futur
> ménage de dépendances.

## Architecture du code

Architecture **feature-first**, avec une séparation `data` / `presentation`
dans chaque feature :

```text
lib/
├── core/                  # transverse à toute l'app
│   ├── config/            # AppConfig (environnements, URLs) — jamais d'URL en dur ailleurs
│   ├── errors/             # AppError, mapping des erreurs HTTP/réseau
│   ├── network/           # DioClient, intercepteur JWT, config OAuth Google
│   ├── routing/           # go_router : app_router.dart, main_shell.dart, garde admin
│   ├── storage/           # SecureTokenStorage (JWT), préférences thème
│   ├── text/               # utilitaires texte
│   ├── theme/              # thème clair/sombre, contrôleur de thème
│   └── widgets/            # kit UI partagé (Figma design system, écrans d'erreur…)
│
├── features/
│   ├── auth/               # login, register, mot de passe oublié, sélection de rôle
│   ├── home/                # landing, tableau de bord global
│   ├── user/                # (réservé — actuellement vide)
│   ├── book/                # modèle livre partagé
│   ├── writing/             # espace auteur : dashboard, création, éditeur de chapitres, publication
│   ├── beta_reading/        # campagnes, invitations, commentaires de bêta-lecture
│   ├── reading/             # lecture, bibliothèque, favoris, avis, progression
│   ├── catalog/             # catalogue public, recherche, détail livre, livres du domaine public
│   ├── ai/                  # écrans Mukeme / Plumo IA (écriture, recommandations)
│   ├── notification/        # centre de notifications
│   ├── admin/                # back-office (utilisateurs, signalements, catalogue, IA)
│   └── profile/              # profil, préférences, édition du profil
│
└── main.dart               # bootstrap : ProviderScope, thème, routing, localisation
```

Chaque feature suit le même schéma interne : `data/` (modèles, services API,
repositories) et `presentation/` (écrans, widgets, controllers Riverpod).

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — le projet
  est développé et construit en CI avec le canal **stable** (image Docker
  figée sur Flutter `3.44.0`, voir `Dockerfile`).
- Dart est fourni avec Flutter (contrainte `sdk: ^3.12.0` dans
  `pubspec.yaml`).
- Un backend Plumora accessible (par défaut `http://localhost:8080/api/v1`
  en développement) — dépôt séparé, non inclus ici.
- Selon la cible de build : Chrome (Web), Android Studio/SDK (Android),
  Xcode (iOS/macOS, nécessite une machine macOS), Visual Studio avec le
  workload "Desktop development with C++" (Windows).

Vérifier l'installation :

```bash
flutter doctor
```

## Installation

```bash
git clone <url-du-dépôt>
cd plumora_app
flutter pub get
```

## Configuration (environnements)

Aucune URL n'est codée en dur dans le code : tout passe par
`lib/core/config/app_config.dart`, résolu à partir de variables
`--dart-define`.

| Variable | Rôle | Défaut dev | Défaut staging | Défaut production |
|---|---|---|---|---|
| `APP_ENV` | `development` \| `staging` \| `production` | `development` | — | — |
| `API_BASE_URL` | Origine + `/api/v1` de l'API backend | `http://localhost:8080/api/v1` | `https://staging-api.plumora-books.fr/api/v1` | `https://api.plumora-books.fr/api/v1` |
| `WEB_BASE_URL` | Origine publique de l'app web (liens profonds) | `http://localhost:5000` | `https://staging-app.plumora-books.fr` | `https://app.plumora-books.fr` |
| `GOOGLE_WEB_CLIENT_ID` | Client OAuth Google (web) — identifiant public, pas un secret | — | — | requis pour la connexion Google |
| `GOOGLE_DESKTOP_CLIENT_ID` / `GOOGLE_DESKTOP_CLIENT_SECRET` | Client OAuth pour le flux navigateur (Windows/Linux/macOS) | — | — | requis pour la connexion Google sur desktop |

`API_BASE_URL` et `WEB_BASE_URL` sont optionnels : s'ils sont omis,
`AppConfig` retombe sur la valeur par défaut de l'environnement choisi.

**Ne jamais** passer en `--dart-define` un secret backend (`GEMINI_API_KEY`,
`JWT_SECRET`, mot de passe base de données, etc.) : ce dépôt frontend n'en a
besoin d'aucun, ces valeurs appartiennent exclusivement au backend Spring
Boot.

Détails complets (garde-fous, pièges CSP/CORS, gestion du JWT) dans
[`docs/deployment-frontend.md`](docs/deployment-frontend.md).

## Lancer l'application

```bash
# Développement (backend local sur http://localhost:8080)
flutter run --dart-define=APP_ENV=development

# Contre le backend de staging
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.plumora-books.fr/api/v1 \
  --dart-define=WEB_BASE_URL=https://staging-app.plumora-books.fr

# Cibler explicitement une plateforme
flutter run -d chrome
flutter run -d windows
flutter devices   # lister les cibles disponibles
```

## Qualité, tests et lint

À exécuter avant toute pull request (identique au job `quality` de la CI) :

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Avec couverture (rapport dans `coverage/lcov.info`) :

```bash
flutter test --coverage
```

La suite de tests (`test/`) couvre notamment : le routing et la navigation
arrière, la config d'environnement (`app_config_test.dart`), le repository
d'authentification et Google Sign-In, l'éditeur de chapitre (autosave, mise
en page, Plumo), le catalogue/livres externes, les campagnes de
bêta-lecture, l'accessibilité et plusieurs écrans en layout desktop large.

## Builds de production

Toujours passer `APP_ENV=production` explicitement (et `API_BASE_URL` /
`WEB_BASE_URL` pour éviter toute ambiguïté) :

```bash
# Web — --no-web-resources-cdn embarque CanvasKit en local (requis par la CSP de prod)
flutter build web --release \
  --no-web-resources-cdn \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1 \
  --dart-define=WEB_BASE_URL=https://app.plumora-books.fr

# Android (App Bundle, Play Store)
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1

# iOS (nécessite macOS + Xcode)
flutter build ipa --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1

# Windows
flutter build windows --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1

# macOS (nécessite macOS + Xcode)
flutter build macos --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1
```

> ⚠️ `applicationId` (Android) et le Bundle Identifier (iOS) sont encore des
> placeholders `com.example.*` — à définir avant toute première publication
> sur un store (irréversible une fois publié). Détails dans
> [`docs/deployment-frontend.md`](docs/deployment-frontend.md).

## Déploiement Web (Docker)

Le `Dockerfile` à la racine construit une image multi-stage : build Flutter
Web puis service statique via Nginx non-root (port interne **8080**).

```bash
docker build \
  --build-arg API_BASE_URL=https://api.plumora-books.fr/api/v1 \
  --build-arg WEB_BASE_URL=https://app.plumora-books.fr \
  --build-arg APP_ENV=production \
  -t plumora-frontend-web .

docker run --rm -p 8080:8080 plumora-frontend-web
```

L'image ne fait pas de TLS (Caddy, côté backend, termine le HTTPS) et ne
contient aucun secret serveur. Le guide complet (fallback SPA, en-têtes de
sécurité/CSP, intégration Google Sign-In, healthcheck, rollback) est dans
[`docs/deployment-frontend.md`](docs/deployment-frontend.md).

## Intégration continue (CI/CD)

`.github/workflows/flutter-ci.yml` s'exécute sur chaque push/PR vers `main`
et `develop`, ainsi que sur les tags `v*` :

| Job | Rôle |
|---|---|
| `quality` | `dart format`, `flutter analyze`, `flutter test --coverage` |
| `build-web` | build de vérification Flutter Web (URL de validation non résolvable) |
| `build-android` | build APK debug |
| `build-linux-desktop` | build debug Linux |
| `docker-publish` | uniquement sur `push` vers `main` ou tag `v*` — build de l'image Docker, smoke test (healthcheck, routes SPA, garde-fous CSP/CanvasKit/Google), puis publication sur GitHub Container Registry (`ghcr.io/<owner>/plumora-frontend`) signée avec cosign |

Aucune image Docker n'est construite/publiée sur une pull request.

## Backend et contrat d'API

Le frontend consomme exclusivement l'API REST Spring Boot sous `/api/v1`
(dépôt backend séparé, non inclus ici). Le contrat détaillé (routes,
payloads, DTOs, enums, codes d'erreur) est documenté dans
[`docs/api-contract.md`](docs/api-contract.md) et doit rester synchronisé
entre les deux dépôts (voir [`docs/shared-decisions.md`](docs/shared-decisions.md)).

Principaux domaines exposés : authentification (email + Google), livres,
chapitres, catalogue, livres externes (import Gutendex/domaine public),
lecture et progression, favoris, avis, bêta-lecture (campagnes,
invitations, commentaires), IA (Mukeme + Plumo IA), signalements,
notifications.

## Structure du dépôt

```text
plumora_app/
├── lib/                # code source Flutter (voir Architecture du code)
├── test/               # tests unitaires et widgets
├── android/ ios/ windows/ macos/ linux/ web/   # projets natifs par plateforme
├── docs/               # documentation technique et produit
├── figma/               # export du design de référence (React/Vite, hors app Flutter)
├── docker/              # config Nginx + en-têtes de sécurité pour l'image web
├── Dockerfile           # build/serve de l'app Web
├── .github/workflows/   # CI GitHub Actions
├── pubspec.yaml          # dépendances et métadonnées du projet
└── AGENTS.md             # cadrage produit/architecture pour les agents IA
```

## Documentation complémentaire

- [`docs/project-context.md`](docs/project-context.md) — contexte produit et rôles utilisateurs
- [`docs/api-contract.md`](docs/api-contract.md) — contrat d'API détaillé
- [`docs/data-model.md`](docs/data-model.md) — modèle de données (référence backend)
- [`docs/deployment-frontend.md`](docs/deployment-frontend.md) — guide de déploiement complet (environnements, Docker, Android/iOS, JWT, CI/CD)
- [`docs/shared-decisions.md`](docs/shared-decisions.md) — décisions partagées entre frontend et backend
- [`CHANGELOG.md`](CHANGELOG.md) — historique des évolutions du frontend
- [`AGENTS.md`](AGENTS.md) — cadrage du projet à l'usage des agents IA contribuant au code
- [`figma/README.md`](figma/README.md) — export du design de référence Figma

## Dépannage

- **Le bouton "Connexion avec Google" échoue immédiatement** : vérifier que
  `GOOGLE_WEB_CLIENT_ID` (et, sur desktop, `GOOGLE_DESKTOP_CLIENT_ID`/
  `GOOGLE_DESKTOP_CLIENT_SECRET`) est bien passé en `--dart-define`.
- **`DioExceptionType.connectionError` ("Impossible de joindre le serveur
  Plumora")** : le backend n'est pas joignable, ou CORS n'autorise pas
  l'origine de l'app (à corriger côté backend).
- **Page blanche sur le build Web de production** : très probablement un
  blocage CSP lié à CanvasKit chargé depuis un CDN au lieu du bundle local —
  toujours builder avec `--no-web-resources-cdn` (voir section Docker).
- **404 au rafraîchissement d'une route profonde en Web** (`/books/12/read`,
  `/admin/users`…) : le serveur qui sert `build/web` doit rediriger toute
  route inconnue vers `index.html` (fallback SPA, déjà fait par
  `docker/nginx.conf`).
- **Build Windows échoue avec "Unable to find suitable Visual Studio
  toolchain"** : installer Visual Studio avec le workload "Desktop
  development with C++".
