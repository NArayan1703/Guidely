alter table public.profiles add column if not exists avatar_path text;
alter table public.guides add column if not exists photo_path text;

grant update (avatar_path) on public.profiles to authenticated;
grant update (photo_path) on public.guides to authenticated;

insert into storage.buckets (id, name, public)
values
  ('user-avatars', 'user-avatars', false),
  ('guide-avatars', 'guide-avatars', true)
on conflict (id) do update set public = excluded.public;

create policy "users manage own private avatar" on storage.objects
for all to authenticated
using (bucket_id = 'user-avatars' and (storage.foldername(name))[1] = (select auth.uid()::text))
with check (bucket_id = 'user-avatars' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "guides upload own public avatar" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'guide-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
  and exists (select 1 from public.guides where user_id = auth.uid())
);

create policy "guides update or delete own public avatar" on storage.objects
for update to authenticated
using (bucket_id = 'guide-avatars' and (storage.foldername(name))[1] = (select auth.uid()::text))
with check (bucket_id = 'guide-avatars' and (storage.foldername(name))[1] = (select auth.uid()::text));

create policy "guides delete own public avatar" on storage.objects
for delete to authenticated
using (bucket_id = 'guide-avatars' and (storage.foldername(name))[1] = (select auth.uid()::text));
