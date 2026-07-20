create table public.tour_packages (
  id uuid primary key default gen_random_uuid(),
  guide_id uuid not null references public.guides(user_id) on delete cascade,
  title text not null check (char_length(trim(title)) between 3 and 120),
  category text not null check (category in ('trekking', 'adventure', 'nature', 'culture', 'wellness')),
  duration_days smallint not null check (duration_days between 1 and 30),
  capacity smallint not null check (capacity between 1 and 50),
  price_npr integer not null check (price_npr > 0),
  status text not null default 'draft' check (status in ('draft', 'active', 'inactive')),
  created_at timestamptz not null default now()
);

alter table public.tour_packages enable row level security;

create policy "guides manage own packages" on public.tour_packages
for all to authenticated
using (guide_id = auth.uid())
with check (guide_id = auth.uid() and status = 'draft');

revoke all on public.tour_packages from anon, authenticated;
grant select, insert, update, delete on public.tour_packages to authenticated;
