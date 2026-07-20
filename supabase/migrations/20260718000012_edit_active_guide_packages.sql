create or replace function public.update_guide_package(
  p_package_id uuid,
  p_title text,
  p_category text,
  p_duration_days smallint,
  p_capacity smallint,
  p_price_npr integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Please sign in again.';
  end if;

  update public.tour_packages
  set
    title = p_title,
    category = p_category,
    duration_days = p_duration_days,
    capacity = p_capacity,
    price_npr = p_price_npr
  where id = p_package_id
    and guide_id = auth.uid();

  if not found then
    raise exception 'Package not found.';
  end if;
end;
$$;

revoke all on function public.update_guide_package(uuid, text, text, smallint, smallint, integer) from public;
grant execute on function public.update_guide_package(uuid, text, text, smallint, smallint, integer) to authenticated;
