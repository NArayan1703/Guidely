create view public.my_booking_summaries
with (security_barrier = true) as
select
  bookings.id,
  bookings.starts_on,
  bookings.headcount,
  bookings.status,
  tour_packages.title as package_title,
  profiles.full_name as guide_name
from public.bookings
join public.tour_packages on tour_packages.id = bookings.package_id
join public.profiles on profiles.id = bookings.guide_id
where bookings.tourist_id = auth.uid();

revoke all on public.my_booking_summaries from public;
grant select on public.my_booking_summaries to authenticated;
