# Déploiement frontend — Plumora

Ce document décrit comment configurer, construire et héberger le frontend
Flutter de Plumora pour ses 5 cibles : **Web, Android, iOS, Windows, macOS**,
face au même backend Spring Boot (hébergé séparément, hors de ce dépôt) :
`https://api.plumora-books.fr/api/v1`.

## 1. Environnements

Trois environnements sont supportés, résolus par `lib/core/config/app_config.dart`
à partir de `--dart-define` (aucune URL n'est jamais codée en dur dans un écran,
un ViewModel, un repository ou un service — `AppConfig` est la seule source de
vérité) :

| Variable | Rôle | Défaut dev | Défaut staging | Défaut production |
|---|---|---|---|---|
| `APP_ENV` | Sélectionne l'environnement (`development` \| `staging` \| `production`) | `development` | — | — |
| `API_BASE_URL` | Origine + `/api/v1` de l'API. Écrase toujours la valeur par défaut de `APP_ENV`. | `http://localhost:8080/api/v1` | `https://staging-api.plumora-books.fr/api/v1` | `https://api.plumora-books.fr/api/v1` |
| `WEB_BASE_URL` | Origine publique de l'app web (liens profonds, ex. carte « Continuer sur le web »). | `http://localhost:5000` | `https://staging-app.plumora-books.fr` | `https://app.plumora-books.fr` |

`API_BASE_URL` et `WEB_BASE_URL` sont optionnels : s'ils sont omis, `AppConfig`
retombe sur la valeur par défaut de l'environnement choisi via `APP_ENV`. Ne
jamais définir `API_BASE_URL` sur une adresse locale/privée en même temps que
`APP_ENV=production` : un `assert` dans `AppConfig.apiBaseUrl` lève une erreur
en debug/profile si c'est le cas, et `test/app_config_test.dart` verrouille ce
comportement.

**Ne jamais passer en `--dart-define`, en argument de build Docker, ni
committer ailleurs :** `GEMINI_API_KEY`, `JWT_SECRET` serveur, mot de passe
PostgreSQL, clé d'un fournisseur IA, ou tout autre secret backend. Ces valeurs
n'appartiennent qu'au backend Spring Boot — ce dépôt frontend n'en a besoin
d'aucune, et ce document ne fait référence qu'à des valeurs publiques
(origines HTTPS).

D'autres `--dart-define` existent déjà pour la connexion Google
(`GOOGLE_WEB_CLIENT_ID`, `GOOGLE_DESKTOP_CLIENT_ID`,
`GOOGLE_DESKTOP_CLIENT_SECRET` — voir `lib/core/network/google_auth_config.dart`
et `docs/api-contract.md`) ; ce sont des identifiants client OAuth publics par
plateforme, pas des secrets serveur.

### Lancer en développement

```bash
flutter run --dart-define=APP_ENV=development
# API_BASE_URL par défaut : http://localhost:8080/api/v1
```

### Lancer contre staging

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.plumora-books.fr/api/v1 \
  --dart-define=WEB_BASE_URL=https://staging-app.plumora-books.fr
```

## 2. Builds de production

Toujours passer `APP_ENV=production` (et explicitement `API_BASE_URL` /
`WEB_BASE_URL` pour éviter toute ambiguïté) :

```bash
# Flutter Web — --no-web-resources-cdn bundles CanvasKit under /canvaskit/
# (same origin) instead of fetching it from Google's CDN at runtime, which
# our CSP's script-src (docker/security-headers.conf) does not allow — see
# section 5.
flutter build web --release \
  --no-web-resources-cdn \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1 \
  --dart-define=WEB_BASE_URL=https://app.plumora-books.fr

# Android (App Bundle, Play Store)
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1

# iOS (IPA — nécessite macOS + Xcode)
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

### Qualité avant tout build de production

```bash
dart format .
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.plumora-books.fr/api/v1 \
  --dart-define=WEB_BASE_URL=https://app.plumora-books.fr
```

## 3. Flutter Web

- **Routing** : `usePathUrlStrategy()` est appelé dans `main.dart`, donc les
  URLs sont en mode chemin (`/author/manuscripts/42`), pas en `#/...`. **Le
  serveur qui héberge `build/web` doit rediriger toute route inconnue vers
  `index.html`** (fallback SPA), sinon un rafraîchissement sur `/admin/users`,
  `/author/manuscripts/42` ou `/books/12/read` renvoie un 404 serveur avant
  même que Flutter ne s'exécute. C'est exactement ce que fait
  `docker/nginx.conf` (section 5) via `try_files $uri $uri/ /index.html;`.
