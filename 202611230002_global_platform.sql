-- Worldwide public profiles, consultations, verified reviews, community and moderation.
-- Public profile fields are intentionally separated from private contact/payment data.
alter table public.profiles add column if not exists headline text;
alter table public.profiles add column if not exists portfolio_url text;
alter table public.profiles add column if not exists skills text[] not null default '{}';
alter table public.profiles add column if not exists guidance_topics text[] not null default '{}';
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

create table if not exists public.consultations (
 id uuid primary key default gen_random_uuid(),
 mentor_id uuid not null references public.profiles(id) on delete restrict,
 student_id uuid not null references auth.users(id) on delete cascade,
 topic text not null check (char_length(topic) between 3 and 160),
 starts_at timestamptz not null,
 duration_minutes int not null default 30 check (duration_minutes between 15 and 120),
 status text not null default 'requested' check (status in ('requested','accepted','declined','completed','cancelled')),
 private_meeting_url text,
 completed_at timestamptz,
 created_at timestamptz not null default now(),
 check (mentor_id <> student_id)
);
create index if not exists consultations_mentor_time_idx on public.consultations(mentor_id, starts_at desc);
create index if not exists consultations_student_time_idx on public.consultations(student_id, starts_at desc);

create table if not exists public.mentor_reviews (
 id uuid primary key default gen_random_uuid(),
 consultation_id uuid not null unique references public.consultations(id) on delete cascade,
 mentor_id uuid not null references public.profiles(id) on delete cascade,
 reviewer_id uuid not null references auth.users(id) on delete cascade,
 rating int not null check (rating between 1 and 5),
 body text not null check (char_length(body) between 10 and 2000),
 status text not null default 'pending' check (status in ('pending','approved','rejected','removed')),
 moderated_by uuid references auth.users(id) on delete set null,
 moderated_at timestamptz,
 created_at timestamptz not null default now(),
 unique(consultation_id, reviewer_id)
);
create index if not exists mentor_reviews_public_idx on public.mentor_reviews(mentor_id, created_at desc) where status='approved';

create table if not exists public.community_posts (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(body) between 1 and 4000),
 status text not null default 'pending' check (status in ('pending','published','removed')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists community_posts_public_idx on public.community_posts(created_at desc) where status='published';
create table if not exists public.community_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.community_posts(id) on delete cascade,
 author_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(body) between 1 and 2000),
 status text not null default 'pending' check (status in ('pending','published','removed')),
 created_at timestamptz not null default now()
);
create index if not exists community_comments_post_idx on public.community_comments(post_id, created_at);

create table if not exists public.content_reports (
 id uuid primary key default gen_random_uuid(),
 reporter_id uuid not null references auth.users(id) on delete cascade,
 target_type text not null check (target_type in ('profile','review','post','comment')),
 target_id uuid not null,
 reason text not null check (char_length(reason) between 5 and 500),
 status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
 handled_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now()
);
create table if not exists public.payment_records (
 id uuid primary key default gen_random_uuid(),
 consultation_id uuid references public.consultations(id) on delete set null,
 payer_id uuid references auth.users(id) on delete set null,
 provider text not null default 'stripe',
 provider_reference text unique,
 amount_minor bigint not null check (amount_minor >= 0),
 currency text not null check (currency ~ '^[A-Z]{3}$'),
 status text not null check (status in ('pending','succeeded','failed','refunded')),
 created_at timestamptz not null default now()
);

alter table public.consultations enable row level security;
alter table public.mentor_reviews enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
alter table public.content_reports enable row level security;
alter table public.payment_records enable row level security;

