create view public.public_tour_packages
with (security_barrier = true) as
select
  tour_packages.id,
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
