create table public.contact_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in ('booking_issue', 'guide_complaint', 'general_inquiry', 'other', 'report')),
  message text not null check (char_length(message) between 1 and 4000),
  contact_details text,
  screenshot_path text,
  created_at timestamptz not null default now()
);

alter table public.contact_requests enable row level security;

create policy "users create own contact requests" on public.contact_requests
for insert to authenticated
with check (auth.uid() = user_id);

create policy "admins read contact requests" on public.contact_requests
for select to authenticated
using (public.is_admin());

revoke all on public.contact_requests from anon, authenticated;
grant insert (user_id, reason, message, contact_details, screenshot_path) on public.contact_requests to authenticated;
grant select on public.contact_requests to authenticated;

insert into storage.buckets (id, name, public)
values ('support-attachments', 'support-attachments', false)
on conflict (id) do update set public = excluded.public;

create policy "users upload own support attachments" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'support-attachments'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "admins read support attachments" on storage.objects
for select to authenticated
using (bucket_id = 'support-attachments' and public.is_admin());
