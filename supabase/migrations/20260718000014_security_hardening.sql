-- A prior admin migration granted table-wide UPDATE rights. Keep only the
-- exact columns used by the client; RLS then enforces which rows may change.
revoke update on public.guides, public.guide_applications, public.tour_packages from authenticated;

grant update (location, bio, languages, categories, years_experience, photo_path)
  on public.guides to authenticated;
grant update (status) on public.tour_packages to authenticated;

-- Do not let an authenticated caller point a support ticket at another
-- user's private attachment path.
drop policy if exists "users create own contact requests" on public.contact_requests;
create policy "users create own contact requests" on public.contact_requests
for insert to authenticated
with check (
  auth.uid() = user_id
  and (
    screenshot_path is null
    or screenshot_path like auth.uid()::text || '/%'
  )
);

alter table public.tour_packages
  add constraint tour_packages_cover_path_length
    check (cover_path is null or char_length(cover_path) <= 300),
  add constraint tour_packages_highlights_size
    check (
      cardinality(highlights) <= 8
      and coalesce(octet_length(array_to_string(highlights, '')), 0) <= 1000
    );

update storage.buckets
set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']::text[]
where id = 'package-images';

create or replace function public.is_admin()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

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
  if package_row.guide_id = auth.uid() then
    raise exception 'You cannot request your own package.';
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

revoke all on function public.create_booking_request(uuid, date, smallint, text) from public;
grant execute on function public.create_booking_request(uuid, date, smallint, text) to authenticated;
