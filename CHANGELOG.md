# Changelog

All notable changes to the **Plumora** Flutter app (`plumora_app`, the frontend repository — the Spring Boot backend lives in a separate repository per `AGENTS.md`) are documented here.

This project has not yet cut any formal releases or git tags. The versions below are development milestones reconstructed from the commit history so the project's progress can be tracked like a normal changelog. Numbering follows semantic versioning conventions (MINOR = a new feature/module lands, PATCH = fixes, refinements or visual polish with no new module), and each entry links back to the commit it was generated from so it can be verified with `git show <hash>`. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

Nothing pending — the working tree is clean as of this writing.

## [0.5.1] — 2026-07-05

_Commit `464be41` — "Aligne l'interface Figma et corrige la CI"_

### Changed
- Reworked the landing screen hero section to match the Figma mockup: gradient CTA buttons (`Se connecter`, `Rejoindre gratuitement`) replacing flat-colour buttons, corrected icon placement (trailing arrow on the primary CTA instead of leading), corrected type scale/weights on the title/subtitle/stat labels, corrected book-cover stack sizing with an edge fade mask, emoji-based feature cards instead of Material icons to match Figma exactly.
- Realigned `HomeScreen`, `DiscoverScreen` and `LibraryScreen` visuals against their Figma references.
- Refined the `MainShell` navigation chrome (mobile bottom bar / desktop sidebar).
- Adjusted `RoleSelectionScreen` and `AuthScreenShell` styling, and a handful of shared tokens in `figma_plumora.dart`.

### Fixed
- `.github/workflows/flutter-ci.yml` adjustment.
- Small correction in `ReadingScreen`.

## [0.5.0] — 2026-07-05

_Commit `3e6f861` — "feat: integrate catalog and app redesign"_

### Added
- External/public-domain book catalog powered by Gutendex (Project Gutenberg): `ExternalBookModel`, `ExternalBookRepository`, `ExternalBookApiService`, `ExternalBookDetailScreen`, `PublicDomainCatalogScreen`. Any authenticated user can browse and import a public-domain book into Plumora (`POST /books/import/gutendex/{gutendexId}`), per the "External Books" section of `docs/api-contract.md`.
- Review support for external (non-Plumora) books, reusing the same `{ rating, comment }` payload as internal book reviews, without requiring the book to be imported first.
- `lib/core/widgets/figma_plumora.dart` — a new shared design-system widget kit (`FigmaCard`, `FigmaBrandMark`, `FigmaBookCover`, `FigmaGradientIcon`, `FigmaPillTab`, …) derived from the Figma reference and reused across most screens from this point on.

### Changed
- Broad visual redesign pass across `LandingScreen`, `LoginScreen`, `RegisterScreen`, the Discover/Library/Home/Profile screens and both Mukeme (AI) screens, bringing them closer to an updated round of Figma mockups.
- Updated the Figma reference export itself (`figma/src/app/screens/*`, `theme.css`, cover images) to a newer design iteration.
- `docs/api-contract.md` extended with the External Books contract.

### Removed
- Deleted the obsolete static HTML mockup exports (`figma/html-export/`, `figma/public/export/`), superseded by the live Figma/React reference under `figma/src/`.

## [0.4.1] — 2026-05-23

_Commit `707eec3` — "fix seed"_

### Added
- `BookCoverCache` (client-side cover image caching) and `AuthCacheInvalidator` (Riverpod provider-cache invalidation on auth state changes).
- Documented the cover-image field aliases (`coverImage`, `cover_image`, `image`, `imageFile`, `cover`, `file`) and the `GET /uploads/book-covers/{filename}` route in `docs/api-contract.md`.

### Fixed
- Corrected field mappings across `BookModel`, `CatalogBookModel`, `ReadingProgressModel`, `BetaCampaignModel`, `BetaInvitationModel` and several screens (book creation/detail, my-books, publish flow, library, favorites, reviews, beta invitations, discover, catalog search) to match the real backend contract discovered while wiring up seed data.
- Expanded `test/api_contract_seed_test.dart` and `test/widget_test.dart` to cover the corrected contract.

## [0.4.0] — 2026-05-23

_Commit `eae68df` — "fix CI"_

Despite the commit message, this is the largest feature drop after the initial redesign — it brings the app from "auth + books" up to the **full MVP feature surface** described in `AGENTS.md`.