- **404 interne** : une fois l'app chargée, une route qui ne correspond à
  aucun `GoRoute` affiche `NotFoundScreen` (`lib/core/widgets/not_found_screen.dart`)
  au lieu de l'écran d'erreur brut de go_router.
- **Jeton JWT** : stocké via `flutter_secure_storage`, qui utilise l'API
  WebCrypto du navigateur sur Web. Cela exige un **contexte sécurisé**
  (HTTPS, ou `localhost` en dev) — servir la prod en HTTP simple casse le
  stockage du token. L'image Docker/nginx ne fait pas elle-même de TLS : en
  production, Caddy (devant le conteneur) doit terminer le HTTPS.
- **CORS** : à configurer côté backend (hors de ce dépôt) pour autoriser les
  origines `https://app.plumora-books.fr` (prod) et `https://staging-app.plumora-books.fr`
  (staging), avec le header `Authorization` dans `Access-Control-Allow-Headers`.
  Une erreur CORS se manifeste dans l'app comme une `DioExceptionType.connectionError`
  (message affiché : « Impossible de joindre le serveur Plumora. ») — voir
  section 8.
- **Images distantes / liens externes** : `Image.network` et `url_launcher`
  fonctionnent nativement sur Web ; `resolvePlumoraImageUrl` (dans
  `lib/core/widgets/plumora_ui.dart`) résout les chemins relatifs renvoyés par
  l'API contre `AppConfig.apiBaseUrl`.
- **Responsive / admin / éditeur** : déjà géré par `MainShell` (bascule
  desktop/mobile à 1024px de large) et par les écrans individuels
  (administration, éditeur de manuscrit, panneau Plumo) — aucune reprise
  nécessaire pour cette tâche.
- **Navigation clavier et souris** : héritée des widgets Material standard
  (`InkWell`, `TextButton`, `PopupMenuButton`, focus traversal par défaut de
  Flutter) ; non retravaillée spécifiquement ici.

## 4. Expérience multiplateforme

Toutes les fonctionnalités principales sont conservées sur mobile, Web et
desktop — rien n'a été retiré.

### Mobile (Android / iOS)

Une carte discrète a été ajoutée dans l'espace auteur mobile
(`lib/features/writing/presentation/widgets/continue_on_web_card.dart`,
intégrée dans `author_dashboard_screen.dart`) :

- Visible uniquement sur Android/iOS natifs (`ContinueOnWebCard.isRelevant`
  — jamais sur Flutter Web, jamais sur desktop).
- Ouvre `${WEB_BASE_URL}/author/manuscripts/{manuscriptId}` dans le
  navigateur externe (`url_launcher`, `LaunchMode.externalApplication`).
- **Aucun JWT ni secret n'est jamais inclus dans cette URL** (voir section 8,
  test dédié dans `test/continue_on_web_card_test.dart`).
- Si le navigateur n'a pas de session active, l'auteur se reconnecte
  normalement (comportement MVP accepté, pas de SSO app→navigateur).
- Côté routing, `/author/manuscripts/:bookId` est un alias go_router qui
  redirige vers l'écran réel `AppRoutes.authorBookDetail`
  (`/books/:bookId/author`) — le lien reste stable même si l'écran interne
  change de chemin.

### Web et desktop (Windows / macOS)

Le code compile pour Windows et macOS sans changement structurel : aucune
dépendance `dart:io` directe dans `lib/`, et les grands écrans (sidebar,
éditeur de chapitre large, liste des chapitres, panneau Plumo, administration
complète) sont déjà adaptés via le breakpoint desktop de `MainShell`
(≥ 1024px de large) mis en place lors de travaux précédents.

Aucune fonctionnalité native complexe (mise à jour automatique, raccourcis
système avancés) ni mode hors-ligne n'a été ajoutée : explicitement hors du
périmètre de cette étape.

## 5. Image Docker (Flutter Web)

`Dockerfile` (racine du dépôt) est un build multi-stage :

