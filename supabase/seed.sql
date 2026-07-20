-- Development/demo data. Run this manually in the Supabase SQL Editor.
-- It reuses your first registered guide and never deletes existing records.
do $$
declare
  seed_guide_id uuid;
begin
  select user_id into seed_guide_id
  from public.guides
  order by created_at
  limit 1;

  if seed_guide_id is null then
    raise exception 'Create a guide account first, then run this seed.';
  end if;

  update public.guides
  set verification_status = 'approved'
  where user_id = seed_guide_id;

  update public.guide_applications
  set status = 'approved'
  where user_id = seed_guide_id;

  with packages(title, category, duration_days, capacity, price_npr) as (
    values
      ('Sunrise at Poon Hill', 'trekking', 4::smallint, 10::smallint, 18500),
      ('Old Pokhara, slow and local', 'culture', 1::smallint, 8::smallint, 3500),
      ('Sarangkot sunrise and paragliding', 'adventure', 1::smallint, 6::smallint, 12000),
      ('Australian Camp forest walk', 'nature', 2::smallint, 12::smallint, 9500),
      ('Begnas Lake village day', 'culture', 1::smallint, 10::smallint, 4800),
      ('Peace Pagoda and lakeside walk', 'wellness', 1::smallint, 8::smallint, 4200)
  )
  insert into public.tour_packages (
    guide_id, title, category, duration_days, capacity, price_npr, status
  )
  select
    seed_guide_id, title, category, duration_days, capacity, price_npr, 'active'
  from packages
  where not exists (
    select 1
    from public.tour_packages
    where guide_id = seed_guide_id
      and tour_packages.title = packages.title
  );
end;
$$;
