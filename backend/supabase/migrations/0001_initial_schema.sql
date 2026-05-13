-- Discovery-pET - Initial database schema
-- Target: Supabase PostgreSQL

create extension if not exists "pgcrypto";

-- User roles
create type public.user_role as enum (
  'user',
  'volunteer',
  'shelter',
  'vet',
  'admin'
);

-- Animal/report enums
create type public.animal_type as enum (
  'dog',
  'cat',
  'other'
);

create type public.report_category as enum (
  'lost',
  'seen',
  'abandoned',
  'rescued',
  'adoption',
  'injured'
);

create type public.report_status as enum (
  'reported',
  'searching',
  'recently_seen',
  'someone_going',
  'sheltered',
  'vet_care',
  'foster_home',
  'adoption',
  'adopted',
  'reunited',
  'closed_unresolved',
  'invalid'
);

create type public.urgency_level as enum (
  'low',
  'medium',
  'high'
);

create type public.flag_status as enum (
  'pending',
  'reviewed',
  'dismissed',
  'accepted'
);

create type public.adoption_request_status as enum (
  'pending',
  'contacted',
  'approved',
  'rejected',
  'cancelled'
);

-- Profiles
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  phone text,
  role public.user_role not null default 'user',
  city text,
  avatar_url text,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Reports
create table public.animal_reports (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  animal_type public.animal_type not null,
  category public.report_category not null,
  title text not null,
  description text,
  status public.report_status not null default 'reported',
  urgency public.urgency_level not null default 'medium',
  latitude numeric(10, 7) not null,
  longitude numeric(10, 7) not null,
  approximate_address text,
  contact_phone text,
  show_contact_phone boolean not null default false,
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz
);

create index idx_animal_reports_created_by on public.animal_reports(created_by);
create index idx_animal_reports_status on public.animal_reports(status);
create index idx_animal_reports_category on public.animal_reports(category);
create index idx_animal_reports_animal_type on public.animal_reports(animal_type);
create index idx_animal_reports_location on public.animal_reports(latitude, longitude);

-- Images
create table public.report_images (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.animal_reports(id) on delete cascade,
  image_url text not null,
  storage_path text,
  created_at timestamptz not null default now()
);

create index idx_report_images_report_id on public.report_images(report_id);

-- Updates / comments
create table public.report_updates (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.animal_reports(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  comment text,
  old_status public.report_status,
  new_status public.report_status,
  created_at timestamptz not null default now()
);

create index idx_report_updates_report_id on public.report_updates(report_id);

-- Adoption requests
create table public.adoption_requests (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.animal_reports(id) on delete cascade,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  message text,
  status public.adoption_request_status not null default 'pending',
  created_at timestamptz not null default now()
);

create index idx_adoption_requests_report_id on public.adoption_requests(report_id);
create index idx_adoption_requests_requester_id on public.adoption_requests(requester_id);

-- Flags / reports
create table public.report_flags (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.animal_reports(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  status public.flag_status not null default 'pending',
  created_at timestamptz not null default now()
);

create index idx_report_flags_report_id on public.report_flags(report_id);
create index idx_report_flags_status on public.report_flags(status);

-- updated_at helper
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger set_animal_reports_updated_at
before update on public.animal_reports
for each row execute function public.set_updated_at();

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.animal_reports enable row level security;
alter table public.report_images enable row level security;
alter table public.report_updates enable row level security;
alter table public.adoption_requests enable row level security;
alter table public.report_flags enable row level security;

-- Basic policies
create policy "Profiles are viewable by authenticated users"
on public.profiles for select
to authenticated
using (true);

create policy "Users can update own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

create policy "Public visible reports are readable"
on public.animal_reports for select
to authenticated
using (is_public = true or created_by = auth.uid());

create policy "Users can create reports"
on public.animal_reports for insert
to authenticated
with check (created_by = auth.uid());

create policy "Users can update own reports"
on public.animal_reports for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

create policy "Images are readable for authenticated users"
on public.report_images for select
to authenticated
using (true);

create policy "Users can add images to own reports"
on public.report_images for insert
to authenticated
with check (
  exists (
    select 1 from public.animal_reports ar
    where ar.id = report_id
      and ar.created_by = auth.uid()
  )
);

create policy "Updates are readable for authenticated users"
on public.report_updates for select
to authenticated
using (true);

create policy "Users can add updates"
on public.report_updates for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can create adoption requests"
on public.adoption_requests for insert
to authenticated
with check (requester_id = auth.uid());

create policy "Users can see own adoption requests"
on public.adoption_requests for select
to authenticated
using (requester_id = auth.uid());

create policy "Users can flag reports"
on public.report_flags for insert
to authenticated
with check (user_id = auth.uid());

create policy "Users can see own flags"
on public.report_flags for select
to authenticated
using (user_id = auth.uid());
