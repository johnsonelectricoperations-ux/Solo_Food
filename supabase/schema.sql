-- Zero-Waste Kitchen 초기 스키마
-- Supabase 대시보드 > SQL Editor에 붙여넣어 실행한다.

-- 취향 프로필 (idea.md 유저 여정 0단계)
create table if not exists profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  allergens text[] not null default '{}',
  diet_type text not null default 'normal' check (diet_type in ('normal', 'vegan', 'lowSugar', 'lowSalt')),
  naengpa_count int not null default 0,
  discard_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 냉장고 품목
create table if not exists fridge_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  emoji text not null default '🍽️',
  section text not null check (section in ('shelf1', 'shelf2', 'shelf3', 'door', 'freezer')),
  amount double precision not null default 1.0,
  count int not null default 1,
  expires_on date not null,
  created_at timestamptz not null default now()
);

create index if not exists fridge_items_user_idx on fridge_items (user_id);

-- RLS: 각 유저는 자기 데이터만 읽고 쓸 수 있다
alter table profiles enable row level security;
alter table fridge_items enable row level security;

create policy "own profile" on profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own fridge items" on fridge_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
