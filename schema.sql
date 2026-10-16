-- Multi-tenant notes on Supabase: schema + row-level security.
-- Run in the Supabase SQL editor (or as a migration).

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.memberships (
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member','viewer')),
  primary key (org_id, user_id)
);

create table public.notes (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  author_id uuid not null default auth.uid() references auth.users(id),
  content text not null,
  created_at timestamptz not null default now()
);

create index on public.memberships (user_id);
create index on public.notes (org_id);

-- Helper functions. SECURITY DEFINER so policies on memberships don't recurse.
create function public.is_member(_org uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.memberships
                 where org_id = _org and user_id = (select auth.uid()));
$$;

create function public.can_write(_org uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.memberships
                 where org_id = _org and user_id = (select auth.uid())
                   and role in ('owner','member'));
$$;

-- Creator becomes the owner of a new organization.
create function public.add_owner_membership()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.memberships (org_id, user_id, role)
  values (new.id, new.created_by, 'owner');
  return new;
end $$;

create trigger on_org_created after insert on public.organizations
for each row execute function public.add_owner_membership();

-- Row-level security
alter table public.organizations enable row level security;
alter table public.memberships  enable row level security;
alter table public.notes        enable row level security;

create policy "members read their orgs" on public.organizations
  for select to authenticated
  using (public.is_member(id) or created_by = (select auth.uid()));
create policy "users create orgs" on public.organizations
  for insert to authenticated with check (created_by = (select auth.uid()));

create policy "users see their own memberships" on public.memberships
  for select to authenticated using (user_id = (select auth.uid()));

create policy "members read org notes" on public.notes
  for select to authenticated using (public.is_member(org_id));
create policy "writers insert org notes" on public.notes
  for insert to authenticated
  with check (public.can_write(org_id) and author_id = (select auth.uid()));
create policy "authors update own notes" on public.notes
  for update to authenticated
  using (author_id = (select auth.uid()) and public.can_write(org_id))
  with check (author_id = (select auth.uid()) and public.can_write(org_id));
create policy "authors delete own notes" on public.notes
  for delete to authenticated
  using (author_id = (select auth.uid()) and public.can_write(org_id));
