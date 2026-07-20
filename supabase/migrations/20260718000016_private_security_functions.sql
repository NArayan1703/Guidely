-- Keep SECURITY DEFINER code outside the Data API. Public functions below are
-- SECURITY INVOKER wrappers; their private implementations are not RPC routes.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated;

alter function public.handle_new_user() set schema private;
revoke all on function private.handle_new_user() from public, anon, authenticated;

create or replace function private.list_public_tour_packages()
returns table (
  id uuid, guide_id uuid, title text, category text, duration_days smallint,
  capacity smallint, price_npr integer, guide_name text, description text,
  highlights text[], cover_path text
)
language sql stable security definer set search_path = ''
as $$
  select tour_packages.id, tour_packages.guide_id, tour_packages.title,
    tour_packages.category, tour_packages.duration_days, tour_packages.capacity,
    tour_packages.price_npr, profiles.full_name, tour_packages.description,
    tour_packages.highlights, tour_packages.cover_path
  from public.tour_packages
  join public.guides on guides.user_id = tour_packages.guide_id
  join public.profiles on profiles.id = guides.user_id
  where tour_packages.status = 'active'
    and guides.verification_status = 'approved';
$$;

create or replace function private.list_my_booking_summaries()
returns table (
  id uuid, starts_on date, headcount smallint, status text,
  package_title text, guide_name text, reviewed boolean
)
language sql stable security definer set search_path = ''
as $$
  select bookings.id, bookings.starts_on, bookings.headcount, bookings.status,
    tour_packages.title, profiles.full_name,
    exists (select 1 from public.reviews where reviews.booking_id = bookings.id)
  from public.bookings
  join public.tour_packages on tour_packages.id = bookings.package_id
  join public.profiles on profiles.id = bookings.guide_id
  where bookings.tourist_id = auth.uid();
$$;

create or replace function private.list_my_saved_packages()
returns table (
  package_id uuid, created_at timestamptz, title text, category text,
  duration_days smallint, price_npr integer, guide_name text
)
language sql stable security definer set search_path = ''
as $$
  select saved_packages.package_id, saved_packages.created_at, tour_packages.title,
    tour_packages.category, tour_packages.duration_days, tour_packages.price_npr,
    profiles.full_name
  from public.saved_packages
  join public.tour_packages on tour_packages.id = saved_packages.package_id
  join public.guides on guides.user_id = tour_packages.guide_id
  join public.profiles on profiles.id = guides.user_id
  where saved_packages.tourist_id = auth.uid()
    and tour_packages.status = 'active'
    and guides.verification_status = 'approved';
$$;

