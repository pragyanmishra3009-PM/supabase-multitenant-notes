# Supabase multi-tenant notes (Auth + row-level security)

A small project to learn Supabase Auth and Postgres row-level security (RLS) hands-on.
Each organization's notes are visible only to its members. A `viewer` role gives
read-only access, used to model a scoped, least-privilege agent credential.

## What it covers
- Supabase Auth (email, plus Google sign-in if you enable it)
- Multi-tenant data isolation with RLS: `organizations`, `memberships`, `notes`
- Roles: `owner`, `member` (read/write), `viewer` (read-only)
- A read-only "agent" user that can read one organization's notes but cannot write

## Setup
1. Create a free project at supabase.com.
2. Open the SQL editor and run `schema.sql`.
3. In Authentication, enable Email (and Google if you like).
4. Create two users in different organizations and one agent user (see `tests.md`).

## Verify isolation
Follow `tests.md`. Every expected result there should hold before you rely on this.

## What I learned
_Fill this in after you build it: what failed, what surprised you, what you'd change._
