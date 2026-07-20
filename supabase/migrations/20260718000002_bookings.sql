create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  tourist_id uuid not null references public.profiles(id) on delete cascade,
  guide_id uuid not null references public.guides(user_id) on delete restrict,
  package_id uuid not null references public.tour_packages(id) on delete restrict,
  starts_on date not null check (starts_on >= current_date),
  headcount smallint not null check (headcount between 1 and 50),
  trip_note text not null default '' check (char_length(trip_note) <= 1000),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'withdrawn', 'completed')),
  created_at timestamptz not null default now(),
  unique (tourist_id, package_id, starts_on)
);

alter table public.bookings enable row level security;

create policy "tourists create valid booking requests" on public.bookings
for insert to authenticated
with check (
  tourist_id = auth.uid()
  and status = 'pending'
  and exists (
    select 1
    from public.tour_packages
    join public.guides on guides.user_id = tour_packages.guide_id
    where tour_packages.id = package_id
      and tour_packages.guide_id = guide_id
      and tour_packages.status = 'active'
      and guides.verification_status = 'approved'
      and headcount <= tour_packages.capacity
  )
);

create policy "booking participants read bookings" on public.bookings
for select to authenticated
using (tourist_id = auth.uid() or guide_id = auth.uid());

revoke all on public.bookings from anon, authenticated;
grant select, insert on public.bookings to authenticated;

drop view if exists public.public_tour_packages;

create view public.public_tour_packages
with (security_barrier = true) as
select
  tour_packages.id,
  tour_packages.guide_id,
  tour_packages.title,
  tour_packages.category,
  tour_packages.duration_days,
  tour_packages.capacity,
  tour_packages.price_npr,
  profiles.full_name as guide_name
from public.tour_packages
join public.guides on guides.user_id = tour_packages.guide_id
join public.profiles on profiles.id = guides.user_id
where tour_packages.status = 'active'
  and guides.verification_status = 'approved';

revoke all on public.public_tour_packages from public;
grant select on public.public_tour_packages to anon, authenticated;
