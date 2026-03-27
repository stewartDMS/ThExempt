-- Phase 4: Financial Tools & Wealth Building
-- Migration 008

-- ──────────────────────────────────────────────────────────────────────────
-- membership_tiers
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists membership_tiers (
  id           uuid primary key default gen_random_uuid(),
  name         text unique not null,
  slug         text unique not null,
  price_monthly  numeric(10,2) default 0,
  price_annual   numeric(10,2) default 0,
  description  text,
  features     jsonb default '[]',
  badge_color  text default '#0A66C2',
  is_active    boolean default true,
  sort_order   integer default 0,
  created_at   timestamptz default now()
);

-- ──────────────────────────────────────────────────────────────────────────
-- user_memberships
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists user_memberships (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles(id) on delete cascade,
  tier_id     uuid not null references membership_tiers(id) on delete restrict,
  status      text not null default 'active'
                check (status in ('active','cancelled','expired')),
  started_at  timestamptz default now(),
  expires_at  timestamptz,
  created_at  timestamptz default now(),
  unique (user_id)
);

create index if not exists idx_user_memberships_user_id on user_memberships(user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- credit_balances
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists credit_balances (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles(id) on delete cascade unique,
  balance    integer not null default 0 check (balance >= 0),
  updated_at timestamptz default now()
);

create index if not exists idx_credit_balances_user_id on credit_balances(user_id);

-- ──────────────────────────────────────────────────────────────────────────
-- credit_transactions
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists credit_transactions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references profiles(id) on delete cascade,
  amount           integer not null,
  transaction_type text not null
                     check (transaction_type in (
                       'earn','spend','purchase','refund',
                       'invest','receive_investment'
                     )),
  description      text,
  reference_type   text,
  reference_id     uuid,
  created_at       timestamptz default now()
);

create index if not exists idx_credit_transactions_user_id
  on credit_transactions(user_id);
create index if not exists idx_credit_transactions_created_at
  on credit_transactions(created_at desc);

-- ──────────────────────────────────────────────────────────────────────────
-- project_investments
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists project_investments (
  id             uuid primary key default gen_random_uuid(),
  project_id     uuid not null references projects(id) on delete cascade,
  user_id        uuid not null references profiles(id) on delete cascade,
  credits_amount integer not null check (credits_amount > 0),
  message        text,
  created_at     timestamptz default now(),
  unique (project_id, user_id)
);

create index if not exists idx_project_investments_project_id
  on project_investments(project_id);
create index if not exists idx_project_investments_user_id
  on project_investments(user_id);
-- Composite index to optimize the SUM(credits_amount) aggregation in the trigger
create index if not exists idx_project_investments_project_credits
  on project_investments(project_id, credits_amount);

-- ──────────────────────────────────────────────────────────────────────────
-- project_contributions
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists project_contributions (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references projects(id) on delete cascade,
  user_id           uuid not null references profiles(id) on delete cascade,
  contribution_type text not null default 'credits'
                      check (contribution_type in ('credits','skills','time','other')),
  amount            integer default 0,
  description       text not null,
  created_at        timestamptz default now()
);

create index if not exists idx_project_contributions_project_id
  on project_contributions(project_id);

-- ──────────────────────────────────────────────────────────────────────────
-- project_equity
-- ──────────────────────────────────────────────────────────────────────────
create table if not exists project_equity (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references projects(id) on delete cascade,
  user_id           uuid not null references profiles(id) on delete cascade,
  equity_percentage numeric(5,2) not null
                      check (equity_percentage > 0 and equity_percentage <= 100),
  description       text,
  granted_at        timestamptz default now(),
  unique (project_id, user_id)
);

create index if not exists idx_project_equity_project_id
  on project_equity(project_id);

-- ──────────────────────────────────────────────────────────────────────────
-- Extend projects table
-- ──────────────────────────────────────────────────────────────────────────
alter table projects
  add column if not exists total_invested  integer not null default 0,
  add column if not exists investor_count  integer not null default 0;

-- ──────────────────────────────────────────────────────────────────────────
-- Trigger: keep projects.total_invested / investor_count in sync
-- ──────────────────────────────────────────────────────────────────────────
create or replace function sync_project_investment_stats()
returns trigger language plpgsql as $$
begin
  if (tg_op = 'DELETE') then
    update projects
    set
      total_invested = coalesce((
        select sum(credits_amount) from project_investments
        where project_id = old.project_id
      ), 0),
      investor_count = (
        select count(*) from project_investments
        where project_id = old.project_id
      )
    where id = old.project_id;
    return old;
  else
    update projects
    set
      total_invested = coalesce((
        select sum(credits_amount) from project_investments
        where project_id = new.project_id
      ), 0),
      investor_count = (
        select count(*) from project_investments
        where project_id = new.project_id
      )
    where id = new.project_id;
    return new;
  end if;
