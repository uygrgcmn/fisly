create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 80),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index categories_user_name_unique
  on public.categories (user_id, lower(name));
create index categories_user_id_idx on public.categories (user_id);

create table public.recurring_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  merchant text not null check (length(trim(merchant)) > 0),
  amount_minor_units bigint not null check (amount_minor_units > 0),
  category_id uuid references public.categories (id) on delete set null,
  note text,
  is_active boolean not null default true,
  last_paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index recurring_expenses_user_id_idx
  on public.recurring_expenses (user_id);

create table public.monthly_budgets (
  user_id uuid primary key references auth.users (id) on delete cascade,
  limit_minor_units bigint not null check (limit_minor_units > 0),
  updated_at timestamptz not null default now()
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  merchant text not null check (length(trim(merchant)) > 0),
  amount_minor_units bigint not null check (amount_minor_units > 0),
  currency_code text not null default 'TRY'
    check (currency_code ~ '^[A-Z]{3}$'),
  occurred_at timestamptz not null,
  category_id uuid references public.categories (id) on delete set null,
  note text,
  recurring_expense_id uuid
    references public.recurring_expenses (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index expenses_user_occurred_at_idx
  on public.expenses (user_id, occurred_at desc);

alter table public.categories enable row level security;
alter table public.recurring_expenses enable row level security;
alter table public.monthly_budgets enable row level security;
alter table public.expenses enable row level security;

create policy "Users can read their categories"
  on public.categories for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can create their categories"
  on public.categories for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "Users can update their custom categories"
  on public.categories for update to authenticated
  using (user_id = (select auth.uid()) and not is_default)
  with check (user_id = (select auth.uid()) and not is_default);

create policy "Users can delete their custom categories"
  on public.categories for delete to authenticated
  using (user_id = (select auth.uid()) and not is_default);

create policy "Users can read their recurring expenses"
  on public.recurring_expenses for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can create their recurring expenses"
  on public.recurring_expenses for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (
      category_id is null
      or exists (
        select 1
        from public.categories as category
        where category.id = recurring_expenses.category_id
          and category.user_id = (select auth.uid())
      )
    )
  );

create policy "Users can update their recurring expenses"
  on public.recurring_expenses for update to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (
      category_id is null
      or exists (
        select 1
        from public.categories as category
        where category.id = recurring_expenses.category_id
          and category.user_id = (select auth.uid())
      )
    )
  );

create policy "Users can delete their recurring expenses"
  on public.recurring_expenses for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can read their monthly budgets"
  on public.monthly_budgets for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can create their monthly budgets"
  on public.monthly_budgets for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "Users can update their monthly budgets"
  on public.monthly_budgets for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "Users can delete their monthly budgets"
  on public.monthly_budgets for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can read their expenses"
  on public.expenses for select to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can create their expenses"
  on public.expenses for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and (
      category_id is null
      or exists (
        select 1
        from public.categories as category
        where category.id = expenses.category_id
          and category.user_id = (select auth.uid())
      )
    )
    and (
      recurring_expense_id is null
      or exists (
        select 1
        from public.recurring_expenses as recurring
        where recurring.id = expenses.recurring_expense_id
          and recurring.user_id = (select auth.uid())
      )
    )
  );

create policy "Users can update their expenses"
  on public.expenses for update to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and (
      category_id is null
      or exists (
        select 1
        from public.categories as category
        where category.id = expenses.category_id
          and category.user_id = (select auth.uid())
      )
    )
    and (
      recurring_expense_id is null
      or exists (
        select 1
        from public.recurring_expenses as recurring
        where recurring.id = expenses.recurring_expense_id
          and recurring.user_id = (select auth.uid())
      )
    )
  );

create policy "Users can delete their expenses"
  on public.expenses for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.categories from anon;
revoke all on public.recurring_expenses from anon;
revoke all on public.monthly_budgets from anon;
revoke all on public.expenses from anon;

grant select, insert, update, delete
  on public.categories, public.recurring_expenses,
     public.monthly_budgets, public.expenses
  to authenticated;
