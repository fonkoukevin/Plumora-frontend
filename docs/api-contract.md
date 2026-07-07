# Plumora API Contract

Base URL:
`/api/v1`

## Auth

POST `/auth/register`
POST `/auth/login`
POST `/auth/google`
GET `/auth/me`
GET `/users/me`
PUT `/users/me/roles`

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

POST `/books/{bookId}/beta-campaigns`
GET `/books/{bookId}/beta-campaigns`
GET `/beta-campaigns/{campaignId}`
PATCH `/beta-campaigns/{campaignId}/close`

POST `/beta-campaigns/{campaignId}/invitations`
GET `/beta-invitations/my-invitations`
PATCH `/beta-invitations/{invitationId}/accept`
PATCH `/beta-invitations/{invitationId}/refuse`

GET `/beta-campaigns/{campaignId}/chapters`
PUT `/beta-campaigns/{campaignId}/chapters`

POST `/beta-comments`
GET `/books/{bookId}/beta-comments`
GET `/beta-campaigns/{campaignId}/comments`
PATCH `/beta-comments/{commentId}/status`

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
