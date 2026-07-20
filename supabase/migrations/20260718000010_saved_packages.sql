create table public.saved_packages (
  tourist_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  package_id uuid not null references public.tour_packages(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (tourist_id, package_id)
);

alter table public.saved_packages enable row level security;

create policy "travellers read own saved packages" on public.saved_packages
for select to authenticated using (tourist_id = auth.uid());

create policy "travellers save active packages" on public.saved_packages
for insert to authenticated with check (
  tourist_id = auth.uid()
  and exists (
    select 1 from public.tour_packages
    join public.guides on guides.user_id = tour_packages.guide_id
    where tour_packages.id = package_id
      and tour_packages.status = 'active'
      and guides.verification_status = 'approved'
  )
);

create policy "travellers remove own saved packages" on public.saved_packages
for delete to authenticated using (tourist_id = auth.uid());

revoke all on public.saved_packages from anon, authenticated;
grant select, delete on public.saved_packages to authenticated;
grant insert (package_id) on public.saved_packages to authenticated;

create view public.my_saved_packages
with (security_barrier = true) as
select
  saved_packages.package_id,
  saved_packages.created_at,
  tour_packages.title,
  tour_packages.category,
  tour_packages.duration_days,
  tour_packages.price_npr,
  profiles.full_name as guide_name
from public.saved_packages
join public.tour_packages on tour_packages.id = saved_packages.package_id
join public.guides on guides.user_id = tour_packages.guide_id
join public.profiles on profiles.id = guides.user_id
where saved_packages.tourist_id = auth.uid()
  and tour_packages.status = 'active'
  and guides.verification_status = 'approved';

revoke all on public.my_saved_packages from public;
grant select on public.my_saved_packages to authenticated;
