grant update on public.guides, public.guide_applications, public.tour_packages to authenticated;

create policy "admins manage tour packages" on public.tour_packages
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create or replace function public.review_guide_application(
  application_user_id uuid,
  approve boolean
)
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Administrator access required';
  end if;

  update public.guide_applications
  set status = case when approve then 'approved' else 'rejected' end
  where user_id = application_user_id and status = 'pending';

  if not found then
    raise exception 'Pending guide application not found';
  end if;

  update public.guides
  set verification_status = case when approve then 'approved' else 'rejected' end
  where user_id = application_user_id;
end;
$$;

revoke all on function public.review_guide_application(uuid, boolean) from public;
grant execute on function public.review_guide_application(uuid, boolean) to authenticated;
