alter table public.contact_requests
  add column if not exists status text not null default 'open'
    check (status in ('open', 'in_progress', 'closed'));

create policy "admins manage contact requests" on public.contact_requests
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "admins read all bookings" on public.bookings
for select to authenticated
using (public.is_admin());

grant update (status) on public.contact_requests to authenticated;