1. **Stage `build`** — `debian:bookworm-slim` + Flutter `3.44.0` (cloné en
   `--depth 1` depuis le dépôt officiel, aucune image tierce non officielle).
   Reçoit `APP_ENV`, `API_BASE_URL`, `WEB_BASE_URL` comme `--build-arg` et les
   transmet à `flutter build web --release` via `--dart-define`. Ne contient
   et ne reçoit aucun secret serveur.
2. **Stage `runtime`** — `nginxinc/nginx-unprivileged:1.27-alpine` (image
   nginx:alpine officielle repackagée pour tourner en non-root sur un port
   non privilégié par défaut), qui ne copie que `build/web`.

### Build

```bash
docker build \
  --build-arg API_BASE_URL=https://api.plumora-books.fr/api/v1 \
  --build-arg WEB_BASE_URL=https://app.plumora-books.fr \
  --build-arg APP_ENV=production \
  -t plumora-frontend-web .
```

### Run local

```bash
docker run --rm -p 8080:8080 plumora-frontend-web
curl -I http://localhost:8080/                # page d'accueil
curl -I http://localhost:8080/admin/users      # fallback SPA -> 200, index.html
```

### Port interne

**8080** (non privilégié, cohérent avec l'utilisateur non-root de l'image).
`EXPOSE 8080` dans le `Dockerfile`, écoute déclarée dans `docker/nginx.conf`.

### Fallback SPA

`docker/nginx.conf` :

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

`index.html`, `flutter_service_worker.js` et `version.json` sont servis avec
`Cache-Control: no-cache` (toujours revalidés, pour que Flutter détecte une
nouvelle version après un redéploiement) ; le reste (JS, wasm CanvasKit,
polices, images) avec un cache court d'une heure — les noms de fichiers du
build Flutter Web standard ne sont pas hashés, un cache long/« immutable »
risquerait de servir du JS périmé après un redéploiement.

### En-têtes de sécurité

`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`,
`Permissions-Policy` et une `Content-Security-Policy` compatible avec le
renderer CanvasKit de Flutter Web (wasm same-origin, `worker-src blob:`,
`style-src 'unsafe-inline'` requis par le moteur Flutter lui-même). Voir les
commentaires dans `docker/nginx.conf` pour le détail de chaque choix.

**Piège corrigé** : `script-src` n'autorise que `'self'` (pas de CDN tiers).
Or par défaut, `flutter build web` charge CanvasKit depuis
`https://www.gstatic.com/flutter-canvaskit/...` au runtime plutôt que depuis
les fichiers `/canvaskit/` déjà présents dans l'image — ce que cette CSP
bloque silencieusement (page blanche, aucune erreur serveur, tous les
fichiers statiques répondent 200 : `curl` ne peut pas détecter ce problème
puisqu'il n'exécute pas de JS). Le `Dockerfile` compile donc avec
`--no-web-resources-cdn`, qui force le chargement de CanvasKit depuis la même
origine et embarque `"useLocalCanvasKit":true` dans `flutter_bootstrap.js` —
vérifié explicitement par le smoke test CI (section 12).

### Healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1
```

### Intégration avec le docker-compose du dépôt backend

Ce dépôt ne contient pas et ne modifie pas l'infrastructure Docker Compose
(elle vit dans le dépôt backend). Le contrat attendu, tel que décrit par le
projet :

- l'image de ce dépôt doit être publiée/taguée sous le nom que la variable
  `FRONTEND_IMAGE` du docker-compose backend référence ;
- le conteneur doit répondre sur le nom de service `frontend-web`, port
  interne **8080** ;
- Caddy (côté backend) fait un reverse proxy vers `frontend-web:8080` et
  gère la terminaison TLS — cette image ne fait pas de TLS elle-même.

Aucune image n'a été poussée vers un registre, aucun VPS n'a été contacté et
le backend n'a pas été modifié.

## 6. Android

Audité dans `android/app/build.gradle.kts`, `AndroidManifest.xml`,
`android/app/src/main/res/` :

| Point | État | Action |
|---|---|---|
| Permission Internet | ❌ absente → **corrigé** | `<uses-permission android:name="android.permission.INTERNET" />` ajoutée à `AndroidManifest.xml`. Sans elle, un **build release** (contrairement au debug) n'a accès à aucun réseau. |
| `applicationId` | `com.example.plumora_app` (placeholder) | **Action manuelle requise** — voir ci-dessous. |
| Nom affiché | `android:label="plumora_app"` | **Action manuelle** si un nom d'affichage différent est voulu (actuellement le nom de package, pas "Plumora"). |
| Icône / écran de lancement | Icône et `launch_background.xml` par défaut de `flutter create` | **Action manuelle** — fournir les assets de marque Plumora (`flutter_launcher_icons` ou remplacement manuel des `mipmap-*`). |
| Version / build number | `pubspec.yaml` → `version: 1.0.0+1` (utilisé comme `versionName`/`versionCode`) | OK pour une première publication ; à incrémenter à chaque release. |
| Signature release | Signait avec la clé **debug** → **corrigé** | `build.gradle.kts` charge maintenant un `signingConfigs["release"]` **si et seulement si** `android/key.properties` existe ; sinon, retombe sur la clé debug (comportement identique à avant, mais explicite et prêt pour une vraie clé). |
| `key.properties` | N'existe pas (et restera absent de ce dépôt) | `android/key.properties.example` documente le format attendu ; `android/.gitignore` exclut déjà `key.properties`, `*.keystore`, `*.jks`. **Aucune vraie clé n'a été créée.** |

### Valeurs à fournir manuellement (Android)

1. **`applicationId`** définitif (`android/app/build.gradle.kts`, ligne
   `applicationId = "..."`) — ex. `fr.plumora.app` ou `com.plumora.app`.
   Irréversible une fois publié sur le Play Store : à choisir avant la
   première publication, pas modifiable après.
2. **Un vrai keystore de release**, généré et conservé par vous seul :
   ```bash
   keytool -genkey -v -keystore ~/plumora-release.keystore \
     -keyalg RSA -keysize 2048 -validity 10000 -alias plumora
   ```
   puis copier `android/key.properties.example` vers `android/key.properties`
   (git-ignoré) et y renseigner `storePassword`, `keyPassword`, `keyAlias`,
   `storeFile`.
3. **Icône et écran de lancement** aux couleurs Plumora (assets graphiques
   réels, non générés ici).
4. Éventuellement un nom d'affichage (`android:label`) différent du nom de
   package.

## 7. iOS

Audité dans `ios/Runner/Info.plist` et `ios/Runner.xcodeproj/project.pbxproj` :

| Point | État | Action |
|---|---|---|
| Nom affiché | `CFBundleDisplayName = "Plumora App"` | Déjà correct. |
| Bundle Identifier | `com.example.plumoraApp` (placeholder) | **Action manuelle requise** — voir ci-dessous. |
| Permissions | Aucune entrée `NSPhotoLibraryUsageDescription`/`NSCameraUsageDescription` | Pas nécessaire actuellement : le seul point d'accès fichier (`file_selector.openFile` dans `create_book_screen.dart`, choix de la couverture d'un livre) utilise le sélecteur de documents natif (`UIDocumentPickerViewController` / `PHPickerViewController`), qui ne requiert **aucune** permission `Info.plist`. Si un futur écran accède directement à la photothèque, la permission correspondante devra être ajoutée à ce moment-là. |
| Configuration réseau (ATS) | Stricte par défaut (HTTPS uniquement) — bloquait `http://localhost:8080` en dev sur device/simulateur réel → **corrigé** | `NSAppTransportSecurity` / `NSAllowsLocalNetworking` ajouté : autorise le réseau local/loopback **uniquement**, ne touche pas à la sécurité des hôtes publics (prod/staging restent strictement HTTPS). |
| Compatibilité build macOS | `IPHONEOS_DEPLOYMENT_TARGET = 13.0` | Compatible avec les dépendances actuelles (aucun changement nécessaire). |
| Build réel | Non exécutable depuis Windows | Nécessite une machine macOS + Xcode (voir section 9). |

### Valeurs à fournir manuellement (iOS)

1. **Bundle Identifier** définitif (`PRODUCT_BUNDLE_IDENTIFIER` dans
   `ios/Runner.xcodeproj/project.pbxproj`, 3 occurrences pour la cible
   principale + tests) — ex. `fr.plumora.app`. Doit correspondre à
   l'identifiant déclaré dans App Store Connect.
