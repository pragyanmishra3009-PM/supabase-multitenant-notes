-- RLS test script. Run in the Supabase SQL Editor. It cleans up after itself.
-- Result: one row per check, PASS or FAIL.

create temp table if not exists test_results (n int, check_name text, expected text, actual text, result text);
truncate test_results;
grant all on test_results to authenticated;

do $$
declare
  a uuid := 'fd7e3757-5965-45aa-b13f-0b8bc068d81d';
  b uuid := 'f234a31d-73e8-4c76-a168-94240d3d6524';
  g uuid := '200d464f-08dc-4196-84a3-4379b69135d5';
  org_a uuid := gen_random_uuid();
  org_b uuid := gen_random_uuid();
  cnt int;
  note_id uuid;
begin
  delete from public.organizations where name in ('A-Co','B-Co');

  -- 1. A creates an organization and an owner membership appears
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.organizations(id, name) values (org_a, 'A-Co');
    select count(*) into cnt from public.memberships where org_id = org_a and role = 'owner';
    insert into test_results values (1, 'A creates org and becomes owner', '1 owner membership', cnt || ' owner membership', case when cnt = 1 then 'PASS' else 'FAIL' end);
  exception when others then
    insert into test_results values (1, 'A creates org and becomes owner', 'success', sqlerrm, 'FAIL');
  end;
  -- 2. A inserts a note into A-Co
  begin
    insert into public.notes(org_id, content) values (org_a, 'A note') returning id into note_id;
    insert into test_results values (2, 'A inserts a note in A-Co', 'allowed', 'allowed', 'PASS');
  exception when others then
    insert into test_results values (2, 'A inserts a note in A-Co', 'allowed', sqlerrm, 'FAIL');
  end;
  reset role;

  -- 3. B creates own org
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role','authenticated')::text, true);
  set local role authenticated;
  begin
    insert into public.organizations(id, name) values (org_b, 'B-Co');
    insert into test_results values (3, 'B creates B-Co', 'allowed', 'allowed', 'PASS');
  exception when others then
    insert into test_results values (3, 'B creates B-Co', 'allowed', sqlerrm, 'FAIL');
  end;
  -- 4. B cannot see A's notes
  select count(*) into cnt from public.notes where org_id = org_a;
  insert into test_results values (4, 'B reads A-Co notes', '0 rows', cnt || ' rows', case when cnt = 0 then 'PASS' else 'FAIL' end);
  -- 5. B cannot insert into A-Co
  begin
    insert into public.notes(org_id, content) values (org_a, 'B intrusion');
    insert into test_results values (5, 'B inserts note into A-Co', 'blocked', 'allowed', 'FAIL');
  exception when others then
    insert into test_results values (5, 'B inserts note into A-Co', 'blocked', 'blocked', 'PASS');
  end;
  reset role;

  -- 6. Add agent G as viewer in A-Co (done by admin, bypasses RLS)
  insert into public.memberships(org_id, user_id, role) values (org_a, g, 'viewer');

  perform set_config('request.jwt.claims', json_build_object('sub', g, 'role','authenticated')::text, true);
  set local role authenticated;
  -- 7. Agent reads A-Co notes
  select count(*) into cnt from public.notes where org_id = org_a;
  insert into test_results values (7, 'Agent reads A-Co notes', '1 row', cnt || ' rows', case when cnt = 1 then 'PASS' else 'FAIL' end);
  -- 8. Agent cannot write
  begin
    insert into public.notes(org_id, content) values (org_a, 'agent write');
    insert into test_results values (8, 'Agent writes note in A-Co', 'blocked', 'allowed', 'FAIL');
  exception when others then
    insert into test_results values (8, 'Agent writes note in A-Co', 'blocked', 'blocked', 'PASS');
  end;
  -- 9. Agent cannot see B-Co notes (or org)
  select count(*) into cnt from public.organizations where id = org_b;
  insert into test_results values (9, 'Agent sees B-Co organization', '0 rows', cnt || ' rows', case when cnt = 0 then 'PASS' else 'FAIL' end);
  -- 10. Agent cannot update A's note
  update public.notes set content = 'tampered' where id = note_id;
  get diagnostics cnt = row_count;
  insert into test_results values (10, 'Agent updates A''s note', '0 rows changed', cnt || ' rows changed', case when cnt = 0 then 'PASS' else 'FAIL' end);
  reset role;

  delete from public.organizations where name in ('A-Co','B-Co');
end $$;

select * from test_results order by n;