### Added
- Continuous integration: `.github/workflows/flutter-ci.yml`.
- **Mukeme AI writing assistant** — models, `AiRepository`, `AiApiService`, `MukemeWritingScreen` (reformulate / improve style / fix repetitions / make more emotional / make dialogue natural) and `MukemeRecommendationScreen` (mood/genre/duration-based recommendations), wired to `POST /ai/writing/suggestions` and `POST /ai/recommendations/books`.
- **Beta-reading module, end to end** — campaign/comment/invitation/shared-chapter models, `BetaReadingRepository`, `BetaReadingApiService`, and 8 screens: author-side campaign management (`BetaCampaignsAuthorScreen`, `BetaCampaignDetailAuthorScreen`) and feedback inbox (`AuthorBetaCommentsScreen`, `BetaFeedbackScreen`), plus the beta-reader side (`BetaInvitationsScreen`, `BetaReadingChaptersScreen`, `BetaReadChapterScreen`, `CreateBetaCommentBottomSheet`).
- **Reading module, end to end** — favourites, reviews and reading-progress models/repositories/services, `ReadingScreen`, `MyFavoritesScreen`, `MyReviewsScreen`.
- **Notifications module, end to end** — model, repository, API service, `NotificationsScreen`.
- Catalog expansion — `CatalogBookModel`, `CatalogRepository`, `CatalogApiService`, `BookDetailScreen`, `CatalogSearchScreen`.
- `PublishBookScreen` and `ChapterDetailAuthorScreen` for the author publishing flow.
- `test/api_contract_seed_test.dart`, a large contract/seed-data regression test (first version).

## [0.3.0] — 2026-05-22

_Commit `87c66b5` — "feature book"_

### Added
- Imported the full Figma design export into `figma/` (React + TypeScript + Tailwind mockup, the shadcn/ui component library, and every planned screen) to serve as the canonical visual reference for the Flutter UI going forward.
- **Book & writing module** — `BookModel`, `ChapterModel`, `BookRepository`, `ChapterRepository`, `BookApiService`, `ChapterApiService`.
- Author-side screens — `AuthorDashboardScreen`, `BookDetailAuthorScreen`, `ChapterEditorScreen`, `CreateBookScreen`, `MyBooksScreen`.
- Shared design-system widgets — `plumora_ui.dart`, `plumora_logo_mark.dart`, `book_status_badge.dart`.

### Changed
- Major rewrites of `HomeScreen`, `DiscoverScreen`, `LibraryScreen`, `ProfileScreen`, `LoginScreen`, `RegisterScreen`, `RoleSelectionScreen` and `AuthScreenShell`, moving them off placeholder content and onto the new Figma-driven design system.
- Expanded `app_router.dart` / `main_shell.dart` with the new author-space routes and the responsive navigation shell.

## [0.2.0] — 2026-05-21

_Commit `a18a20d` — "feature auth"_

### Added
- JWT-based authentication — `AuthResponse`, `LoginRequest`, `RegisterRequest`, `RoleModel`, `UserModel`, `AuthRepository`, `AuthApiService`, `AuthController` (a Riverpod `AsyncNotifier`).
- `SecureTokenStorage` (a `flutter_secure_storage` wrapper) and a Dio provider with a JWT-attaching request interceptor.
- `AppError`, a centralized Dio-exception-to-French-message mapper used for user-facing error states.
- Real `LoginScreen`, `RegisterScreen`, `RoleSelectionScreen` and a shared `AuthScreenShell`, replacing the single placeholder `auth_screen.dart`.
- `LandingScreen` (first version).

## [0.1.0] — 2026-05-21

_Commit `5d0cc7c` — "fix structure"_

### Added
- Initial Flutter project scaffold targeting Android, iOS, Linux, macOS, Windows and Web.
- Core dependencies in `pubspec.yaml` (`stacked`, `stacked_services`, `get_it`, `dio`, `go_router`, `flutter_riverpod`, `flutter_secure_storage`, `file_picker`, `url_launcher`).
- `AGENTS.md` and the shared project documentation: `docs/project-context.md`, `docs/data-model.md`, `docs/api-contract.md`, `docs/shared-decisions.md` — defining the product scope, the database schema and the backend REST contract ahead of implementation.
- Core skeleton: `core/network` (Dio client, API base-URL config), `core/routing` (initial `app_router.dart`), `core/theme` (`plumora_colors.dart`, `plumora_theme.dart`), `core/widgets` (placeholder screen).
- Placeholder screens for every planned feature folder (auth, home, discover, library, profile, write).

---

## Known issues / technical debt

Not tied to a specific version — carried forward from the codebase as of `464be41`:

- `lib/features/writing/presentation/editor_screen.dart` and `write_screen.dart` are orphaned: not referenced by `app_router.dart` (superseded by `ChapterEditorScreen` and `AuthorDashboardScreen` respectively).
- `lib/features/book/presentation/manuscripts_screen.dart` is similarly unreferenced, superseded by `lib/features/writing/presentation/my_books_screen.dart`.
- `pubspec.yaml` still declares `stacked`, `stacked_services` and `get_it` as dependencies, but the app is built entirely on `flutter_riverpod` — none of the three are actually used.
- The theme references the `Nunito` and `Playfair Display` font families, but no font assets or `google_fonts` dependency are bundled, so both currently fall back to the platform's system font.
- `app_router.dart` has no top-level `redirect:` auth guard; each screen checks authentication state individually.

## Explicitly out of scope for the MVP

Per `AGENTS.md` / `docs/project-context.md` — not a gap, a deliberate boundary:

- Payments, real royalties, subscriptions.
- Admin publication-validation workflow (publication is direct by the author).
- Chat.
- Marketplace.
