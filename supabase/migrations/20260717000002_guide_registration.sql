create table public.guides (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  location text,
  bio text,
  languages text[] not null default '{}',
  categories text[] not null default '{}',
  years_experience smallint check (years_experience >= 0),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

alter table public.guides enable row level security;

revoke all on public.guides from anon, authenticated;
grant select on public.guides to authenticated;
grant update (location, bio, languages, categories, years_experience) on public.guides to authenticated;

create policy "guides read own record or admin" on public.guides
for select using (auth.uid() = user_id or public.is_admin());

create policy "guides update own editable fields" on public.guides
for update using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "admin manages guides" on public.guides
for all using (public.is_admin()) with check (public.is_admin());

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
    insert into public.guides (user_id, location, bio, languages, categories, years_experience)
    values (
      new.id,
      new.raw_user_meta_data ->> 'location',
      new.raw_user_meta_data ->> 'bio',
      array(select jsonb_array_elements_text(coalesce(new.raw_user_meta_data -> 'languages', '[]'::jsonb))),
      array(select jsonb_array_elements_text(coalesce(new.raw_user_meta_data -> 'categories', '[]'::jsonb))),
      nullif(new.raw_user_meta_data ->> 'years_experience', '')::smallint
    );
  end if;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
