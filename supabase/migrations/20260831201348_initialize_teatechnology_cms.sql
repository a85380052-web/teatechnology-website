-- Teatechnology current-schema baseline.
-- This file intentionally represents the final database structure as of 2026-09-01.
-- Historical changes after this version are folded into this baseline; later files are no-op placeholders.
-- Existing production data is intentionally excluded.

create schema if not exists private;
grant usage on schema private to authenticated;

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin'::text check (role = 'admin'::text),
  created_at timestamptz not null default now()
);

create table public.business_hours (
  id uuid primary key default gen_random_uuid(),
  day_of_week smallint not null unique check (day_of_week >= 1 and day_of_week <= 7),
  day_name_it text not null,
  open_time time,
  close_time time,
  published boolean not null default true,
  sort_order integer not null default 0
);

create table public.faqs (
  id uuid primary key default gen_random_uuid(),
  question_it text not null,
  answer_it text not null,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.inquiries (
  id uuid primary key default gen_random_uuid(),
  name text,
  phone text,
  email text,
  device text,
  message text not null,
  status text not null default 'new'::text check (status = any (array['new'::text,'contacted'::text,'closed'::text])),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  label_zh text,
  file_url text not null,
  alt_text_it text,
  asset_type text not null default 'image'::text check (asset_type = any (array['image'::text,'logo'::text])),
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  title_it text not null,
  description_it text,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.site_settings (
  id uuid primary key default gen_random_uuid(),
  singleton_key text not null default 'main'::text unique check (singleton_key = 'main'::text),
  brand_name text not null default 'Teatechnology'::text,
  phone text,
  address text,
  city text,
  postal_code text,
  country text,
  hero_title_it text,
  hero_subtitle_it text,
  primary_cta_it text,
  secondary_cta_it text,
  logo_url text,
  map_url text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  updated_at timestamptz not null default now()
);

create table public.user_directory (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  email_confirmed boolean not null default false,
  created_at timestamptz,
  last_sign_in_at timestamptz
);

create table public.repair_prices (
  id uuid primary key default gen_random_uuid(),
  device_type text not null default 'iPhone'::text,
  series text not null,
  model text not null,
  service_key text not null,
  service_name_it text not null,
  price_eur numeric(10,2) check (price_eur >= 0::numeric),
  sort_order integer not null default 0,
  active boolean not null default true,
  source_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  brand text not null default 'Apple'::text,
  part_quality text not null default 'originale'::text,
  constraint repair_prices_brand_model_quality_service_key_key unique (brand, model, part_quality, service_key)
);

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path to 'public', 'private'
as $$
  select exists (
    select 1
    from public.admin_users a
    where a.user_id = auth.uid()
  );
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

create or replace function private.sync_user_directory()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if tg_op = 'DELETE' then
    delete from public.user_directory where user_id = old.id;
    return old;
  end if;

  if new.deleted_at is not null then
    delete from public.user_directory where user_id = new.id;
    return new;
  end if;

  insert into public.user_directory(user_id,email,email_confirmed,created_at,last_sign_in_at)
  values(new.id,new.email::text,(new.email_confirmed_at is not null),new.created_at,new.last_sign_in_at)
  on conflict (user_id) do update set
    email = excluded.email,
    email_confirmed = excluded.email_confirmed,
    created_at = excluded.created_at,
    last_sign_in_at = excluded.last_sign_in_at;

  return new;
end;
$$;

revoke all on function private.sync_user_directory() from public;

create trigger trg_sync_user_directory
after insert or update or delete on auth.users
for each row execute function private.sync_user_directory();

create or replace function public.normalize_blank_compatible_price()
returns trigger
language plpgsql
as $$
begin
  if new.part_quality = 'compatibile' and new.price_eur = 0 then
    new.price_eur := null;
  end if;
  return new;
end;
$$;

create trigger normalize_blank_compatible_price_trigger
before insert or update on public.repair_prices
for each row execute function public.normalize_blank_compatible_price();

alter table public.admin_users enable row level security;
alter table public.business_hours enable row level security;
alter table public.faqs enable row level security;
alter table public.inquiries enable row level security;
alter table public.media_assets enable row level security;
alter table public.repair_prices enable row level security;
alter table public.services enable row level security;
alter table public.site_settings enable row level security;
alter table public.user_directory enable row level security;

create policy admin_users_self_read
on public.admin_users for select to authenticated
using (user_id = auth.uid());

create policy admin_users_admin_insert
on public.admin_users for insert to authenticated
with check (private.is_admin());

create policy admin_users_admin_delete
on public.admin_users for delete to authenticated
using (private.is_admin() and user_id <> auth.uid());

create policy hours_public_read
on public.business_hours for select to anon, authenticated
using (published = true);

create policy hours_authenticated_read
on public.business_hours for select to authenticated
using ((published = true) or private.is_admin());

create policy hours_admin_read
on public.business_hours for select to authenticated
using (private.is_admin());

create policy hours_admin_write
on public.business_hours for all to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy faqs_public_read
on public.faqs for select to anon, authenticated
using (active = true);

create policy faqs_authenticated_read
on public.faqs for select to authenticated
using ((active = true) or private.is_admin());

create policy faqs_admin_read
on public.faqs for select to authenticated
using (private.is_admin());

create policy faqs_admin_write
on public.faqs for all to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy inquiries_public_insert
on public.inquiries for insert to anon, authenticated
with check (true);

create policy inquiries_admin_read
on public.inquiries for select to authenticated
using (private.is_admin());

create policy inquiries_admin_update
on public.inquiries for update to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy inquiries_admin_delete
on public.inquiries for delete to authenticated
using (private.is_admin());

create policy media_public_read
on public.media_assets for select to anon, authenticated
using (active = true);

create policy media_authenticated_read
on public.media_assets for select to authenticated
using ((active = true) or private.is_admin());

create policy media_admin_read
on public.media_assets for select to authenticated
using (private.is_admin());

create policy media_admin_write
on public.media_assets for all to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy repair_prices_public_read
on public.repair_prices for select to anon
using (active = true);

create policy repair_prices_authenticated_read
on public.repair_prices for select to authenticated
using ((active = true) or private.is_admin());

create policy repair_prices_admin_write
on public.repair_prices for all to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy services_public_read
on public.services for select to anon, authenticated
using (active = true);

create policy services_authenticated_read
on public.services for select to authenticated
using ((active = true) or private.is_admin());

create policy services_admin_read
on public.services for select to authenticated
using (private.is_admin());

create policy services_admin_write
on public.services for all to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy site_settings_public_read
on public.site_settings for select to anon, authenticated
using (true);

create policy site_settings_admin_write
on public.site_settings for all to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy user_directory_admin_read
on public.user_directory for select to authenticated
using (private.is_admin());

revoke all on table public.admin_users from anon, authenticated;
grant select, insert, delete on table public.admin_users to authenticated;

grant select on table public.business_hours to anon;
grant select, insert, update, delete on table public.business_hours to authenticated;

grant select on table public.faqs to anon;
grant select, insert, update, delete on table public.faqs to authenticated;

grant insert on table public.inquiries to anon;
grant select, insert, update, delete on table public.inquiries to authenticated;

grant select on table public.media_assets to anon;
grant select, insert, update, delete on table public.media_assets to authenticated;

grant select on table public.repair_prices to anon;
grant select, insert, update, delete on table public.repair_prices to authenticated;

grant select on table public.services to anon;
grant select, insert, update, delete on table public.services to authenticated;

grant select on table public.site_settings to anon;
grant select, insert, update, delete on table public.site_settings to authenticated;

grant select on table public.user_directory to authenticated;