2. **Compte Apple Developer** + certificat de distribution + profil de
   provisioning App Store — rien de tout cela n'a été créé ici (aucun
   certificat ni secret Apple généré, comme demandé).
3. Icônes App Store (`ios/Runner/Assets.xcassets/AppIcon.appiconset`) aux
   couleurs Plumora.
4. Build effectif : `flutter build ipa --release ...` sur une machine macOS
   avec Xcode installé, puis upload via Transporter/Xcode Organizer.

## 8. Gestion du JWT

La stratégie existante (`flutter_secure_storage` + intercepteur Dio +
`AuthRepository`) a été **conservée telle quelle**, pas remplacée. Audit :

- **Stockage** : `lib/core/storage/secure_token_storage.dart` — un seul token
  (`plumora_jwt`) via `flutter_secure_storage`, qui choisit automatiquement le
  backend adapté par plateforme (Keychain iOS/macOS, Keystore Android,
  DPAPI Windows, libsecret Linux, WebCrypto + stockage chiffré sur Web —
  contexte sécurisé requis, voir section 3).
- **Envoi du token** : un unique `QueuedInterceptor` (`_JwtInterceptor` dans
  `lib/core/network/dio_client.dart`) l'ajoute en `Authorization: Bearer ...`
  sur toutes les requêtes. Le token n'apparaît **jamais dans une URL** (ni
  query param, ni path).
- **401 / 403** : `AuthRepository._loadCurrentUser` et `.restoreSession`
  traitent les deux identiquement — le token est effacé du stockage sécurisé
  et la session redevient non authentifiée. Le routeur (`app_router.dart`,
  callback `redirect`) renvoie alors automatiquement vers `/login`. Vérifié
  par `test/auth_repository_test.dart` avec un `HttpClientAdapter` Dio mocké
  (aucun vrai backend appelé).
- **Erreur réseau** (backend injoignable, CORS, timeout) : contrairement à un
  401/403, le token **n'est pas effacé** — l'exception se propage jusqu'à
  `AuthController.build()`, capturée par Riverpod en `AsyncError`. L'auteur
  n'est donc pas déconnecté à cause d'une simple coupure réseau ; relancer
  l'app une fois la connexion rétablie restaure la session silencieusement
  avec le même token. Vérifié dans `test/auth_repository_test.dart`.
- **Renouvellement du token** : il n'existe **aucun endpoint/flux de refresh
  token** côté client actuellement (`AuthApiService` n'expose pas de méthode
  de ce type) — l'expiration force une reconnexion complète. C'est un
  comportement préexistant, non modifié ici ; à traiter séparément si un
  refresh token est ajouté côté backend.
- **Déconnexion** : `AuthController.logout()` efface le token
  (`AuthRepository.logout()`) et invalide les caches utilisateur (`profile`,
  `admin`) ; câblé depuis `profile_screen.dart` et `admin_shell.dart`.
- **Absence de token dans les logs** : aucun `print`/`debugPrint`/log
  n'affiche le token nulle part dans `lib/` (vérifié par recherche exhaustive).
