create policy "guides complete own accepted bookings" on public.bookings
for update to authenticated
using (guide_id = auth.uid() and status = 'accepted')
with check (guide_id = auth.uid() and status = 'completed');
