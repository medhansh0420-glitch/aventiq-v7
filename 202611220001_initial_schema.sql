-- AventIQ initial production foundation. Apply with Supabase CLI or SQL editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  bio text,
  avatar_url text,
  country text,
  role text not null default 'student' check (role in ('student','mentor','admin','moderator')),
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.opportunity_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  url text not null unique,
  source_type text not null check (source_type in ('rss','atom','api','json','webpage')),
  category text,
  reliability numeric(3,2) not null default 0.5 check (reliability between 0 and 1),
  is_active boolean not null default true,
  scan_interval_minutes integer not null default 1440 check (scan_interval_minutes between 15 and 43200),
  last_scanned_at timestamptz,
  last_scan_result text,
  created_at timestamptz not null default now()
);

create table if not exists public.opportunities (
  id uuid primary key default gen_random_uuid(),
  legacy_id text unique,
  title text not null,
  description text,
  organization text,
  category text,
  subcategory text,
  location text,
  country text,
  eligibility text,
  target_audience text,
  funding_amount text,
  benefits text,
  start_date date,
  deadline date,
  application_url text,
  official_source_url text,
  status text not null default 'pending_review' check (status in ('draft','pending_review','published','rejected','archived')),
  confidence numeric(4,3) check (confidence between 0 and 1),
  confidence_explanation jsonb not null default '[]'::jsonb,
  last_verified_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists opportunities_publication_idx on public.opportunities(status, published_at desc);
create index if not exists opportunities_category_country_idx on public.opportunities(category, country);
create index if not exists opportunities_deadline_idx on public.opportunities(deadline);

create table if not exists public.discovery_runs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references public.opportunity_sources(id) on delete set null,
  status text not null default 'queued' check (status in ('queued','running','succeeded','failed')),
  items_found integer not null default 0,
  items_created integer not null default 0,
  error_message text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.discovered_items (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references public.opportunity_sources(id) on delete set null,
  discovery_run_id uuid references public.discovery_runs(id) on delete set null,
  external_hash text not null unique,
  raw_payload jsonb not null default '{}'::jsonb,
  processing_status text not null default 'pending' check (processing_status in ('pending','processed','rejected','failed')),
  opportunity_id uuid references public.opportunities(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.opportunity_duplicates (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  possible_duplicate_id uuid not null references public.opportunities(id) on delete cascade,
  similarity numeric(4,3) not null check (similarity between 0 and 1),
  resolution text check (resolution in ('merged','separate','unresolved')),
  unique(opportunity_id, possible_duplicate_id),
  check (opportunity_id <> possible_duplicate_id)
);
create table if not exists public.verification_logs (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid references public.opportunities(id) on delete cascade,
  check_type text not null,
  result text not null,
  details jsonb not null default '{}'::jsonb,
  checked_at timestamptz not null default now()
);
create table if not exists public.admin_reviews (
  id uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  reviewer_id uuid references public.profiles(id) on delete set null,
  decision text not null check (decision in ('approved','rejected','needs_changes')),
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.saved_opportunities (
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, opportunity_id)
);
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists public.processing_jobs (
  id uuid primary key default gen_random_uuid(),
  job_type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued' check (status in ('queued','running','succeeded','failed')),
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  locked_at timestamptz,
  last_error text,
  created_at timestamptz not null default now()
);
create table if not exists public.system_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.profiles where id = auth.uid() and role in ('admin','moderator')) $$;

alter table public.profiles enable row level security;
alter table public.opportunity_sources enable row level security;
alter table public.opportunities enable row level security;
alter table public.discovery_runs enable row level security;
alter table public.discovered_items enable row level security;
alter table public.opportunity_duplicates enable row level security;
alter table public.verification_logs enable row level security;
alter table public.admin_reviews enable row level security;
alter table public.saved_opportunities enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
alter table public.processing_jobs enable row level security;
alter table public.system_settings enable row level security;

create policy "public profiles visible only when opted in" on public.profiles for select using (is_public or id = auth.uid() or public.is_staff());
create policy "users manage own profile" on public.profiles for all using (id = auth.uid() or public.is_staff()) with check (id = auth.uid() or public.is_staff());
create policy "published opportunities are public" on public.opportunities for select using (status = 'published' or public.is_staff());
create policy "staff manage opportunities" on public.opportunities for all using (public.is_staff()) with check (public.is_staff());
create policy "staff manage sources" on public.opportunity_sources for all using (public.is_staff()) with check (public.is_staff());
create policy "staff view discovery runs" on public.discovery_runs for select using (public.is_staff());
create policy "staff manage discovered items" on public.discovered_items for all using (public.is_staff()) with check (public.is_staff());
create policy "staff manage duplicates" on public.opportunity_duplicates for all using (public.is_staff()) with check (public.is_staff());
create policy "staff view verification logs" on public.verification_logs for select using (public.is_staff());
create policy "staff manage admin reviews" on public.admin_reviews for all using (public.is_staff()) with check (public.is_staff());
create policy "users manage own saved opportunities" on public.saved_opportunities for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users view own notifications" on public.notifications for select using (user_id = auth.uid());
create policy "users update own notifications" on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "staff view audit logs" on public.audit_logs for select using (public.is_staff());
create policy "staff manage processing jobs" on public.processing_jobs for all using (public.is_staff()) with check (public.is_staff());
create policy "staff manage system settings" on public.system_settings for all using (public.is_staff()) with check (public.is_staff());

-- Never grant anon access to private source, processing, or administrative tables.
