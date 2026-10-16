-- Fix: let a creator read back the organization they just created
-- (the owner membership is added by a trigger only after the insert).
drop policy if exists "members read their orgs" on public.organizations;
create policy "members read their orgs" on public.organizations
  for select to authenticated
  using (public.is_member(id) or created_by = (select auth.uid()));
