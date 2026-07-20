drop policy if exists "guides manage own packages" on public.tour_packages;

create policy "guides read own packages" on public.tour_packages
for select to authenticated using (guide_id = auth.uid());

create policy "guides create draft packages" on public.tour_packages
for insert to authenticated
with check (guide_id = auth.uid() and status = 'draft');

create policy "guides update own draft packages" on public.tour_packages
for update to authenticated
using (guide_id = auth.uid() and status = 'draft')
with check (guide_id = auth.uid() and status = 'draft');

create policy "guides delete own draft packages" on public.tour_packages
for delete to authenticated
using (guide_id = auth.uid() and status = 'draft');
