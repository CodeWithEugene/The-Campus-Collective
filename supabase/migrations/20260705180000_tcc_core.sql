-- The Campus Collective — core backend
-- Thesis: the backend NEVER sees user data. It only ships things DOWN to the app
-- (model manifest, content packs, events) and accepts anonymous feedback UP.

-- =============================================================
-- 1. model_manifest — remote config for on-device model delivery
-- =============================================================
create table public.model_manifest (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,                       -- display name, e.g. 'Gemma 4 E2B'
  variant         text not null,                       -- 'e2b-base' | 'e2b-tcc' (fine-tuned)
  version         text not null,
  url             text not null,                       -- ungated public download URL
  size_bytes      bigint not null,
  sha256          text not null,
  min_app_version text not null default '1.0.0',
  channel         text not null default 'stable' check (channel in ('stable','beta')),
  is_active       boolean not null default false,
  created_at      timestamptz not null default now(),
  unique (variant, version)
);

-- =============================================================
-- 2. content_packs — versioned offline content the app refreshes when online
--    (campus corpus, safety contacts, tariffs, fares, phrasebook, faq, events)
-- =============================================================
create table public.content_packs (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null check (kind in
                 ('corpus','safety_contacts','mpesa_tariffs','matatu_fares',
                  'kiembu_phrasebook','faq')),
  version      int  not null,
  storage_path text not null,                          -- path inside the 'content' bucket
  sha256       text,
  size_bytes   bigint,
  notes        text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  unique (kind, version)
);

-- =============================================================
-- 3. feedback_reports — P44 "Report a problem" (anonymous, insert-only)
-- =============================================================
create table public.feedback_reports (
  id            uuid primary key default gen_random_uuid(),
  category      text not null check (category in ('bug','wrong_answer','idea','other')),
  description   text not null check (char_length(description) between 5 and 4000),
  device_info   jsonb,                                 -- only if user opted in
  app_version   text,
  model_version text,
  created_at    timestamptz not null default now()
);

-- =============================================================
-- 4. campus_events — Opportunity Radar feed (stretch feature, curated)
-- =============================================================
create table public.campus_events (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  starts_at  timestamptz,
  location   text,
  organizer  text,
  link       text,
  tags       text[] not null default '{}',
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

-- =============================================================
-- RLS — anon key can read distribution tables and insert feedback. Nothing else.
-- =============================================================
alter table public.model_manifest  enable row level security;
alter table public.content_packs   enable row level security;
alter table public.feedback_reports enable row level security;
alter table public.campus_events   enable row level security;

create policy "anon read active models"
  on public.model_manifest for select
  to anon, authenticated
  using (is_active);

create policy "anon read active packs"
  on public.content_packs for select
  to anon, authenticated
  using (is_active);

create policy "anon read active events"
  on public.campus_events for select
  to anon, authenticated
  using (is_active);

create policy "anon insert feedback"
  on public.feedback_reports for insert
  to anon, authenticated
  with check (true);
-- (no select/update/delete policies on feedback_reports: write-only mailbox)

-- =============================================================
-- Storage: public 'content' bucket for content packs (small JSON/db files).
-- The 2.6 GB model binary is NOT stored here (free-tier limits + egress cost);
-- model_manifest.url points at an ungated public mirror (our HF repo).
-- =============================================================
insert into storage.buckets (id, name, public)
values ('content', 'content', true)
on conflict (id) do nothing;

create policy "public read content bucket"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'content');
