create policy "guides respond to own pending bookings" on public.bookings
for update to authenticated
using (guide_id = auth.uid() and status = 'pending')
with check (guide_id = auth.uid() and status in ('accepted', 'declined'));

grant update (status) on public.bookings to authenticated;
