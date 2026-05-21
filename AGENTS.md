À mettre dans ton repo **plumora-frontend**.

```md
# AGENTS.md — Plumora Frontend

## Project overview

Plumora is a multi-platform Flutter application for writing, beta-reading, publishing, reading and sharing digital books.

The Flutter app targets:
- mobile
- desktop
- possible future web version

The backend is a Spring Boot REST API exposed under:
`/api/v1`

The app must connect to the backend through HTTP REST calls.

## Product positioning

Plumora is not only a reading app.

It includes:
- author space for writing and managing manuscripts
- reader space for discovering and reading books
- beta-reader space integrated into the library
- Mukeme AI assistant for writing help
- Mukeme AI assistant for book recommendations

## MVP scope

Implement:
- authentication screens
- role selection
- global home dashboard
- author dashboard
- book creation
- chapter editor
- publish book action
- catalog
- book detail
- reading screen
- favorites
- reviews
- beta-reading invitations
- beta-reading comments
- Mukeme writing assistant UI
- Mukeme recommendation UI
- notifications

Do NOT implement yet:
- payment
- real royalties
- subscription
- admin publication validation
- chat
- marketplace

## Frontend architecture

Use feature-first architecture.

Recommended structure:

```text
lib/
├── core/
│   ├── network/
│   ├── routing/
│   ├── theme/
│   ├── storage/
│   ├── errors/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── user/
│   ├── book/
│   ├── writing/
│   ├── beta_reading/
│   ├── reading/
│   ├── catalog/
│   ├── ai/
│   ├── notification/
│   └── profile/
│
└── main.dart