create policy "participants and staff read consultations" on public.consultations for select using (student_id=auth.uid() or mentor_id=auth.uid() or public.is_staff());
create policy "students request consultations" on public.consultations for insert with check (student_id=auth.uid() and exists(select 1 from public.profiles p where p.id=mentor_id and p.role='mentor' and p.is_public));
create policy "participants update consultation state" on public.consultations for update using (student_id=auth.uid() or mentor_id=auth.uid() or public.is_staff()) with check (student_id=auth.uid() or mentor_id=auth.uid() or public.is_staff());
create policy "approved reviews are public" on public.mentor_reviews for select using (status='approved' or reviewer_id=auth.uid() or public.is_staff());
create policy "reviewer inserts own review for completed consultation" on public.mentor_reviews for insert with check (reviewer_id=auth.uid() and status='pending' and exists(select 1 from public.consultations c where c.id=consultation_id and c.student_id=auth.uid() and c.mentor_id=mentor_reviews.mentor_id and c.status='completed'));
create policy "staff moderate reviews" on public.mentor_reviews for update using (public.is_staff()) with check (public.is_staff());
create policy "published posts are public" on public.community_posts for select using (status='published' or author_id=auth.uid() or public.is_staff());
create policy "signed in users create pending posts" on public.community_posts for insert with check (author_id=auth.uid() and status='pending');
create policy "authors edit own pending posts" on public.community_posts for update using (author_id=auth.uid() and status='pending' or public.is_staff()) with check (author_id=auth.uid() or public.is_staff());
create policy "published comments are public" on public.community_comments for select using (status='published' or author_id=auth.uid() or public.is_staff());
create policy "signed in users create pending comments" on public.community_comments for insert with check (author_id=auth.uid() and status='pending' and exists(select 1 from public.community_posts p where p.id=post_id and p.status='published'));
create policy "staff moderate comments" on public.community_comments for update using (public.is_staff()) with check (public.is_staff());
create policy "reporters and staff read reports" on public.content_reports for select using (reporter_id=auth.uid() or public.is_staff());
create policy "signed in users file reports" on public.content_reports for insert with check (reporter_id=auth.uid() and status='open');
create policy "staff handle reports" on public.content_reports for update using (public.is_staff()) with check (public.is_staff());
create policy "users read own payments" on public.payment_records for select using (payer_id=auth.uid() or public.is_staff());
create policy "service role manages payment records" on public.payment_records for all using (auth.role()='service_role') with check (auth.role()='service_role');

-- Prevent a review from being submitted before the consultation is marked completed.
create or replace function public.guard_verified_review() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if not exists(select 1 from public.consultations c where c.id=new.consultation_id and c.student_id=new.reviewer_id and c.mentor_id=new.mentor_id and c.status='completed') then
  raise exception 'A verified review requires a completed consultation';
 end if;
 return new;
end $$;
drop trigger if exists verified_review_guard on public.mentor_reviews;
create trigger verified_review_guard before insert on public.mentor_reviews for each row execute function public.guard_verified_review();

-- Only staff can change moderation state or mark consultations completed; clients cannot self-verify.
create or replace function public.guard_consultation_completion() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.status='completed' and old.status is distinct from 'completed' and not public.is_staff() then
  raise exception 'Only staff can verify consultation completion';
 end if;
 if new.student_id <> old.student_id or new.mentor_id <> old.mentor_id then raise exception 'Consultation participants cannot be changed'; end if;
 if new.private_meeting_url is distinct from old.private_meeting_url and auth.uid() not in (old.student_id,old.mentor_id) and not public.is_staff() then raise exception 'Not allowed'; end if;
 if new.status='completed' then new.completed_at=coalesce(new.completed_at,now()); end if;
 return new;
end $$;
drop trigger if exists consultation_completion_guard on public.consultations;
create trigger consultation_completion_guard before update on public.consultations for each row execute function public.guard_consultation_completion();

-- Public profile reads must select only public-safe columns in APIs. No email, phone or payment fields live here.

create or replace function public.handle_new_user_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,display_name,role,is_public) values(new.id,coalesce(new.raw_user_meta_data->>'display_name','New member'),'student',false) on conflict(id) do nothing;
 return new;
end $$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users for each row execute function public.handle_new_user_profile();