end;
$$;

drop trigger if exists trg_sync_project_investment_stats on project_investments;
create trigger trg_sync_project_investment_stats
after insert or update or delete on project_investments
for each row execute function sync_project_investment_stats();

-- ──────────────────────────────────────────────────────────────────────────
-- Trigger: keep credit_balances.updated_at fresh
-- ──────────────────────────────────────────────────────────────────────────
create or replace function touch_credit_balance_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_touch_credit_balance on credit_balances;
create trigger trg_touch_credit_balance
before update on credit_balances
for each row execute function touch_credit_balance_updated_at();

-- ──────────────────────────────────────────────────────────────────────────
-- RLS
-- ──────────────────────────────────────────────────────────────────────────
alter table membership_tiers      enable row level security;
alter table user_memberships      enable row level security;
alter table credit_balances       enable row level security;
alter table credit_transactions   enable row level security;
alter table project_investments   enable row level security;
alter table project_contributions enable row level security;
alter table project_equity        enable row level security;

-- membership_tiers: public read, no direct writes from clients
create policy "membership_tiers_select" on membership_tiers
  for select using (true);

-- user_memberships
create policy "user_memberships_select_own" on user_memberships
  for select using (auth.uid() = user_id);
create policy "user_memberships_insert_own" on user_memberships
  for insert with check (auth.uid() = user_id);
create policy "user_memberships_update_own" on user_memberships
  for update using (auth.uid() = user_id);

-- credit_balances
create policy "credit_balances_select_own" on credit_balances
  for select using (auth.uid() = user_id);
create policy "credit_balances_insert_own" on credit_balances
  for insert with check (auth.uid() = user_id);
create policy "credit_balances_update_own" on credit_balances
  for update using (auth.uid() = user_id);

-- credit_transactions
create policy "credit_transactions_select_own" on credit_transactions
  for select using (auth.uid() = user_id);
create policy "credit_transactions_insert_own" on credit_transactions
  for insert with check (auth.uid() = user_id);

-- project_investments: public read (so anyone can see funders), own write
create policy "project_investments_select" on project_investments
  for select using (true);
create policy "project_investments_insert_own" on project_investments
  for insert with check (auth.uid() = user_id);
create policy "project_investments_update_own" on project_investments
  for update using (auth.uid() = user_id);
create policy "project_investments_delete_own" on project_investments
  for delete using (auth.uid() = user_id);

-- project_contributions: public read, own write
create policy "project_contributions_select" on project_contributions
  for select using (true);
create policy "project_contributions_insert_own" on project_contributions
  for insert with check (auth.uid() = user_id);
create policy "project_contributions_delete_own" on project_contributions
  for delete using (auth.uid() = user_id);

-- project_equity: public read, owner writes
create policy "project_equity_select" on project_equity
  for select using (true);
create policy "project_equity_insert_owner" on project_equity
  for insert with check (
    exists (
      select 1 from projects
      where projects.id = project_id
        and projects.owner_id = auth.uid()
    )
  );
create policy "project_equity_update_owner" on project_equity
  for update using (
    exists (
      select 1 from projects
      where projects.id = project_id
        and projects.owner_id = auth.uid()
    )
  );
create policy "project_equity_delete_owner" on project_equity
  for delete using (
    exists (
      select 1 from projects
      where projects.id = project_id
        and projects.owner_id = auth.uid()
    )
  );

-- ──────────────────────────────────────────────────────────────────────────
-- Seed membership tiers
-- ──────────────────────────────────────────────────────────────────────────
insert into membership_tiers (name, slug, price_monthly, price_annual, description, features, badge_color, is_active, sort_order)
values
  (
    'Free',
    'free',
    0,
    0,
    'Get started with the ThExempt community at no cost.',
    '["Access community discussions","Browse projects","Basic profile","5 credits on signup"]',
    '#666666',
    true,
    0
  ),
  (
    'Supporter',
    'supporter',
    9.99,
    99.99,
    'Amplify your impact with monthly credits and exclusive features.',
    '["Everything in Free","50 credits/month","Endorse projects","Priority in skills marketplace","Supporter badge"]',
    '#0A66C2',
    true,
    1
  ),
  (
    'Changemaker',
    'changemaker',
    24.99,
    249.99,
    'Lead the change — invest in projects and earn equity.',
    '["Everything in Supporter","200 credits/month","Invest in projects","Equity participation","Changemaker badge","Early access to features"]',
    '#057642',
    true,
    2
  )
on conflict (slug) do nothing;
