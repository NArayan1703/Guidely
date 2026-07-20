alter table public.tour_packages
  add column if not exists description text not null default ''
    check (char_length(description) <= 2000),
  add column if not exists highlights text[] not null default '{}',
  add column if not exists cover_path text;

insert into storage.buckets (id, name, public)
values ('package-images', 'package-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "guides upload package images" on storage.objects;
create policy "guides upload package images" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'package-images'
  and (storage.foldername(name))[1] = auth.uid()::text
  and exists (select 1 from public.guides where user_id = auth.uid())
);

drop policy if exists "guides update package images" on storage.objects;
create policy "guides update package images" on storage.objects
for update to authenticated
using (
  bucket_id = 'package-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'package-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "guides delete package images" on storage.objects;
create policy "guides delete package images" on storage.objects
for delete to authenticated
using (
  bucket_id = 'package-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace view public.public_tour_packages
with (security_barrier = true) as
select
  tour_packages.id,
  tour_packages.guide_id,
  tour_packages.title,
  tour_packages.category,
  tour_packages.duration_days,
  tour_packages.capacity,
  tour_packages.price_npr,
  profiles.full_name as guide_name,
  tour_packages.description,
  tour_packages.highlights,
  tour_packages.cover_path
from public.tour_packages
join public.guides on guides.user_id = tour_packages.guide_id
join public.profiles on profiles.id = guides.user_id
where tour_packages.status = 'active'
  and guides.verification_status = 'approved';

drop function if exists public.update_guide_package(uuid, text, text, smallint, smallint, integer);

create function public.update_guide_package(
  p_package_id uuid,
  p_title text,
  p_category text,
  p_duration_days smallint,
  p_capacity smallint,
  p_price_npr integer,
  p_description text,
  p_highlights text[],
  p_cover_path text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Please sign in again.';
  end if;
  if p_cover_path is not null
    and p_cover_path <> ''
    and p_cover_path not like auth.uid()::text || '/%' then
    raise exception 'Invalid cover image.';
  end if;

  update public.tour_packages
  set
    title = p_title,
    category = p_category,
    duration_days = p_duration_days,
    capacity = p_capacity,
    price_npr = p_price_npr,
    description = p_description,
    highlights = coalesce(p_highlights, '{}'),
    cover_path = nullif(p_cover_path, '')
  where id = p_package_id
    and guide_id = auth.uid();

  if not found then
    raise exception 'Package not found.';
  end if;
end;
$$;

revoke all on function public.update_guide_package(
  uuid, text, text, smallint, smallint, integer, text, text[], text
) from public;
grant execute on function public.update_guide_package(
  uuid, text, text, smallint, smallint, integer, text, text[], text
) to authenticated;