-- Replace permissive initial profile policy: users may edit their public fields but cannot self-promote.
drop policy if exists "users manage own profile" on public.profiles;
create policy "users update own profile without role escalation" on public.profiles for update
 using (id=auth.uid() or public.is_staff())
 with check ((id=auth.uid() and role in ('student','mentor')) or public.is_staff());
create policy "staff insert profiles when required" on public.profiles for insert with check (public.is_staff());

insert into public.system_settings(key,value) values
 ('auto_publish_enabled','false'::jsonb),
 ('min_confidence','0.95'::jsonb)
on conflict(key) do nothing;

alter table public.opportunities add column if not exists required_documents text[] not null default '{}';
alter table public.opportunities add column if not exists application_instructions text;
alter table public.opportunities add column if not exists missing_fields text[] not null default '{}';
alter table public.opportunity_duplicates add column if not exists merged_into_id uuid references public.opportunities(id) on delete set null;
create table if not exists public.ai_processing_logs (
 id uuid primary key default gen_random_uuid(),
 discovered_item_id uuid references public.discovered_items(id) on delete set null,
 opportunity_id uuid references public.opportunities(id) on delete set null,
 model text,
 status text not null check(status in ('succeeded','failed')),
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.ai_processing_logs enable row level security;
create policy "staff read ai processing logs" on public.ai_processing_logs for select using(public.is_staff());
create policy "service role writes ai processing logs" on public.ai_processing_logs for all using(auth.role()='service_role') with check(auth.role()='service_role');

-- Database-level spam throttles: limits are shared across serverless instances.
create or replace function public.enforce_aventiq_content_rate_limit() returns trigger language plpgsql security definer set search_path=public as $$
declare n integer; max_count integer; window_interval interval;
begin
 if tg_table_name='community_posts' then max_count:=5; window_interval:='1 hour';
 elsif tg_table_name='community_comments' then max_count:=20; window_interval:='1 hour';
 elsif tg_table_name='content_reports' then max_count:=10; window_interval:='1 hour';
 else return new; end if;
 if tg_table_name='community_posts' then select count(*) into n from public.community_posts where author_id=new.author_id and created_at>now()-window_interval;
 elsif tg_table_name='community_comments' then select count(*) into n from public.community_comments where author_id=new.author_id and created_at>now()-window_interval;
 else select count(*) into n from public.content_reports where reporter_id=new.reporter_id and created_at>now()-window_interval; end if;
 if n>=max_count then raise exception 'Rate limit reached. Please try again later.'; end if;
 return new;
end $$;
drop trigger if exists community_post_rate_limit on public.community_posts;
create trigger community_post_rate_limit before insert on public.community_posts for each row execute function public.enforce_aventiq_content_rate_limit();
drop trigger if exists community_comment_rate_limit on public.community_comments;
create trigger community_comment_rate_limit before insert on public.community_comments for each row execute function public.enforce_aventiq_content_rate_limit();
drop trigger if exists content_report_rate_limit on public.content_reports;
create trigger content_report_rate_limit before insert on public.content_reports for each row execute function public.enforce_aventiq_content_rate_limit();

create or replace function public.guard_consultation_completion() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.student_id <> old.student_id or new.mentor_id <> old.mentor_id then raise exception 'Consultation participants cannot be changed'; end if;
 if new.status='completed' and old.status is distinct from 'completed' and not public.is_staff() then raise exception 'Only staff can verify consultation completion'; end if;
 if new.status='accepted' and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can accept'; end if;
 if new.status='declined' and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can decline'; end if;
 if new.status='cancelled' and auth.uid() is distinct from old.student_id and not public.is_staff() then raise exception 'Only the student can cancel'; end if;
 if new.private_meeting_url is distinct from old.private_meeting_url and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can create the private meeting link'; end if;
 if new.status='completed' then new.completed_at=coalesce(new.completed_at,now()); end if;
 return new;
end $$;

-- Safety gate: only accounts whose adult status has been independently verified may enter 1:1 sessions.
-- This private field is not exposed by public profile APIs and cannot be set by the account owner.
alter table public.profiles add column if not exists age_verified_adult boolean not null default false;
drop policy if exists "students request consultations" on public.consultations;
create policy "verified adults request consultations" on public.consultations for insert with check (
 student_id=auth.uid()
 and exists(select 1 from public.profiles student where student.id=auth.uid() and student.age_verified_adult=true)
 and exists(select 1 from public.profiles mentor where mentor.id=mentor_id and mentor.role='mentor' and mentor.is_public=true and mentor.age_verified_adult=true)
);

-- Column-level privacy: age-verification status is never selectable or user-updatable.
revoke select on public.profiles from anon, authenticated;
grant select (id,display_name,headline,bio,avatar_url,country,portfolio_url,skills,guidance_topics,role,is_public,created_at,updated_at) on public.profiles to anon, authenticated;
revoke update on public.profiles from anon, authenticated;
grant update (display_name,headline,bio,avatar_url,country,portfolio_url,skills,guidance_topics,role,is_public,updated_at) on public.profiles to authenticated;

create or replace view public.public_profiles with (security_barrier=true) as
 select id,display_name,headline,bio,avatar_url,country,portfolio_url,skills,guidance_topics,role,created_at
 from public.profiles
 where is_public=true and (role='student' or (role='mentor' and age_verified_adult=true));
grant select on public.public_profiles to anon, authenticated;

create or replace function public.can_request_consultation(target_mentor uuid)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles s where s.id=auth.uid() and s.age_verified_adult=true)
 and exists(select 1 from public.profiles m where m.id=target_mentor and m.role='mentor' and m.is_public=true and m.age_verified_adult=true)
