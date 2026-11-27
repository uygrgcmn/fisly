create extension if not exists pgtap with schema extensions;

begin;

select plan(8);

insert into auth.users (
  id,
  aud,
  role,
  email,
  email_confirmed_at
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    'authenticated',
    'authenticated',
    'fisly-rls-a@example.invalid',
    now()
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    'authenticated',
    'authenticated',
    'fisly-rls-b@example.invalid',
    now()
  );

insert into public.categories (id, user_id, name, is_default)
values
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '11111111-1111-4111-8111-111111111111',
    'Food A',
    true
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '22222222-2222-4222-8222-222222222222',
    'Food B',
    true
  );

insert into public.recurring_expenses (
  id,
  user_id,
  merchant,
  amount_minor_units,
  category_id
)
values
  (
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    '11111111-1111-4111-8111-111111111111',
    'Streaming A',
    1000,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ),
  (
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    '22222222-2222-4222-8222-222222222222',
    'Streaming B',
    1000,
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
  );

insert into public.monthly_budgets (user_id, limit_minor_units)
values
  ('11111111-1111-4111-8111-111111111111', 100000),
  ('22222222-2222-4222-8222-222222222222', 100000);

insert into public.expenses (
  id,
  user_id,
  merchant,
  amount_minor_units,
  occurred_at,
  category_id,
  recurring_expense_id
)
values
  (
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    '11111111-1111-4111-8111-111111111111',
    'Cafe A',
    2500,
    now(),
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  ),
  (
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '22222222-2222-4222-8222-222222222222',
    'Cafe B',
    2500,
    now(),
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-4111-8111-111111111111',
  true
);

select is(
  (select count(*)::integer from public.categories),
  1,
  'a user sees only their categories'
);
select is(
  (select count(*)::integer from public.expenses),
  1,
  'a user sees only their expenses'
);
select is(
  (select count(*)::integer from public.recurring_expenses),
  1,
  'a user sees only their recurring expenses'
);
select is(
  (select count(*)::integer from public.monthly_budgets),
  1,
  'a user sees only their monthly budget'
);

select throws_ok(
  $$
    insert into public.expenses (
      user_id,
      merchant,
      amount_minor_units,
      occurred_at
    )
    values (
      '22222222-2222-4222-8222-222222222222',
      'Other user expense',
      100,
      now()
    )
  $$,
  '42501',
  null,
  'a user cannot create an expense for another user'
);

select throws_ok(
  $$
    insert into public.expenses (
      user_id,
      merchant,
      amount_minor_units,
      occurred_at,
      category_id
    )
    values (
      '11111111-1111-4111-8111-111111111111',
      'Cross-user category',
      100,
      now(),
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
    )
  $$,
  '42501',
  null,
  'a user cannot attach another user category'
);

select lives_ok(
  $$
    insert into public.expenses (
      user_id,
      merchant,
      amount_minor_units,
      occurred_at,
      category_id
    )
    values (
      '11111111-1111-4111-8111-111111111111',
      'Own expense',
      100,
      now(),
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
    )
  $$,
  'a user can create their own expense'
);

update public.expenses
set merchant = 'Modified by user A'
where id = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

reset role;

select is(
  (
    select merchant
    from public.expenses
    where id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
  ),
  'Cafe B',
  'a user cannot update another user expense'
);

select * from finish();
rollback;
