create type public.app_role as enum ('traveller', 'guide', 'admin');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  preferred_locale text not null default 'en' check (preferred_locale in ('en', 'ne')),
  country text,
  accepted_terms_at timestamptz,
  role public.app_role not null default 'traveller',
  created_at timestamptz not null default now()
);

create table public.guide_applications (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.guide_applications enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$ select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false); $$;

create policy "read own profile or admin" on public.profiles
for select using (auth.uid() = id or public.is_admin());

create policy "update own profile" on public.profiles
for update using (auth.uid() = id)
with check (auth.uid() = id);

create policy "admin manages profiles" on public.profiles
for all using (public.is_admin()) with check (public.is_admin());

create policy "read own guide application or admin" on public.guide_applications
for select using (auth.uid() = user_id or public.is_admin());

create policy "admin manages guide applications" on public.guide_applications
for all using (public.is_admin()) with check (public.is_admin());

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone, preferred_locale, country) on public.profiles to authenticated;
grant select on public.guide_applications to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone, preferred_locale, country, accepted_terms_at)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'phone',
    coalesce(new.raw_user_meta_data ->> 'preferred_locale', 'en'),
    new.raw_user_meta_data ->> 'country',
    case when new.raw_user_meta_data ->> 'accepted_terms' = 'true' then now() end
  );

  if new.raw_user_meta_data ->> 'requested_role' = 'guide' then
    insert into public.guide_applications (user_id) values (new.id);
  end if;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

revoke all on function public.handle_new_user() from public;

insert into public.profiles (id, full_name)
select id, raw_user_meta_data ->> 'full_name'
from auth.users
on conflict (id) do nothing;

insert into public.guide_applications (user_id)
select id
from auth.users
where raw_user_meta_data ->> 'requested_role' = 'guide'
on conflict (user_id) do nothing;

comment on column public.profiles.role is
  'Not an authorization source. Authorization uses auth.users.raw_app_meta_data.role.';

-- Promote administrators only from the Supabase SQL editor or a trusted server:
-- update auth.users set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb where email = 'admin@example.com';
