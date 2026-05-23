# Plumora API Contract

Base URL:
`/api/v1`

## Auth

POST `/auth/register`
POST `/auth/login`
GET `/auth/me`

## Books

POST `/books`
GET `/books/my-books`
GET `/books/{bookId}`
PUT `/books/{bookId}`
PATCH `/books/{bookId}/publish`
PATCH `/books/{bookId}/archive`

Book create/update payloads may be sent as JSON or as `multipart/form-data`.
When a user imports a cover image, the frontend sends:
- text fields: `title`, `description`, `genre`, `visibility`
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
GET `/reviews/my`
PUT `/reviews/{reviewId}`
DELETE `/reviews/{reviewId}`

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
