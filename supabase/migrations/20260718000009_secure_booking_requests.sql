-- The client supplies only its chosen package and trip details. The database
-- derives both participants and re-checks the package at write time.
create or replace function public.create_booking_request(
  p_package_id uuid,
  p_starts_on date,
  p_headcount smallint,
  p_trip_note text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  package_row public.tour_packages%rowtype;
  booking_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Please sign in to request a trip.';
  end if;

  if p_starts_on < current_date then
    raise exception 'Choose a future start date.';
  end if;

  if p_headcount not between 1 and 50 then
    raise exception 'Choose between 1 and 50 travellers.';
  end if;

  if char_length(coalesce(p_trip_note, '')) > 1000 then
    raise exception 'Trip note must be 1000 characters or fewer.';
  end if;

  select tour_packages.* into package_row
  from public.tour_packages
  join public.guides on guides.user_id = tour_packages.guide_id
  where tour_packages.id = p_package_id
    and tour_packages.status = 'active'
    and guides.verification_status = 'approved';

  if not found then
    raise exception 'This package is no longer available.';
  end if;

  if p_headcount > package_row.capacity then
    raise exception 'This package allows up to % travellers.', package_row.capacity;
  end if;

  insert into public.bookings (tourist_id, guide_id, package_id, starts_on, headcount, trip_note)
  values (auth.uid(), package_row.guide_id, p_package_id, p_starts_on, p_headcount, coalesce(p_trip_note, ''))
  returning id into booking_id;

  return booking_id;
exception
  when unique_violation then
    raise exception 'You already requested this package for that date.';
end;
$$;

revoke insert on public.bookings from authenticated;
drop policy if exists "tourists create valid booking requests" on public.bookings;

revoke all on function public.create_booking_request(uuid, date, smallint, text) from public;
grant execute on function public.create_booking_request(uuid, date, smallint, text) to authenticated;
