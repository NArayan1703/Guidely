alter table public.profiles
  add column if not exists phone text,
  add column if not exists preferred_locale text not null default 'en' check (preferred_locale in ('en', 'ne')),
  add column if not exists country text,
  add column if not exists accepted_terms_at timestamptz;

grant update (full_name, phone, preferred_locale, country) on public.profiles to authenticated;

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

revoke all on function public.handle_new_user() from public;