$$;
revoke all on function public.can_request_consultation(uuid) from public, anon;
grant execute on function public.can_request_consultation(uuid) to authenticated;

drop policy if exists "verified adults request consultations" on public.consultations;
create policy "verified adults request consultations" on public.consultations for insert with check (student_id=auth.uid() and public.can_request_consultation(mentor_id));

-- Consultation links are generated server-side on mentor acceptance and cannot be user-supplied.
revoke insert, update on public.consultations from anon, authenticated;
grant insert (mentor_id,student_id,topic,starts_at,duration_minutes,status) on public.consultations to authenticated;
grant update (status) on public.consultations to authenticated;
grant select (id,mentor_id,student_id,topic,starts_at,duration_minutes,status,private_meeting_url,completed_at,created_at) on public.consultations to authenticated;
create or replace function public.guard_consultation_completion() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.student_id <> old.student_id or new.mentor_id <> old.mentor_id then raise exception 'Consultation participants cannot be changed'; end if;
 if new.status='completed' and old.status is distinct from 'completed' and not public.is_staff() then raise exception 'Only staff can verify consultation completion'; end if;
 if new.status='accepted' and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can accept'; end if;
 if new.status='declined' and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can decline'; end if;
 if new.status='cancelled' and auth.uid() is distinct from old.student_id and not public.is_staff() then raise exception 'Only the student can cancel'; end if;
 if new.status='accepted' and old.status='requested' then new.private_meeting_url='https://meet.jit.si/aventiq-'||gen_random_uuid()::text;
 elsif new.private_meeting_url is distinct from old.private_meeting_url then raise exception 'Meeting links are generated by the platform only'; end if;
 if new.status='completed' then new.completed_at=coalesce(new.completed_at,now()); end if;
 return new;
end $$;
revoke select on public.consultations from anon, authenticated;
grant select (id,mentor_id,student_id,topic,starts_at,duration_minutes,status,private_meeting_url,completed_at,created_at) on public.consultations to authenticated;

create or replace function public.limit_consultation_requests() returns trigger language plpgsql security definer set search_path=public as $$
declare n integer;
begin
 select count(*) into n from public.consultations where student_id=new.student_id and created_at>now()-interval '1 hour';
 if n>=5 then raise exception 'Consultation request rate limit reached. Try again later.'; end if;
 return new;
