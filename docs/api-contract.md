# Plumora API Contract

Base URL:
`/api/v1`

## Auth

POST `/auth/register`
POST `/auth/login`
POST `/auth/google`
POST `/auth/forgot-password`
POST `/auth/reset-password`
GET `/auth/me`
GET `/users/me`
PUT `/users/me`
PUT `/users/me/roles`

PUT `/users/me` request body: `{ "firstname", "lastname", "username", "bio"?,
"avatarUrl"? }`. Returns the updated `UserModel` (same shape as `GET
/users/me`). Used by the profile "Informations personnelles" editor
(`edit_profile_screen.dart`) to update name/username/bio; roles are edited
separately via `PUT /users/me/roles`, not through this endpoint.

POST `/auth/google` request body: `{ "idToken": "<Google ID token>" }`.
Response: same shape as `/auth/login` (`accessToken` + `user`).

The frontend obtains the Google ID token itself (native account picker on
Android/iOS, Google Identity Services on web, system-browser OAuth on
Windows/Linux/macOS) and never talks to the Plumora backend during that step.
The backend must, on receiving `idToken`:
- verify its signature against Google's public keys
  (`https://www.googleapis.com/oauth2/v3/certs`);
- check `iss` is `accounts.google.com` or `https://accounts.google.com`;
- check `exp` has not passed;
- check `aud` matches one of the app's configured Google OAuth client IDs
  (the frontend's "web" client id is reused as the audience for both the web
  and native-mobile flows; the "desktop" client id used for the
  Windows/Linux/macOS browser flow is a separate OAuth client and is not a
  valid token audience — only the web client id should be accepted);
- find the Plumora user by the token's verified `email`, or create one if
  none exists (the email is already verified by Google). See the `users`
  table note in docs/data-model.md — this account has no password.

POST `/auth/forgot-password` request body: `{ "email": "<email>" }`. Sent
from the "Mot de passe oublié ?" link on the login screen
(`forgot_password_screen.dart`). Must always respond with 200 whether or
not an account exists for that email — the response must not be used to
leak account existence. On success, emails the user a link to
`{frontend_base_url}/reset-password?token=<token>` with a short-lived,
single-use reset token. Google-only accounts (see above, no password set)
should presumably reject or special-case this — not yet decided, flag to
the frontend if the behavior needs to differ from a normal 200.

POST `/auth/reset-password` request body: `{ "token": "<token>",
"newPassword": "<new password, min 8 chars>" }`. Consumed by
`reset_password_screen.dart`. The token must be single-use and expire
after a short window (e.g. 1 hour); an invalid/expired/already-used token
should respond 400 with a message the frontend can surface via
`AppError.messageFor` (see `_statusMessage`/`_responseMessage` in
`app_error.dart` — any `message`/`error`/`detail` string field in the JSON
body is shown to the user as-is, so keep it end-user readable in French).
On success the token is invalidated and existing sessions/tokens for that
user should presumably be revoked — not yet decided with the backend.

## Books

POST `/books`
GET `/books/my-books`
GET `/books/{bookId}`
PUT `/books/{bookId}`
PATCH `/books/{bookId}/publish`
PATCH `/books/{bookId}/archive`

