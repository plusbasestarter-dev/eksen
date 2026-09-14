-- EKSEN 3.0 initial schema
-- Apply only to a dedicated EKSEN Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.student_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  grade text not null check (grade in ('11','12','graduate')),
  track text not null check (track in ('sayisal','ea','sozel','dil')),
  exam_year smallint not null default 2027,
  weekly_capacity_minutes integer not null default 900 check (weekly_capacity_minutes between 60 and 6000),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.curriculum_courses (
  id uuid primary key default gen_random_uuid(),
  course_key text not null unique, name text not null, short_name text,
  exam_class text not null check (exam_class in ('TYT','AYT','YDT')),
  test_group text not null, sort_order smallint not null default 0,
  curriculum_version text not null default 'eksen-2027.1', active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.curriculum_units (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.curriculum_courses(id) on delete cascade,
  unit_key text not null unique, title text not null, grade_scope text,
  framework text not null default 'hybrid-2026-27', engine_family text not null,
  sort_order smallint not null default 0, created_at timestamptz not null default now()
);

create table if not exists public.curriculum_topics (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references public.curriculum_units(id) on delete cascade,
  topic_key text not null unique, title text not null, grade_scope text,
  exam_type text not null check (exam_type in ('TYT','AYT','YDT')),
  engine_key text not null, official_mapping_status text not null default 'normalized'
    check (official_mapping_status in ('normalized','mapped','verified')),
  sort_order smallint not null default 0, active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.topic_progress (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  topic_id uuid not null references public.curriculum_topics(id) on delete cascade,
  mastery numeric(5,4) not null default .25 check (mastery between 0 and 1),
  attempts integer not null default 0, correct integer not null default 0,
  last_seen_at timestamptz, next_review_at timestamptz,
  updated_at timestamptz not null default now(), unique(user_id,topic_id)
);

create table if not exists public.learning_events (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  event_type text not null, correctness boolean, confidence smallint check (confidence between 1 and 5),
  duration_ms integer check (duration_ms is null or duration_ms >= 0),
  engine_key text, payload jsonb not null default '{}'::jsonb, occurred_at timestamptz not null default now()
);

create table if not exists public.error_dna (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  error_type text not null, probability numeric(5,4) check (probability between 0 and 1),
  reason_codes text[] not null default '{}', corrected_by_user boolean,
  created_at timestamptz not null default now()
);

create table if not exists public.review_schedule (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  topic_id uuid not null references public.curriculum_topics(id) on delete cascade,
  due_at timestamptz not null, interval_days numeric(7,2) not null default 1,
  recall_probability numeric(5,4) check (recall_probability between 0 and 1),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  status text not null default 'pending' check (status in ('pending','done','snoozed','cancelled')),
  created_at timestamptz not null default now(), completed_at timestamptz
);

create table if not exists public.study_plans (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  plan_date date not null, capacity_minutes integer not null,
  mode text not null default 'normal' check (mode in ('normal','minimum','recovery','exam_week')),
  inputs jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), unique(user_id,plan_date)
);

create table if not exists public.study_plan_tasks (
  id uuid primary key default gen_random_uuid(), plan_id uuid not null references public.study_plans(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  topic_id uuid references public.curriculum_topics(id) on delete set null,
  task_type text not null, title text not null, minutes integer not null check (minutes between 1 and 360),
  priority_score numeric(8,4), rationale text,
  status text not null default 'pending' check (status in ('pending','active','done','skipped')),
  completed_at timestamptz, created_at timestamptz not null default now()
);

create table if not exists public.mock_exams (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  exam_type text not null check (exam_type in ('TYT','AYT','YDT')), exam_date date not null,
  total_net numeric(6,2), total_minutes integer, analysis jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_recommendations (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  recommendation_type text not null, input_snapshot jsonb not null default '{}'::jsonb,
  output jsonb not null default '{}'::jsonb, confidence numeric(5,4) check (confidence between 0 and 1),
  reason_codes text[] not null default '{}', accepted boolean, outcome jsonb,
  created_at timestamptz not null default now()
);

alter table public.student_profiles enable row level security;
alter table public.curriculum_courses enable row level security;
alter table public.curriculum_units enable row level security;
alter table public.curriculum_topics enable row level security;
alter table public.topic_progress enable row level security;
alter table public.learning_events enable row level security;
alter table public.error_dna enable row level security;
alter table public.review_schedule enable row level security;
alter table public.study_plans enable row level security;
alter table public.study_plan_tasks enable row level security;
alter table public.mock_exams enable row level security;
alter table public.ai_recommendations enable row level security;

grant select on public.curriculum_courses, public.curriculum_units, public.curriculum_topics to authenticated;
drop policy if exists "curriculum courses read" on public.curriculum_courses;
create policy "curriculum courses read" on public.curriculum_courses for select to authenticated using (active);
drop policy if exists "curriculum units read" on public.curriculum_units;
create policy "curriculum units read" on public.curriculum_units for select to authenticated using (true);
drop policy if exists "curriculum topics read" on public.curriculum_topics;
create policy "curriculum topics read" on public.curriculum_topics for select to authenticated using (active);

grant select,insert,update,delete on public.student_profiles, public.topic_progress, public.learning_events,
  public.error_dna, public.review_schedule, public.study_plans, public.study_plan_tasks, public.mock_exams,
  public.ai_recommendations to authenticated;

do $$
declare t text;
begin
  foreach t in array array['student_profiles','topic_progress','learning_events','error_dna','review_schedule','study_plans','study_plan_tasks','mock_exams','ai_recommendations'] loop
    execute format('drop policy if exists %I on public.%I', 'eksen_'||t||'_select', t);
    execute format('drop policy if exists %I on public.%I', 'eksen_'||t||'_insert', t);
    execute format('drop policy if exists %I on public.%I', 'eksen_'||t||'_update', t);
    execute format('drop policy if exists %I on public.%I', 'eksen_'||t||'_delete', t);
    execute format('create policy %I on public.%I for select to authenticated using ((select auth.uid()) = user_id)', 'eksen_'||t||'_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check ((select auth.uid()) = user_id)', 'eksen_'||t||'_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)', 'eksen_'||t||'_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using ((select auth.uid()) = user_id)', 'eksen_'||t||'_delete', t);
  end loop;
end $$;

create index if not exists idx_topics_unit on public.curriculum_topics(unit_id,sort_order);
create index if not exists idx_progress_user_review on public.topic_progress(user_id,next_review_at);
create index if not exists idx_events_user_time on public.learning_events(user_id,occurred_at desc);
create index if not exists idx_errors_user_type on public.error_dna(user_id,error_type,created_at desc);
create index if not exists idx_reviews_due on public.review_schedule(user_id,status,due_at);
create index if not exists idx_mock_user_date on public.mock_exams(user_id,exam_date desc);
