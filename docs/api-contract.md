# Plumora API Contract

Base URL:
`/api/v1`

## Auth

POST `/auth/register`
POST `/auth/login`
POST `/auth/google`
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

## Favorites

POST `/books/{bookId}/favorites`
DELETE `/books/{bookId}/favorites`
GET `/favorites/my`
GET `/books/{bookId}/favorites/status`

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

POST `/ai/writing/suggestions`
PATCH `/ai/writing/suggestions/{suggestionId}/accept`
PATCH `/ai/writing/suggestions/{suggestionId}/modify`
PATCH `/ai/writing/suggestions/{suggestionId}/ignore`

POST `/ai/recommendations/books`
GET `/ai/recommendations/my-requests`

## Notifications

GET `/notifications/my`
GET `/notifications/unread-count`
PATCH `/notifications/{notificationId}/read`
PATCH `/notifications/read-all`