Book create/update payloads may be sent as JSON or as `multipart/form-data`.
The book's summary field is named `summary` in both the request body and the
response (not `description` — the backend silently ignores a `description`
field and saves no summary at all if that's the only name sent).
When a user imports a cover image, the frontend sends:
- text fields: `title`, `summary`, `genre`, `visibility`
- file field: `coverImage`

Accepted cover file aliases on the API side are `coverImage`, `cover_image`,
`image`, `imageFile`, `cover` and `file`.

Book responses should return this image as `coverUrl`. The frontend also accepts
`cover_url`, `coverImageUrl`, `cover_image_url`, `imageUrl` and `image_url` for
compatibility.

Persisted local cover URLs may be relative to the API base path, for example:
`uploads/book-covers/{filename}`. The public image route is:
GET `/uploads/book-covers/{filename}`.

**`chapterCount` / `wordCount` (fixed 2026-07):** `BookResponse` now
includes real `chapterCount` and `wordCount` fields, computed
server-side from the book's actual chapters (`BookService.getChapterStats`),
on every endpoint that returns a `BookResponse` — `my-books`, `{bookId}`,
create, update, publish, archive. `GET /books/my-books` uses one grouped
query for the whole list (no N+1). These field names (`chapterCount`,
`wordCount`, plain camelCase) match what the Flutter client already
parses (`book_model.dart`), so the "Mes histoires" list screen
(`author_dashboard_screen.dart`), which has no other way to know a
book's chapter/word totals, needed no client change — it was reading
these exact field names all along, they just weren't populated before.
The book detail screen also has an independent client-side fallback
(computes from the live chapter list when loaded) that stays in place as
a defensive belt-and-suspenders, not because it's still needed.

## Chapters

POST `/books/{bookId}/chapters`
GET `/books/{bookId}/chapters`
GET `/chapters/{chapterId}`
PUT `/chapters/{chapterId}`
DELETE `/chapters/{chapterId}`

## Catalog

GET `/catalog/books`
GET `/catalog/books/{bookId}`
GET `/catalog/books/search`
GET `/catalog/books/popular`
GET `/catalog/books/latest`

Only books with status PUBLISHED and visibility PUBLIC are returned in the catalog.

## External Books

GET `/external-books`
GET `/external-books/{gutendexId}`
POST `/books/import/gutendex/{gutendexId}`

Importing a Gutendex book is available to any authenticated user. It must not be
restricted to ADMIN users.

External book search accepts optional query params:
- `search`
- `language`
- `topic`
- `page`

The frontend only calls Plumora API routes for external books. It never calls
Gutendex or Open Library directly.

External book DTOs should include:
- `imported`: whether this Gutendex book already exists in the Plumora catalog
- `internalBookId`: Plumora book id when `imported` is true

After importing a Gutendex book, the frontend reads it through:
GET `/books/{bookId}/read`

## Reading

GET `/books/{bookId}/read`
GET `/reading-progress/my`
GET `/books/{bookId}/reading-progress`
POST `/books/{bookId}/reading-progress`
PUT `/books/{bookId}/reading-progress`
PATCH `/books/{bookId}/reading-progress/finish`

`ReadingProgressResponse` is a flat DTO (`bookId`, `bookTitle`,
`bookCoverUrl`, ...) — no nested `book` object. The cover field is named
`bookCoverUrl`, not `coverUrl`; the Flutter client's
`ReadingProgressModel` must alias it or the "Lectures" tab silently
renders the gradient placeholder instead of the real cover (fixed
2026-07, was missing the alias).

## Favorites

POST `/books/{bookId}/favorites`
DELETE `/books/{bookId}/favorites`
GET `/favorites/my`
GET `/books/{bookId}/favorites/status`

`GET /favorites/my` returns a flat `FavoriteResponse[]` (`id`, `bookId`,
`bookTitle`, `bookCoverUrl`, `authorUsername`, `createdAt`) — no nested
`book` object either. Same `bookCoverUrl` naming as reading progress;
the Flutter client flattens this into a `CatalogBookModel`, so
`CatalogBookModel`'s cover alias list must also include `bookCoverUrl`
(fixed 2026-07, was missing the alias — the "Favoris" tab showed the
gradient placeholder for every book).

## Reviews

POST `/books/{bookId}/reviews`
GET `/books/{bookId}/reviews`
POST `/external-books/{gutendexId}/reviews`
GET `/external-books/{gutendexId}/reviews`
GET `/reviews/my`
PUT `/reviews/{reviewId}`
DELETE `/reviews/{reviewId}`

External book reviews use the same payload as internal book reviews:
`{ "rating": 1..5, "comment": "..." }`.
Creating a review for an external book must not require importing the book into
the Plumora catalog first.

## Beta-reading

Verified 2026-07 against the backend source (`plumora-api`, Spring Boot —
controllers, DTOs, entities, enums, service layer read directly). Access model:
**any user with role `BETA_READER` can read and comment on any campaign with
status `ACTIVE`** — invitations do not gate access, they are only an optional
targeted notification. Jackson uses plain camelCase field names (Java field
name as-is) everywhere in this module except `NotificationResponse`, which
uses `@JsonProperty` for `is_read`/`created_at`/`read_at` (snake_case).

Enums (exact constant names, no other values exist):
- `BetaCampaignStatus`: `ACTIVE`, `CLOSED`, `CANCELLED` (campaigns are
  `ACTIVE` immediately on creation; there is no `DRAFT`/`OPEN`).
- `BetaCommentFeedbackType`: `PLOT`, `CHARACTER`, `STYLE`, `PACING`,
  `CONTINUITY`, `TYPO`, `OTHER`.
- `BetaCommentPriority`: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.
- `BetaCommentStatus`: `OPEN`, `IN_PROGRESS`, `RESOLVED`, `IGNORED`.
- `BetaInvitationStatus`: `PENDING`, `ACCEPTED`, `REFUSED`.

POST `/books/{bookId}/beta-campaigns` — role `AUTHOR`
- Body (`CreateBetaCampaignRequest`): `{ "title": string (required, ≤150),
  "instructions"?: string (≤5000), "deadline"?: "YYYY-MM-DD" }`.
- Returns `BetaCampaignResponse`: `id`, `bookId`, `bookTitle`, `bookCoverUrl`,
  `authorId`, `authorUsername`, `title`, `instructions`, `deadline`, `status`,
  `createdAt`, `closedAt`. Every user with role `BETA_READER` (except the
  author) is sent a `BETA_CAMPAIGN_OPEN` notification when this succeeds.
- **Book status side effect (fixed 2026-07):** creating a campaign now
  transitions the book's own `status` to `IN_BETA_READING`
  (`BookService.startBetaReading`). Verified end-to-end with the Flutter
  app: "Mes histoires" already had the `IN_BETA_READING` status chip, the
  "Bêta-test" filter tab, and the "Retours" action button fully wired
  (`author_dashboard_screen.dart`) and already refetches `GET
  /books/my-books` right after a successful campaign creation, so this
  required no client changes.

GET `/books/{bookId}/beta-campaigns` — role `AUTHOR`
- Returns `BetaCampaignResponse[]` for that book (all statuses).

GET `/beta-campaigns` — role `BETA_READER`
- **New endpoint.** No params. Returns `BetaCampaignResponse[]` filtered to
  `status == ACTIVE` only, ordered by `createdAt` descending. Same DTO shape
  as above (includes `bookCoverUrl`/`authorUsername`) — no chapter-count
  field exists on this DTO. **`engagedByMe`** (bool, added 2026-07): true if
  the current beta-reader has either commented on or opened a shared chapter
  of that campaign — computed server-side in one grouped query (no N+1).

GET `/beta-campaigns/{campaignId}` — role `AUTHOR` or `BETA_READER`
- Returns one `BetaCampaignResponse`.

PATCH `/beta-campaigns/{campaignId}/close` — role `AUTHOR`
PATCH `/beta-campaigns/{campaignId}/cancel` — role `AUTHOR`
- No body. Sets `status` to `CLOSED`/`CANCELLED` and `closedAt` to now. Both
  require the campaign to currently be `ACTIVE`, else 400
  `"Only active beta-reading campaigns can be modified"`.
- **Book status side effect (2026-07):** `close` moves the book's own
  `status` to `IN_CORRECTION` (`BookService.completeBetaReading` — the
  author is expected to act on the feedback before republishing); `cancel`
  reverts it to `DRAFT` (`BookService.cancelBetaReading`). On the Flutter
  side both land the book back in the "En cours" tab (already matches
  `draft`/`inCorrection`) with the generic "Brouillon" chip and
  "Chapitres"/"Écrire" actions — no distinct "En correction" chip exists
  yet, that would be a cosmetic follow-up only, not a blocker.

POST `/beta-campaigns/{campaignId}/invitations` — role `AUTHOR`
- Body (`CreateBetaInvitationRequest`): `{ "betaReaderId": UUID }` — **required,
  no email alternative.** Purely a targeted notification; has no effect on
  who can already access the campaign.
- Returns `BetaInvitationResponse`.

GET `/beta-campaigns/{campaignId}/invitations` — role `AUTHOR`
- Returns `BetaInvitationResponse[]` for that campaign.

GET `/beta-invitations/my-invitations` — role `BETA_READER`
- Returns `BetaInvitationResponse[]`: `id`, `campaignId`, `campaignTitle`,
  `bookId`, `bookTitle`, `bookCoverUrl`, `betaReaderId`, `betaReaderUsername`,
  `status`, `invitedAt`, `respondedAt`. **No author field, no chapter/feedback
  count field** — those must not be assumed present.

PATCH `/beta-invitations/{invitationId}/accept` — role `BETA_READER`
PATCH `/beta-invitations/{invitationId}/refuse` — role `BETA_READER`
- No body. Flips `status`/`respondedAt` only — does not grant or revoke
  campaign access.

GET `/beta-campaigns/{campaignId}/chapters` — role `AUTHOR` or `BETA_READER`
- Returns `BetaSharedChapterResponse[]`: `id`, `title`, `content`,
  `chapterOrder`, `wordCount`. **No `bookId`, no comment count** on this DTO.

PUT `/beta-campaigns/{campaignId}/chapters` — role `AUTHOR`
- Body (`UpdateSharedChaptersRequest`): `{ "chapterIds": UUID[] }` (required,
  each id required). Returns `BetaSharedChapterResponse[]`.

POST `/beta-campaigns/{campaignId}/chapters/{chapterId}/views` — role
`BETA_READER` — **new endpoint (2026-07)**
- No body, no response body. Idempotent (safe to call repeatedly for the
  same chapter). Refuses (400) if the chapter isn't shared on this campaign.
  Records that the current beta-reader opened this chapter; feeds
  `engagedByMe` on `GET /beta-campaigns` alongside comments. Client calls
  this once per chapter view (cached client-side, not re-sent on repeat
  navigation within the same app session).

POST `/beta-comments` — role `BETA_READER`
- Body (`CreateBetaCommentRequest`): `{ "campaignId": UUID, "chapterId": UUID,
  "commentText": string (required, ≤5000), "selectedText"?: string (≤2000),
  "positionStart"?: int (≥0), "positionEnd"?: int (≥0), "feedbackType":
  <enum> (required), "priority": <enum> (required) }`. No `bookId` field.
  400 if `positionStart > positionEnd`
  (`"positionStart must be less than or equal to positionEnd"`); 400 if the
  campaign isn't `ACTIVE`
  (`"Beta comments can only be added to active beta-reading campaigns"`); 400
  if the chapter isn't shared on this campaign
  (`"Beta comments can only target shared chapters"`) or doesn't belong to
  the campaign's book (`"Commented chapter must belong to the campaign book"`).
- Returns `BetaCommentResponse`: `id`, `campaignId`, `campaignTitle`,
  `bookId`, `bookTitle`, `bookCoverUrl`, `chapterId`, `chapterTitle`,
  `betaReaderId`, `betaReaderUsername`, `commentText`, `selectedText`,
  `positionStart`, `positionEnd`, `feedbackType`, `priority`, `status`,
  `createdAt`, `updatedAt`.

GET `/beta-campaigns/{campaignId}/comments` — role `AUTHOR` or `BETA_READER`
- Author sees every comment on the campaign; a beta reader sees **only their
  own** comments on it (server-side filtered, not a client concern).

GET `/books/{bookId}/beta-comments` — role `AUTHOR`
GET `/chapters/{chapterId}/beta-comments` — role `AUTHOR` or `BETA_READER`
- Return `BetaCommentResponse[]`, same shape as above.

PATCH `/beta-comments/{commentId}/status` — role `AUTHOR`
- Body (`UpdateBetaCommentStatusRequest`): `{ "status": <BetaCommentStatus> }`.
  Restricted to the book's author.

DELETE `/beta-comments/{commentId}` — role `BETA_READER`
- Restricted to the comment's own author. Returns 204, no body.

## AI

Verified 2026-07 against the backend source (`plumora-api`). Two distinct,
coexisting surfaces share the `/ai` prefix — a persisted one (history kept
server-side) and a stateless one branded **"Plumo IA"** (each call stands
alone, nothing is stored). JSON is snake_case wherever the backend record
uses `@JsonProperty`; unannotated single-word fields (`text`, `language`,
`tone`, `title`, `reason`, `score`, `provider`, `model`...) are plain
camelCase — same casing either way for those.

### Persisted (Mukeme-era) writing suggestions and recommendations

POST `/ai/writing/suggestions` — role `AUTHOR`
- Body: `{ "chapter_id": UUID (required), "selected_text": string (required,
  ≤5000), "context_text"?: string (≤10000), "action_type": <enum> (required)
  }`. `AiWritingActionType`: `REFORMULATE`, `IMPROVE_STYLE`,
  `FIX_REPETITIONS`, `MAKE_MORE_EMOTIONAL`, `MAKE_DIALOGUE_NATURAL`.
GET `/ai/writing/requests` — role `AUTHOR`
GET `/ai/writing/requests/{requestId}` — role `AUTHOR`
PATCH `/ai/writing/suggestions/{suggestionId}/accept` — role `AUTHOR`, no body
PATCH `/ai/writing/suggestions/{suggestionId}/modify` — role `AUTHOR`
- **No request body param on the backend side** — this only flips `status`
  to `MODIFIED`; it does not persist an edited suggestion text. Any body the
  client sends here is ignored server-side.
PATCH `/ai/writing/suggestions/{suggestionId}/ignore` — role `AUTHOR`, no body

POST `/ai/recommendations/books` — role `READER`
- Body: `{ "query_text": string (required, ≤2000), "mood"?: string (≤40),
  "preferred_duration"?: string (≤30), "preferred_genre"?: string (≤80) }`.
  Response includes `recommendations: RecommendedBookResponse[]` — each item
  is flat: `book_id`, `title`, `coverUrl`, `match_score`, `reasons: string[]`,
  `rank_position`. **No author/genre/rating/read-count field** on this DTO.
GET `/ai/recommendations/my-requests` — role `READER`
GET `/ai/recommendations/requests/{requestId}` — role `READER`

### Plumo IA (stateless, Gemini-backed)

The Flutter app never calls Gemini directly — every request goes through
these Plumora API endpoints, which hold the Gemini key server-side (falls
back to a deterministic mock provider unless `AI_PROVIDER=gemini` is set,
so these work with no Gemini key configured). Each call is independent; the
backend keeps no suggestion history for these six endpoints, unlike the
Mukeme-era ones above. All six share an in-memory rate limit: 20 requests /
5 minutes per user, reset on server restart.

POST `/ai/writing/rewrite` — role `AUTHOR`
POST `/ai/writing/summarize` — role `AUTHOR`
POST `/ai/writing/continue` — role `AUTHOR`
- Body (`AiTextGenerationRequest`, all three endpoints): `{ "text": string
  (required, ≤20000), "language"?: string (≤10), "tone"?: string (≤50),
  "instruction"?: string (≤2000), "manuscript_id"?: UUID, "chapter_id"?: UUID
  }`. `manuscript_id`/`chapter_id` are optional — these three can be called
  with no book context at all.
- Response (`AiTextGenerationResponse`): `{ "suggestion", "explanation",
  "warnings": string[], "provider", "model", "generated_at" }`.

POST `/ai/writing/titles` — role `AUTHOR`
- Same request body shape as rewrite/summarize/continue.
- Response (`AiTitleSuggestionResponse`): `{ "titles": string[],
  "explanation", "warnings": string[], "provider", "model", "generated_at"
  }`.

POST `/ai/beta-reading/analyze` — role `AUTHOR`
- Author-facing only (not beta-reader-facing): lets an author have Plumo
  pre-analyze their own manuscript/chapter before sending it to real beta
  readers. Requires ownership of the `chapter_id`/`manuscript_id` passed in,
  else 403 (`AiUnauthorizedAccessException`).
- Body (`AiBetaReadingAnalysisRequest`): `{ "text": string (required,
  ≤20000), "language"?: string (≤10), "genre"?: string (≤80),
  "expected_feedback_level"?: string (≤30), "manuscript_id"?: UUID,
  "chapter_id"?: UUID }`.
- Response (`AiBetaReadingAnalysisResponse`): `{ "global_feedback",
  "strengths": string[], "weaknesses": string[], "clarity_score": int (0-10),
  "rhythm_score": int, "coherence_score": int, "character_score": int,
  "suggestions": string[], "warnings": string[], "provider", "model",
  "generated_at" }`.

POST `/ai/books/recommend` — role `READER`
- Body (`AiBookRecommendationRequest`): `{ "user_preferences"?: string
  (≤1000), "favorite_genres"?: string[] (each ≤80), "reading_history_ids"?:
  UUID[] (excluded from candidates, not used for scoring), "language"?:
  string (≤10), "limit"?: int (1-20, default 10) }`.
- Response (`AiBookRecommendationResponse`): `{ "recommendations":
  AiBookRecommendationItem[], "provider", "model", "generated_at" }`. Each
  item is flat: `{ "book_id", "title", "reason", "score" }` — no cover/author,
  the client re-fetches those via `GET /catalog/books/{bookId}` per item.
- Gemini is instructed to only rank existing Plumora books, never invent
  ones; the client still defensively drops any recommendation whose
  `book_id` the catalog can't resolve rather than render a broken card.

Error mapping relevant to all Plumo IA endpoints (`GlobalExceptionHandler`):
403 for `AiUnauthorizedAccessException`/`AccessDeniedException`; 400 for
input-too-large/usage-limit/validation failures; 503 for
`AiConfigurationException`/`AiProviderUnavailableException`/
`AiInvalidResponseException` (Gemini misconfigured, unreachable, or returned
unparseable JSON).

## Reports (signalements)

**Documenté 2026-07 : les routes de modération (`/admin/reports/**`,
`/reports/{id}/status`) étaient déjà consommées par
`admin_reports_screen.dart` mais n'étaient pas documentées ici — cet
écart est comblé en même temps que l'ajout de la création côté
lecteur.** Statuts (déjà en usage, non renommés) : `OPEN`, `IN_REVIEW`,
`RESOLVED`, `DISMISSED`.

POST `/books/{bookId}/reports` — utilisateur authentifié (tout rôle)
- **Nouvelle route, proposée par le frontend** — à confirmer côté
  backend, aucun test ni doc préexistante ne la référençait. Suit le
  même gabarit que `POST /books/{bookId}/reviews` /
  `POST /books/{bookId}/favorites`.
- Body : `{ "reason": <enum ci-dessous, requis>, "description"?: string
  (≤1000 caractères ; requis si `reason` = `OTHER`, sinon facultatif) }`.
- Réponse attendue (`ReportResponse`) : `{ "id", "bookId", "reason",
  "description", "status": "OPEN", "createdAt" }` — statut initial
  toujours `OPEN`.
- Motifs proposés (aucun enum existant trouvé côté frontend — colonne
  `reason VARCHAR(100) NOT NULL` sans `CHECK` documenté dans
  `docs/data-model.md`, donc compatible en chaîne libre) :
  `INAPPROPRIATE_CONTENT`, `HARASSMENT`, `HATE_SPEECH`, `PLAGIARISM`,
  `COPYRIGHT`, `MISLEADING_INFORMATION`, `OTHER`.
- Codes d'erreur attendus côté client : 401 (non authentifié), 404
  (livre introuvable), 409 (signalement déjà `OPEN` du même lecteur
  sur ce livre — règle *suggérée*, pas confirmée côté backend), 400
  (validation).

GET `/admin/reports` — role `ADMIN`
- Retourne la liste des signalements (tous statuts).

GET `/admin/reports/{id}` — role `ADMIN`
- Détail d'un signalement (méthode client existante, actuellement
  inutilisée par l'écran de modération).

PATCH `/admin/reports/{id}/resolve` — role `ADMIN`
PATCH `/admin/reports/{id}/reject` — role `ADMIN`
- Body optionnel : `{ "reason"?: string }`.

PATCH `/reports/{id}/status` — role `ADMIN` (hors préfixe `/admin/**`
mais réservée ADMIN côté serveur)
- Body : `{ "status": "IN_REVIEW" }` — seule transition couverte par
  cette route générique ; `resolve`/`reject` ci-dessus couvrent les
  deux autres.

## Notifications

GET `/notifications/my`
GET `/notifications/unread-count`
PATCH `/notifications/{notificationId}/read`
PATCH `/notifications/read-all`
