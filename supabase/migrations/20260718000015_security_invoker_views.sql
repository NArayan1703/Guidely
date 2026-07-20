-- Views should respect the caller's privileges. These no-argument functions
-- expose only the same fields the previous views exposed, with their own
-- fixed predicates, so no profile, booking, or package table grants widen.
create or replace function public.list_public_tour_packages()
returns table (
  id uuid,
  guide_id uuid,
  title text,
  category text,
  duration_days smallint,
  capacity smallint,
  price_npr integer,
  guide_name text,
  description text,
  highlights text[],
  cover_path text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    tour_packages.id,
    tour_packages.guide_id,
    tour_packages.title,
    tour_packages.category,
    tour_packages.duration_days,
    tour_packages.capacity,
    tour_packages.price_npr,
    profiles.full_name,
    tour_packages.description,
    tour_packages.highlights,
    tour_packages.cover_path
  from public.tour_packages
  join public.guides on guides.user_id = tour_packages.guide_id
  join public.profiles on profiles.id = guides.user_id
  where tour_packages.status = 'active'
    and guides.verification_status = 'approved';
$$;

create or replace function public.list_my_booking_summaries()
returns table (
  id uuid,
  starts_on date,
  headcount smallint,
  status text,
  package_title text,
  guide_name text,
  reviewed boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    bookings.id,
    bookings.starts_on,
    bookings.headcount,
    bookings.status,
    tour_packages.title,
    profiles.full_name,
    exists (
      select 1 from public.reviews where reviews.booking_id = bookings.id
    )
  from public.bookings
  join public.tour_packages on tour_packages.id = bookings.package_id
  join public.profiles on profiles.id = bookings.guide_id
  where bookings.tourist_id = auth.uid();
$$;

create or replace function public.list_my_saved_packages()
returns table (
  package_id uuid,
  created_at timestamptz,
  title text,
  category text,
  duration_days smallint,
  price_npr integer,
  guide_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    saved_packages.package_id,
    saved_packages.created_at,
    tour_packages.title,
    tour_packages.category,
    tour_packages.duration_days,
    tour_packages.price_npr,
    profiles.full_name
  from public.saved_packages
  join public.tour_packages on tour_packages.id = saved_packages.package_id
  join public.guides on guides.user_id = tour_packages.guide_id
  join public.profiles on profiles.id = guides.user_id
  where saved_packages.tourist_id = auth.uid()
    and tour_packages.status = 'active'
    and guides.verification_status = 'approved';
$$;

revoke all on function public.list_public_tour_packages() from public;
grant execute on function public.list_public_tour_packages() to anon, authenticated;
revoke all on function public.list_my_booking_summaries() from public;
grant execute on function public.list_my_booking_summaries() to authenticated;
revoke all on function public.list_my_saved_packages() from public;
grant execute on function public.list_my_saved_packages() to authenticated;

create or replace view public.public_tour_packages as
select * from public.list_public_tour_packages();
alter view public.public_tour_packages
  set (security_invoker = true, security_barrier = true);

create or replace view public.my_booking_summaries as
select * from public.list_my_booking_summaries();
alter view public.my_booking_summaries
  set (security_invoker = true, security_barrier = true);

create or replace view public.my_saved_packages as
select * from public.list_my_saved_packages();
alter view public.my_saved_packages
  set (security_invoker = true, security_barrier = true);

revoke all on public.public_tour_packages, public.my_booking_summaries, public.my_saved_packages from public;
grant select on public.public_tour_packages to anon, authenticated;
grant select on public.my_booking_summaries, public.my_saved_packages to authenticated;