- **Absence de token dans une URL** : vérifié explicitement par
  `test/continue_on_web_card_test.dart` pour le lien « Continuer sur le web »
  (seul endroit du code qui construit une URL vers une autre surface de
  l'app).

## 9. Compatibilités validées dans cet environnement de développement

Cet environnement (Windows, sans Chrome ni Visual Studio installés, avec
Docker Desktop) permet de valider :

| Cible | Commande | Résultat |
|---|---|---|
| Web | `flutter build web --release` | ✅ Build réussi (`build/web`) |
| Android (bundle) | `flutter build appbundle --release` | ✅ Build réussi (`build/app/outputs/bundle/release/app-release.aab`) |
| Windows | `flutter build windows --release` | ❌ Échoue ici : *"Unable to find suitable Visual Studio toolchain"* — installer Visual Studio + workload "Desktop development with C++" pour construire réellement ce binaire. Pas un problème de code. |
| macOS / iOS | `flutter build macos` / `flutter build ipa` | ⏭️ Non exécutable depuis Windows — nécessite une machine macOS avec Xcode. |
| Docker (image Web) | `docker build` + `docker run` | ✅ voir résultats détaillés donnés en fin de tâche |

`flutter analyze`, `dart format .` et `flutter test` passent tous sans
erreur (détail du nombre de tests en fin de tâche).

## 10. Limitations connues

- Build Windows/macOS/iOS non vérifiable sur cette machine de développement
  (toolchains manquants) — à valider en CI (`windows-latest` GitHub Actions
  fournit Visual Studio ; macOS/iOS nécessitent un runner `macos-latest`).
- Aucun flux de refresh token côté client (voir section 8) : l'expiration du
  JWT force une reconnexion complète — comportement préexistant, non modifié.
- Avertissement Flutter/Gradle : `google_sign_in_all_platforms_mobile` et
  `quill_native_bridge_android` appliquent encore l'ancien Kotlin Gradle
  Plugin ; une future version de Flutter refusera de builder tant que ces
  plugins n'auront pas migré vers le "Built-in Kotlin". À surveiller lors
  des mises à jour de dépendances.
- La carte « Continuer sur le web » ne transfère pas la session : l'auteur
  se reconnecte dans le navigateur (accepté pour le MVP, voir section 4).
- CORS est un réglage backend, hors du code de ce dépôt — voir section 3
  pour les valeurs attendues.
- `applicationId` (Android) et Bundle Identifier (iOS) restent des
  placeholders `com.example.*` — actions manuelles listées aux sections 6-7.
  Le nom de produit Windows/macOS (`plumora_app` / `com.example` dans
  `windows/runner/Runner.rc`) est un polish cosmétique du même ordre, non
  traité ici faute de demande explicite.
- L'image Docker ne fait pas de TLS : c'est Caddy (dépôt backend) qui doit
  terminer HTTPS devant `frontend-web:8080`.

## 11. Dépendances spécifiques à une plateforme

| Dépendance | Web | Android | iOS | Windows | macOS |
|---|---|---|---|---|---|
| `flutter_secure_storage` | ✅ (WebCrypto, contexte sécurisé requis) | ✅ (Keystore) | ✅ (Keychain) | ✅ (DPAPI) | ✅ (Keychain) |
| `google_sign_in_all_platforms` | ✅ (Google Identity Services) | ✅ | ✅ | ✅ (flux navigateur système, `GOOGLE_DESKTOP_CLIENT_ID/SECRET`) | ✅ (idem Windows) |
| `flutter_quill` (+ `quill_native_bridge_*`) | ✅ | ✅ | ✅ | ✅ | ✅ (plugin natif enregistré dans `GeneratedPluginRegistrant.swift`) |
| `file_selector` | ✅ | ✅ | ✅ (document picker, aucune permission requise) | ✅ | ✅ |
| `url_launcher` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `flutter_web_plugins` (URL strategy) | ✅ (seule plateforme concernée) | n/a | n/a | n/a | n/a |

macOS requiert en plus l'entitlement `com.apple.security.network.client`
(app sandboxée) pour tout appel HTTPS sortant — absent des deux fichiers
`macos/Runner/*.entitlements` avant cette tâche, **ajouté** dans
`DebugProfile.entitlements` et `Release.entitlements`.

## 12. Intégration continue et publication de l'image (GitHub Actions → GHCR)

Le workflow existant `.github/workflows/flutter-ci.yml` a été **étendu** (pas
recréé) : un job `docker-publish` a été ajouté, et `on.push` reçoit en plus
les tags `v*`. Les jobs `quality`, `build-web`, `build-android`,
`build-linux-desktop` déjà présents sont inchangés dans leur logique.

### Comportement sur une pull request

Le job `quality` (`flutter pub get`, `dart format --set-exit-if-changed`,
`flutter analyze`, `flutter test`) et le job `build-web` (`flutter build web
--release`) tournent comme avant. `build-web` utilise désormais une URL de
validation explicitement non résolvable (`https://ci-validate.plumora.invalid/api/v1`,
domaine réservé RFC 2606) plutôt que la valeur de développement par défaut,
pour bien marquer qu'il ne s'agit que d'une vérification de compilation.
**Aucune image Docker n'est construite ni publiée sur une pull request**, y
compris depuis un fork externe : le job `docker-publish` ne s'exécute que sur
un évènement `push` (jamais `pull_request`).

### Comportement sur `main` ou un tag `v*`

Le job `docker-publish` (`needs: quality`, donc les vérifications rejouent
avant toute publication) :

1. construit l'image via le `Dockerfile` de la racine, avec
   `APP_ENV=production`, `API_BASE_URL=https://api.plumora-books.fr/api/v1`,
   `WEB_BASE_URL=https://app.plumora-books.fr` en `--build-arg` — aucune autre
   variable, aucun secret ;
2. la charge dans le moteur Docker du runner (`load: true`, pas encore
   poussée) et lance un **smoke test** : démarrage du conteneur, attente de
   `healthy` (jusqu'à 60s), `HTTP 200` sur `/`, `/admin/users`,
   `/author/manuscripts/42`, `/books/12/read`, et vérification que
   `flutter_bootstrap.js` embarque `"useLocalCanvasKit":true` (garde-fou
   anti-régression contre le piège CSP/CDN de la section 5) ;
3. seulement si le smoke test réussit, publie l'image dans GitHub Container
   Registry.

Un échec du smoke test fait échouer le job **avant** toute publication.

### Image et tags

Nom exact de l'image (owner normalisé en minuscules, requis par
Docker/GHCR) :

```
ghcr.io/<repository_owner en minuscules>/plumora-frontend
```

| Déclencheur | Tags produits |
|---|---|
| Tag Git `v1.0.0-beta` | `v1.0.0-beta` (valeur exacte du tag) et `sha-<7 caractères>` |
| Push sur `main` | `sha-<7 caractères>` et, en plus, `latest` (jamais seul — toujours accompagné du tag `sha-`) |

Générés par `docker/metadata-action@v5` :

```yaml
tags: |
  type=semver,pattern={{raw}}
  type=sha,format=short,prefix=sha-
  type=raw,value=latest,enable={{is_default_branch}}
```

### Authentification et permissions

- `GITHUB_TOKEN` (pas de PAT) via `docker/login-action`.
- Permissions minimales, au niveau du job (remplacent, et n'étendent pas,
  le `contents: read` par défaut du workflow) : `contents: read`,
  `packages: write` — les autres jobs du même workflow n'ont toujours que
  `contents: read`.
- Prérequis côté dépôt GitHub : Settings → Actions → General → Workflow
  permissions doit autoriser l'écriture (ou au minimum ne pas bloquer la
  permission `packages: write` demandée explicitement par le job). Lors de la
  toute première publication, le package GHCR créé peut être **privé** par
  défaut : ajuster sa visibilité dans Settings → Packages si un accès public
  est nécessaire (GITHUB_TOKEN ne peut pas changer cette visibilité lui-même).

