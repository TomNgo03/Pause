-- Pause social backend. Run in a new Supabase project after reviewing policies.
create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 30),
  friend_code text not null unique check (friend_code ~ '^[A-Z0-9]{8}$'),
  daily_intention text check (char_length(daily_intention) <= 120),
  created_at timestamptz not null default now()
);

create table public.friendships (
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','blocked')),
  created_at timestamptz not null default now(),
  primary key (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

create table public.circles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 40),
  weekly_goal integer not null default 10 check (weekly_goal between 1 and 100),
  created_at timestamptz not null default now()
);

create table public.circle_members (
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  joined_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);

create table public.focus_rooms (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  creator_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 60),
  duration_minutes integer not null check (duration_minutes between 5 and 60),
  state text not null default 'waiting' check (state in ('waiting','focusing','completed','cancelled')),
  starts_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.room_participants (
  room_id uuid not null references public.focus_rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 80),
  target integer not null check (target between 1 and 500),
  progress integer not null default 0 check (progress >= 0),
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.encouragements (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('support','plan','focus','together')),
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);

create table public.ai_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  used_at timestamptz not null default now()
);
create index ai_usage_user_time on public.ai_usage(user_id, used_at desc);

create function public.create_pause_profile() returns trigger language plpgsql security definer set search_path = public as $$
declare generated_code text;
begin
  loop
    generated_code := upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 8));
    exit when not exists(select 1 from profiles where friend_code = generated_code);
  end loop;
  insert into profiles(id, display_name, friend_code) values (new.id, 'Student', generated_code);
  return new;
end; $$;
create trigger on_pause_user_created after insert on auth.users for each row execute procedure public.create_pause_profile();

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.focus_rooms enable row level security;
alter table public.room_participants enable row level security;
alter table public.challenges enable row level security;
alter table public.encouragements enable row level security;
alter table public.ai_usage enable row level security;

create policy "own profile" on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy "friendship participants read" on public.friendships for select using (auth.uid() in (requester_id, addressee_id));
create policy "request own friendship" on public.friendships for insert with check (requester_id = auth.uid() and status = 'pending');
create policy "participants update friendship" on public.friendships for update using (auth.uid() in (requester_id, addressee_id));
create policy "participants delete friendship" on public.friendships for delete using (auth.uid() in (requester_id, addressee_id));

create function public.is_circle_member(target_circle uuid) returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from circle_members where circle_id = target_circle and user_id = auth.uid());
$$;
create policy "members read circles" on public.circles for select using (public.is_circle_member(id) or owner_id = auth.uid());
create policy "users create circles" on public.circles for insert with check (owner_id = auth.uid());
create policy "owners update circles" on public.circles for update using (owner_id = auth.uid());
create policy "owners delete circles" on public.circles for delete using (owner_id = auth.uid());
create policy "members read membership" on public.circle_members for select using (public.is_circle_member(circle_id));
create policy "owners add membership" on public.circle_members for insert with check (exists(select 1 from circles where id = circle_id and owner_id = auth.uid()) or user_id = auth.uid());
create policy "member or owner leaves" on public.circle_members for delete using (user_id = auth.uid() or exists(select 1 from circles where id = circle_id and owner_id = auth.uid()));
create policy "members manage rooms" on public.focus_rooms for all using (public.is_circle_member(circle_id)) with check (public.is_circle_member(circle_id) and creator_id = auth.uid());
create policy "room members read participants" on public.room_participants for select using (exists(select 1 from focus_rooms r where r.id = room_id and public.is_circle_member(r.circle_id)));
create policy "join as self" on public.room_participants for insert with check (user_id = auth.uid());
create policy "leave as self" on public.room_participants for delete using (user_id = auth.uid());
create policy "members read challenges" on public.challenges for select using (public.is_circle_member(circle_id));
create policy "circle owners manage challenges" on public.challenges for all using (exists(select 1 from circles where id = circle_id and owner_id = auth.uid()));
create policy "recipient or sender reads reactions" on public.encouragements for select using (auth.uid() in (sender_id, recipient_id));
create policy "sender creates preset reaction" on public.encouragements for insert with check (sender_id = auth.uid());
create policy "recipient deletes reaction" on public.encouragements for delete using (recipient_id = auth.uid());

create function public.request_friend_by_code(target_code text) returns uuid language plpgsql security definer set search_path = public as $$
declare target_id uuid;
begin
  select id into target_id from profiles where friend_code = upper(target_code);
  if target_id is null or target_id = auth.uid() then raise exception 'invalid_friend_code'; end if;
  insert into friendships(requester_id, addressee_id, status) values (auth.uid(), target_id, 'pending')
  on conflict (requester_id, addressee_id) do nothing;
  return target_id;
end; $$;
grant execute on function public.request_friend_by_code(text) to authenticated;

create function public.consume_ai_quota(target_user uuid, daily_limit integer default 10)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if target_user is null or (select count(*) from ai_usage where user_id = target_user and used_at > now() - interval '24 hours') >= daily_limit then
    return false;
  end if;
  insert into ai_usage(user_id) values (target_user);
  return true;
end; $$;
revoke all on function public.consume_ai_quota(uuid, integer) from public, anon, authenticated;
