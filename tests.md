# RLS test checklist (run as each user, via the Supabase client or SQL with `set role authenticated` and a JWT)

Setup: users A and B (separate orgs), agent user G (viewer in A's org).

| # | As | Action | Expected |
|---|----|--------|----------|
| 1 | A | create org "A-Co" | succeeds; A is owner |
| 2 | B | create org "B-Co" | succeeds; B is owner |
| 3 | A | insert note in A-Co | succeeds |
| 4 | B | select notes | returns none of A-Co's notes |
| 5 | B | insert note with A-Co's org_id | fails (RLS) |
| 6 | A | add G to A-Co as `viewer` (insert into memberships as service role) | succeeds |
| 7 | G | select notes of A-Co | returns A-Co's notes |
| 8 | G | insert note in A-Co | fails (viewer cannot write) |
| 9 | G | select notes of B-Co | returns none |
| 10 | A | update a note written by someone else | fails |

Break it on purpose: remove `with check` from the insert policy and re-run #5. Note what happens.