### Exemple `FRONTEND_IMAGE` (docker-compose backend)

Ce dépôt ne modifie pas le docker-compose backend ; à titre d'exemple, la
variable que ce dépôt s'attend à voir référencée là-bas :

```bash
# Déploiement d'une version taguée (recommandé en production)
FRONTEND_IMAGE=ghcr.io/<owner>/plumora-frontend:v1.0.0-beta

# Déploiement du dernier commit de main
FRONTEND_IMAGE=ghcr.io/<owner>/plumora-frontend:sha-abc1234
```

`latest` reste utilisable comme alias de confort, mais ne doit pas être
l'unique référence en production : `sha-<commit>` ou `vX.Y.Z` restent
disponibles indéfiniment (tags immuables), alors que `latest` est réécrit à
chaque push sur `main`.

### Procédure de rollback

Aucun tag n'est jamais supprimé ni réécrit (à l'exception de `latest`), donc
un rollback consiste simplement à republier le service frontend avec le tag
précédent :

1. Identifier le tag précédent connu-bon (ex. via l'historique des runs
   GitHub Actions, ou `git log` pour retrouver le SHA court d'un commit
   antérieur stable).
2. Dans le docker-compose backend, remplacer la valeur de `FRONTEND_IMAGE`
   par ce tag, par exemple :
   ```bash
   FRONTEND_IMAGE=ghcr.io/<owner>/plumora-frontend:sha-<sha-precedent>
   ```
3. Redéployer uniquement le service `frontend-web` (`docker compose pull
   frontend-web && docker compose up -d frontend-web`), sans toucher au
   backend ni à la base de données.
4. Vérifier `/`, une route profonde (ex. `/books/12/read`) et le healthcheck
   du conteneur avant de considérer le rollback terminé.

Cette procédure n'a pas été exécutée ici : aucun déploiement réel, aucune
image publiée, aucun VPS contacté.