end $$;
drop trigger if exists consultation_request_rate_limit on public.consultations;
create trigger consultation_request_rate_limit before insert on public.consultations for each row execute function public.limit_consultation_requests();

-- Harden post moderation: authors may edit pending drafts but cannot self-publish.
drop policy if exists "authors edit own pending posts" on public.community_posts;
create policy "authors edit own pending posts" on public.community_posts for update
 using ((author_id=auth.uid() and status='pending') or public.is_staff())
 with check ((author_id=auth.uid() and status='pending') or public.is_staff());

-- Auditing is writable only by staff through authenticated server routes.
create policy "staff write audit logs" on public.audit_logs for insert with check (public.is_staff());

-- Notifications are recipient-private. Consultation notifications require a real participant event.
alter table public.notifications add column if not exists actor_id uuid references auth.users(id) on delete set null;
alter table public.notifications add column if not exists consultation_id uuid references public.consultations(id) on delete cascade;
drop policy if exists "users update own notifications" on public.notifications;
create policy "users update own notification read state" on public.notifications for update using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "participants create consultation notifications" on public.notifications for insert with check (
 actor_id=auth.uid() and exists(select 1 from public.consultations c where c.id=consultation_id and auth.uid() in (c.student_id,c.mentor_id) and user_id in (c.student_id,c.mentor_id))
);
create policy "staff create moderation notifications" on public.notifications for insert with check(public.is_staff());
revoke insert,update on public.notifications from anon,authenticated;
grant insert(user_id,actor_id,consultation_id,title,body) on public.notifications to authenticated;
grant update(read_at) on public.notifications to authenticated;

-- Consultation states cannot be reopened or rewritten by participants.
create or replace function public.guard_consultation_completion() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.student_id <> old.student_id or new.mentor_id <> old.mentor_id then raise exception 'Consultation participants cannot be changed'; end if;
 if old.status in ('declined','cancelled','completed') and new.status is distinct from old.status then raise exception 'This consultation is closed'; end if;
 if old.status='accepted' and new.status='requested' then raise exception 'Accepted consultations cannot be reopened'; end if;
 if new.status='completed' and old.status is distinct from 'completed' and not public.is_staff() then raise exception 'Only staff can verify consultation completion'; end if;
 if new.status='accepted' and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can accept'; end if;
 if new.status='declined' and auth.uid() is distinct from old.mentor_id and not public.is_staff() then raise exception 'Only the mentor can decline'; end if;
 if new.status='cancelled' and auth.uid() is distinct from old.student_id and not public.is_staff() then raise exception 'Only the student can cancel'; end if;
 if new.status='accepted' and old.status='requested' then new.private_meeting_url='https://meet.jit.si/aventiq-'||gen_random_uuid()::text;
 elsif new.private_meeting_url is distinct from old.private_meeting_url then raise exception 'Meeting links are generated by the platform only'; end if;
 if new.status='completed' then new.completed_at=coalesce(new.completed_at,now()); end if;
 return new;
end $$;

-- Preserve the original CSV values alongside normalized review fields during legacy import.
alter table public.opportunities add column if not exists legacy_status text;
alter table public.opportunities add column if not exists legacy_verification_status text;
alter table public.opportunities add column if not exists legacy_deadline text;
alter table public.opportunities add column if not exists legacy_url text;

create or replace view public.mentor_review_stats with (security_barrier=true) as
 select mentor_id,count(*)::integer as review_count,round(avg(rating)::numeric,2) as average_rating
 from public.mentor_reviews where status='approved' group by mentor_id;
grant select on public.mentor_review_stats to anon,authenticated;

create or replace function public.ensure_own_profile(p_display_name text)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 insert into public.profiles(id,display_name,role,is_public) values(auth.uid(),left(trim(coalesce(p_display_name,'New member')),80),'student',false) on conflict(id) do nothing;
end $$;
revoke all on function public.ensure_own_profile(text) from public,anon;
grant execute on function public.ensure_own_profile(text) to authenticated;
