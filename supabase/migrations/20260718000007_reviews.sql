create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  tourist_id uuid not null references public.profiles(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 1000),
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

create policy "tourists review completed own bookings" on public.reviews
for insert to authenticated
with check (
  tourist_id = auth.uid()
  and exists (
    select 1 from public.bookings
    where bookings.id = booking_id
      and bookings.tourist_id = auth.uid()
      and bookings.status = 'completed'
  )
);

create policy "booking participants read reviews" on public.reviews
for select to authenticated
using (
  exists (
    select 1 from public.bookings
    where bookings.id = booking_id
      and (bookings.tourist_id = auth.uid() or bookings.guide_id = auth.uid())
  )
);

revoke all on public.reviews from anon, authenticated;
grant select, insert on public.reviews to authenticated;

drop view if exists public.my_booking_summaries;

create view public.my_booking_summaries
with (security_barrier = true) as
select
  bookings.id,
  bookings.starts_on,
  bookings.headcount,
  bookings.status,
  tour_packages.title as package_title,
  profiles.full_name as guide_name,
  exists (select 1 from public.reviews where reviews.booking_id = bookings.id) as reviewed
from public.bookings
join public.tour_packages on tour_packages.id = bookings.package_id
join public.profiles on profiles.id = bookings.guide_id
where bookings.tourist_id = auth.uid();

revoke all on public.my_booking_summaries from public;
grant select on public.my_booking_summaries to authenticated;
