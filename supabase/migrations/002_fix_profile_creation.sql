-- Keep auth signup independent from extension schema placement.
-- A failed AFTER INSERT trigger rolls back auth.users creation, so this function
-- intentionally uses only built-in PostgreSQL functions and qualified names.
create or replace function public.create_pause_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  generated_code text;
begin
  loop
    generated_code := upper(substr(md5(new.id::text || clock_timestamp()::text || random()::text), 1, 8));
    exit when not exists (
      select 1 from public.profiles where friend_code = generated_code
    );
  end loop;

  insert into public.profiles (id, display_name, friend_code)
  values (
    new.id,
    coalesce(nullif(left(new.raw_user_meta_data ->> 'display_name', 30), ''), 'Student'),
    generated_code
  );
  return new;
end;
$$;
