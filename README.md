# Supabase multi-tenant notes (Auth + row-level security)

A small project I built to learn Supabase Auth and Postgres row-level security (RLS) hands-on.
Each organization's notes are visible only to its members. A `viewer` role gives
read-only access and models a scoped, least-privilege credential for an AI agent.

## What it covers
- Supabase Auth (email sign-in)
- Multi-tenant data isolation with RLS: `organizations`, `memberships`, `notes`
- Roles: `owner`, `member` (read/write), `viewer` (read-only)
- A read-only "agent" user that can read one organization's notes but cannot write

## Setup
1. Create a free project at supabase.com.
2. In the SQL editor, run `schema.sql`, then `fix_org_policy.sql` if you used an older copy of the schema.
3. In Authentication, enable Email and create three test users (A, B and an agent).
4. Put the three user IDs into `run_tests.sql` and run it.

## Verifying isolation
`run_tests.sql` runs 9 checks as different users: cross-tenant reads and writes must be blocked, and the viewer-role agent can read but not write. All 9 pass. `tests.md` lists the same checks to run by hand.

## What I learned
My first policy blocked creating an organization and reading it back, because the owner membership is added by a trigger after the insert. I fixed it by letting the creator read their own organization.
