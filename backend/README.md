# Backend (Express + Prisma)

This backend powers the Flutter app via a REST API.

## Local DB (no Docker)

Because Docker Desktop/daemon can be unreliable on some Windows setups, this project defaults to a local SQLite database.

- DB file: `backend/dev.db`
- API port: `3001` (configured in `backend/.env`)

## Setup

From the `backend/` folder:

- `npm install`
- `npm run prisma:generate`
- `npm run prisma:migrate`
- `npm run db:seed`

Demo login:

- username: `demo@svu.com`
- password: `password123`

## Run

Recommended (detached, keeps running and writes logs):

- `./scripts/start-backend.ps1`

Stop it:

- `./scripts/stop-backend.ps1`

Health check:

- `curl.exe http://localhost:3001/health`

## Prisma schemas

- SQLite (default for local dev): `prisma/schema.local.prisma`
- Postgres (for later, if Docker works): `prisma/schema.prisma`

If you switch to Postgres later, also update `DATABASE_URL` in `backend/.env` and use the `*:pg` npm scripts.