create or replace function private.create_booking_request(
  p_package_id uuid, p_starts_on date, p_headcount smallint, p_trip_note text default ''
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare package_row public.tour_packages%rowtype; booking_id uuid;
begin
  if auth.uid() is null then raise exception 'Please sign in to request a trip.'; end if;
  if p_starts_on < current_date then raise exception 'Choose a future start date.'; end if;
  if p_headcount not between 1 and 50 then raise exception 'Choose between 1 and 50 travellers.'; end if;
  if char_length(coalesce(p_trip_note, '')) > 1000 then raise exception 'Trip note must be 1000 characters or fewer.'; end if;
  select tour_packages.* into package_row
  from public.tour_packages join public.guides on guides.user_id = tour_packages.guide_id
  where tour_packages.id = p_package_id and tour_packages.status = 'active'
    and guides.verification_status = 'approved';
  if not found then raise exception 'This package is no longer available.'; end if;
  if package_row.guide_id = auth.uid() then raise exception 'You cannot request your own package.'; end if;
  if p_headcount > package_row.capacity then raise exception 'This package allows up to % travellers.', package_row.capacity; end if;
  insert into public.bookings (tourist_id, guide_id, package_id, starts_on, headcount, trip_note)
  values (auth.uid(), package_row.guide_id, p_package_id, p_starts_on, p_headcount, coalesce(p_trip_note, ''))
  returning id into booking_id;
  return booking_id;
exception when unique_violation then
  raise exception 'You already requested this package for that date.';
end;
$$;

create or replace function private.update_guide_package(
  p_package_id uuid, p_title text, p_category text, p_duration_days smallint,
  p_capacity smallint, p_price_npr integer, p_description text,
  p_highlights text[], p_cover_path text
)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Please sign in again.'; end if;
  if p_cover_path is not null and p_cover_path <> ''
    and p_cover_path not like auth.uid()::text || '/%' then
    raise exception 'Invalid cover image.';
  end if;
  update public.tour_packages set
    title = p_title, category = p_category, duration_days = p_duration_days,
    capacity = p_capacity, price_npr = p_price_npr, description = p_description,
    highlights = coalesce(p_highlights, '{}'), cover_path = nullif(p_cover_path, '')
  where id = p_package_id and guide_id = auth.uid();
  if not found then raise exception 'Package not found.'; end if;
end;
$$;

create or replace function private.review_guide_application(application_user_id uuid, approve boolean)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  update public.guide_applications
  set status = case when approve then 'approved' else 'rejected' end
  where user_id = application_user_id and status = 'pending';
  if not found then raise exception 'Pending guide application not found'; end if;
  update public.guides
  set verification_status = case when approve then 'approved' else 'rejected' end
  where user_id = application_user_id;
  if not found then raise exception 'Guide record not found'; end if;
end;
$$;

revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.list_public_tour_packages() to anon, authenticated;
grant execute on function private.list_my_booking_summaries(), private.list_my_saved_packages(),
  private.create_booking_request(uuid, date, smallint, text),
  private.update_guide_package(uuid, text, text, smallint, smallint, integer, text, text[], text),
  private.review_guide_application(uuid, boolean) to authenticated;

create or replace function public.create_booking_request(
  p_package_id uuid, p_starts_on date, p_headcount smallint, p_trip_note text default ''
)
returns uuid language sql security invoker set search_path = ''
as $$ select private.create_booking_request(p_package_id, p_starts_on, p_headcount, p_trip_note); $$;

create or replace function public.update_guide_package(
  p_package_id uuid, p_title text, p_category text, p_duration_days smallint,
  p_capacity smallint, p_price_npr integer, p_description text,
  p_highlights text[], p_cover_path text
)
returns void language sql security invoker set search_path = ''
as $$ select private.update_guide_package(p_package_id, p_title, p_category, p_duration_days,
  p_capacity, p_price_npr, p_description, p_highlights, p_cover_path); $$;

create or replace function public.review_guide_application(application_user_id uuid, approve boolean)
returns void language sql security invoker set search_path = ''
as $$ select private.review_guide_application(application_user_id, approve); $$;

create or replace view public.public_tour_packages as
select * from private.list_public_tour_packages();
create or replace view public.my_booking_summaries as
select * from private.list_my_booking_summaries();
create or replace view public.my_saved_packages as
select * from private.list_my_saved_packages();
alter view public.public_tour_packages
  set (security_invoker = true, security_barrier = true);
alter view public.my_booking_summaries
  set (security_invoker = true, security_barrier = true);
alter view public.my_saved_packages
  set (security_invoker = true, security_barrier = true);

drop function public.list_public_tour_packages();
drop function public.list_my_booking_summaries();
drop function public.list_my_saved_packages();

revoke all on function public.create_booking_request(uuid, date, smallint, text) from public, anon;
revoke all on function public.update_guide_package(uuid, text, text, smallint, smallint, integer, text, text[], text) from public, anon;
revoke all on function public.review_guide_application(uuid, boolean) from public, anon;
grant execute on function public.create_booking_request(uuid, date, smallint, text),
  public.update_guide_package(uuid, text, text, smallint, smallint, integer, text, text[], text),
  public.review_guide_application(uuid, boolean) to authenticated;
