-- RESPONSE · guarding & response software
-- PostgreSQL 15+ schema. Multi-tenant by company_id. UK guarding domain (SIA, BS 7984-3, WTR).

-- Supabase keeps extensions in their own schema; make sure types/functions resolve.
create schema if not exists extensions;
set search_path = public, extensions;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext   with schema extensions;   -- needed for users.email
create extension if not exists postgis  with schema extensions;

-- ───────────────────────── enums ─────────────────────────
create type user_role       as enum ('owner','admin','controller','supervisor','officer','client');
create type shift_status    as enum ('open','offered','accepted','published','booked_on','completed','no_show','cancelled');
create type shift_kind      as enum ('static','patrol','static_patrol','mobile','concierge','keyholding');
create type scan_method     as enum ('nfc','qr','beacon','gps','manual');
create type patrol_status   as enum ('scheduled','in_progress','completed','partial','missed');
create type incident_type   as enum ('intruder','damage','medical','fire','suspicious','theft','other');
create type incident_status as enum ('draft','new','needs_review','acknowledged','closed');
create type alarm_status    as enum ('received','offered','accepted','en_route','on_site','reset','closed','cancelled');
create type check_call_status as enum ('due','ok','help','missed','escalated');
create type sos_status      as enum ('active','acknowledged','resolved','cancelled');
create type welfare_rule    as enum ('interval','fixed_times');

-- ───────────────────────── tenancy & people ─────────────────────────
create table companies (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  sia_acs_no    text,                       -- Approved Contractor Scheme reference
  timezone      text not null default 'Europe/London',
  created_at    timestamptz not null default now()
);

create table users (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references companies(id) on delete cascade,
  role          user_role not null,
  full_name     text not null,
  email         citext unique,
  mobile        text unique,                -- E.164; officer app signs in by mobile + passcode
  passcode_hash text,
  face_id_enabled boolean not null default false,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);
create index on users (company_id, role);

create table officers (
  user_id           uuid primary key references users(id) on delete cascade,
  initials          text generated always as (upper(left(split_part(full_name_cache,' ',1),1) || left(split_part(full_name_cache,' ',2),1))) stored,
  full_name_cache   text not null,
  employment_start  date,
  pattern           text,                  -- 'Nights','Days','Mobile' — display only
  vehicle_callsign  text,                  -- 'RX-04'
  holiday_days_left numeric(4,1) default 0
);

create table sia_licences (
  id            uuid primary key default gen_random_uuid(),
  officer_id    uuid not null references officers(user_id) on delete cascade,
  sector        text not null,             -- 'Security Guarding','Door Supervisor','CCTV','Close Protection'
  licence_no    text not null,             -- store full; app shows masked
  expires_on    date not null,
  verified_at   timestamptz,
  unique (officer_id, sector)
);
create index on sia_licences (expires_on);

create table training_records (
  id          uuid primary key default gen_random_uuid(),
  officer_id  uuid not null references officers(user_id) on delete cascade,
  title       text not null,
  completed_on date not null,
  expires_on  date
);

-- ───────────────────────── clients & sites ─────────────────────────
create table clients (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references companies(id) on delete cascade,
  name        text not null,
  contact_name text, contact_phone text, contact_email text
);

create table client_users (                 -- client-portal logins
  user_id   uuid primary key references users(id) on delete cascade,
  client_id uuid not null references clients(id) on delete cascade
);

create table sites (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references companies(id) on delete cascade,
  client_id     uuid references clients(id) on delete set null,
  name          text not null,
  address       text,
  postcode      text,
  location      geography(point,4326),
  geofence_m    integer not null default 150,      -- book-on radius
  kind          shift_kind not null default 'static',
  contract_hours_per_week numeric(6,1),
  notes         text,                              -- site notes shown to officers/controllers
  is_active     boolean not null default true
);
create index on sites using gist (location);
create index on sites (company_id, client_id);

create table site_documents (               -- 'read before shift'
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references sites(id) on delete cascade,
  title       text not null,
  version     integer not null default 1,
  url         text,
  mandatory   boolean not null default true,
  published_at timestamptz not null default now()
);

create table document_acknowledgements (
  document_id uuid references site_documents(id) on delete cascade,
  officer_id  uuid references officers(user_id) on delete cascade,
  version     integer not null,
  read_at     timestamptz not null default now(),
  primary key (document_id, officer_id, version)
);

create table site_keys (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references sites(id) on delete cascade,
  tag         text not null,                -- 'K-114'
  nfc_uid     text unique,
  location    text                          -- 'Depot'
);

create table key_movements (
  id          uuid primary key default gen_random_uuid(),
  key_id      uuid not null references site_keys(id),
  officer_id  uuid not null references officers(user_id),
  alarm_job_id uuid,                        -- fk added below
  signed_out_at timestamptz not null default now(),
  returned_at  timestamptz
);

-- ───────────────────────── rota ─────────────────────────
create table shifts (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references companies(id) on delete cascade,
  site_id       uuid references sites(id),            -- null for mobile/patrol vehicles
  officer_id    uuid references officers(user_id),    -- null = open shift
  kind          shift_kind not null,
  starts_at     timestamptz not null,
  ends_at       timestamptz not null,
  status        shift_status not null default 'open',
  post_name     text,                                 -- 'Gate House'
  offered_to    uuid references officers(user_id),
  offered_at    timestamptz,
  booked_on_at  timestamptz,
  booked_on_location geography(point,4326),
  booked_off_at timestamptz,
  created_by    uuid references users(id),
  check (ends_at > starts_at)
);
create index on shifts (company_id, starts_at);
create index on shifts (officer_id, starts_at);
create index on shifts (site_id, starts_at);

-- Working Time Regulations: flag < 11h rest between consecutive shifts
create or replace view v_rest_breaches with (security_invoker = true) as
select s1.officer_id, s1.id as shift_id, s2.id as next_shift_id,
       s2.starts_at - s1.ends_at as rest
from shifts s1
join lateral (
  select * from shifts s2 where s2.officer_id = s1.officer_id and s2.starts_at > s1.ends_at
  order by s2.starts_at limit 1
) s2 on true
where s1.officer_id is not null and s2.starts_at - s1.ends_at < interval '11 hours';

-- ───────────────────────── patrols & checkpoints ─────────────────────────
create table patrol_routes (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references sites(id) on delete cascade,
  name        text not null,                -- 'Route B'
  grace_minutes integer not null default 5,
  is_active   boolean not null default true
);

create table checkpoints (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references sites(id) on delete cascade,
  name        text not null,                -- 'Loading Bay 3'
  tag_code    text not null,                -- 'LB3-A' (printed on tag)
  nfc_uid     text unique,
  qr_payload  text unique,
  beacon_uuid text, beacon_major int, beacon_minor int,
  location    geography(point,4326),
  is_damaged  boolean not null default false
);

create table route_checkpoints (            -- ordered checkpoints + expected offset from route start
  route_id      uuid references patrol_routes(id) on delete cascade,
  checkpoint_id uuid references checkpoints(id) on delete cascade,
  seq           integer not null,
  offset_minutes integer not null,
  primary key (route_id, checkpoint_id),
  unique (route_id, seq)
);

create table checkpoint_tasks (             -- 'Roller shutter closed', 'Fire exit clear?'
  id            uuid primary key default gen_random_uuid(),
  checkpoint_id uuid not null references checkpoints(id) on delete cascade,
  prompt        text not null,
  answer_type   text not null default 'yes_no' check (answer_type in ('yes_no','check','number','text','photo'))
);

create table patrols (
  id          uuid primary key default gen_random_uuid(),
  shift_id    uuid not null references shifts(id) on delete cascade,
  route_id    uuid not null references patrol_routes(id),
  officer_id  uuid not null references officers(user_id),
  scheduled_start timestamptz not null,
  started_at  timestamptz,
  completed_at timestamptz,
  status      patrol_status not null default 'scheduled'
);
create index on patrols (shift_id);
create index on patrols (scheduled_start);

create table checkpoint_scans (
  id            uuid primary key default gen_random_uuid(),
  patrol_id     uuid not null references patrols(id) on delete cascade,
  checkpoint_id uuid not null references checkpoints(id),
  officer_id    uuid not null references officers(user_id),
  scanned_at    timestamptz not null default now(),
  due_at        timestamptz,
  method        scan_method not null,
  location      geography(point,4326),
  gps_accuracy_m numeric(6,1),
  on_time       boolean generated always as (due_at is null or scanned_at <= due_at) stored,
  note          text
);
create index on checkpoint_scans (patrol_id, scanned_at);
create index on checkpoint_scans (checkpoint_id, scanned_at);

create table checkpoint_task_answers (
  scan_id   uuid references checkpoint_scans(id) on delete cascade,
  task_id   uuid references checkpoint_tasks(id),
  answer    text,
  primary key (scan_id, task_id)
);

-- ───────────────────────── welfare ─────────────────────────
create table welfare_policies (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references companies(id) on delete cascade,
  site_id         uuid references sites(id) on delete cascade,     -- null = company default
  rule            welfare_rule not null default 'interval',
  interval_minutes integer default 60,
  reply_window_minutes integer not null default 5,
  remind_after_minutes integer not null default 5,
  supervisor_after_minutes integer not null default 10,
  control_after_minutes integer not null default 15
);

create table check_calls (
  id          uuid primary key default gen_random_uuid(),
  shift_id    uuid not null references shifts(id) on delete cascade,
  officer_id  uuid not null references officers(user_id),
  due_at      timestamptz not null,
  responded_at timestamptz,
  status      check_call_status not null default 'due',
  escalated_to uuid references users(id),
  escalated_at timestamptz
);
create index on check_calls (status, due_at);

create table sos_events (
  id            uuid primary key default gen_random_uuid(),
  officer_id    uuid not null references officers(user_id),
  shift_id      uuid references shifts(id),
  raised_at     timestamptz not null default now(),
  location      geography(point,4326),
  status        sos_status not null default 'active',
  acknowledged_by uuid references users(id),
  acknowledged_at timestamptz,
  nearest_officer_id uuid references officers(user_id),
  audio_url     text,
  resolved_at   timestamptz,
  cancelled_with_passcode boolean
);

create table location_pings (               -- live map; partition by month in production
  officer_id  uuid not null references officers(user_id) on delete cascade,
  at          timestamptz not null default now(),
  location    geography(point,4326) not null,
  accuracy_m  numeric(6,1),
  battery_pct smallint,
  primary key (officer_id, at)
);

-- ───────────────────────── incidents ─────────────────────────
create table incidents (
  id            uuid primary key default gen_random_uuid(),
  ref           text unique,                          -- 'IR-4471' set by trigger
  company_id    uuid not null references companies(id) on delete cascade,
  site_id       uuid not null references sites(id),
  officer_id    uuid not null references officers(user_id),
  shift_id      uuid references shifts(id),
  type          incident_type not null,
  occurred_at   timestamptz not null default now(),
  location_text text,
  location      geography(point,4326),
  raw_notes     text,                                 -- officer's rough notes / transcript
  report        text,                                 -- AI-tidied, controller-approved
  police_ref    text,
  status        incident_status not null default 'new',
  action_needed text,
  acknowledged_by uuid references users(id),
  acknowledged_at timestamptz,
  created_at    timestamptz not null default now()
);
create index on incidents (company_id, occurred_at desc);
create index on incidents (site_id, status);

create table attachments (                  -- photos, voice notes, PDFs — polymorphic
  id          uuid primary key default gen_random_uuid(),
  owner_type  text not null check (owner_type in ('incident','checkpoint_scan','alarm_job','sos_event')),
  owner_id    uuid not null,
  kind        text not null check (kind in ('photo','audio','video','pdf','form')),
  url         text not null,
  taken_at    timestamptz,
  location    geography(point,4326),
  uploaded_by uuid references users(id)
);
create index on attachments (owner_type, owner_id);

-- ───────────────────────── alarm response (BS 7984-3) ─────────────────────────
create table alarm_jobs (
  id            uuid primary key default gen_random_uuid(),
  ref           text unique,                          -- 'AR-20931'
  company_id    uuid not null references companies(id) on delete cascade,
  site_id       uuid not null references sites(id),
  arc_ref       text,                                 -- alarm receiving centre reference
  zone          text,                                 -- 'Zone 3 · rear loading door'
  alarm_type    text not null default 'intruder',
  received_at   timestamptz not null default now(),
  officer_id    uuid references officers(user_id),
  key_id        uuid references site_keys(id),
  status        alarm_status not null default 'received',
  eta_at        timestamptz,
  arrived_at    timestamptz,
  arrival_scan_id uuid references checkpoint_scans(id),
  closed_at     timestamptz,
  client_notified_at timestamptz,
  created_by    uuid references users(id)
);
create index on alarm_jobs (company_id, status, received_at desc);
alter table key_movements add constraint key_movements_job_fk foreign key (alarm_job_id) references alarm_jobs(id);

create table alarm_job_events (             -- the timeline
  id          uuid primary key default gen_random_uuid(),
  job_id      uuid not null references alarm_jobs(id) on delete cascade,
  at          timestamptz not null default now(),
  event       text not null,                -- 'signal_received','offered','accepted','keys_out','client_notified','arrived','perimeter_checked','reset','keys_returned','closed'
  detail      text,
  actor_id    uuid references users(id)
);
create index on alarm_job_events (job_id, at);

-- ───────────────────────── control room feed ─────────────────────────
create table events (                       -- denormalised live feed; written by triggers/app
  id          bigserial primary key,
  company_id  uuid not null references companies(id) on delete cascade,
  at          timestamptz not null default now(),
  kind        text not null check (kind in ('alarm','warn','ok','info')),
  title       text not null,
  subtitle    text,
  site_id     uuid references sites(id),
  officer_id  uuid references officers(user_id),
  ref_type    text, ref_id uuid
);
create index on events (company_id, at desc);

-- ───────────────────────── reference sequences ─────────────────────────
create sequence incident_ref_seq start 4471;
create sequence alarm_ref_seq    start 20931;

create or replace function set_incident_ref() returns trigger language plpgsql as $$
begin if new.ref is null then new.ref := 'IR-' || nextval('incident_ref_seq'); end if; return new; end $$;
create trigger trg_incident_ref before insert on incidents for each row execute function set_incident_ref();

create or replace function set_alarm_ref() returns trigger language plpgsql as $$
begin if new.ref is null then new.ref := 'AR-' || nextval('alarm_ref_seq'); end if; return new; end $$;
create trigger trg_alarm_ref before insert on alarm_jobs for each row execute function set_alarm_ref();

-- push a feed row when a checkpoint is scanned
create or replace function feed_on_scan() returns trigger language plpgsql as $$
declare v_company uuid; v_site uuid; v_cp text; v_name text;
begin
  select s.company_id, s.id, c.name into v_company, v_site, v_cp
    from checkpoints c join sites s on s.id = c.site_id where c.id = new.checkpoint_id;
  select full_name_cache into v_name from officers where user_id = new.officer_id;
  insert into events (company_id, at, kind, title, subtitle, site_id, officer_id, ref_type, ref_id)
  values (v_company, new.scanned_at, case when new.on_time then 'ok' else 'warn' end,
          'Checkpoint scanned · ' || v_cp, v_name || ' · ' || upper(new.method::text) || case when new.on_time then ' · on time' else ' · late' end,
          v_site, new.officer_id, 'checkpoint_scan', new.id);
  return new;
end $$;
create trigger trg_feed_scan after insert on checkpoint_scans for each row execute function feed_on_scan();

-- ───────────────────────── reporting views ─────────────────────────
create or replace view v_site_patrol_compliance with (security_invoker = true) as
select s.id as site_id, s.name, s.client_id,
       count(distinct p.id) filter (where p.status = 'completed') as patrols_completed,
       count(distinct p.id) as patrols_scheduled,
       count(cs.id) as checkpoints_scanned,
       round(100.0 * count(cs.id) filter (where cs.on_time) / nullif(count(cs.id),0), 1) as on_time_pct
from sites s
left join patrols p on p.route_id in (select id from patrol_routes where site_id = s.id)
     and p.scheduled_start >= now() - interval '7 days'
left join checkpoint_scans cs on cs.patrol_id = p.id
group by s.id;

create or replace view v_officers_on_shift with (security_invoker = true) as
select o.user_id, o.full_name_cache as name, sh.id as shift_id, si.name as site,
       sh.booked_on_at, sh.ends_at,
       (select status from check_calls cc where cc.shift_id = sh.id order by due_at desc limit 1) as last_check_call,
       exists (select 1 from sos_events x where x.officer_id = o.user_id and x.status = 'active') as sos_active
from officers o
join shifts sh on sh.officer_id = o.user_id and sh.status = 'booked_on' and now() between sh.starts_at - interval '1 hour' and sh.ends_at + interval '1 hour'
left join sites si on si.id = sh.site_id;

-- ───────────────────────── row-level security (multi-tenant) ─────────────────────────
alter table sites enable row level security;
alter table shifts enable row level security;
alter table incidents enable row level security;
alter table alarm_jobs enable row level security;
alter table events enable row level security;
-- app sets: set local app.company_id = '<uuid>';
create policy tenant_sites     on sites      using (company_id = current_setting('app.company_id', true)::uuid);
create policy tenant_shifts    on shifts     using (company_id = current_setting('app.company_id', true)::uuid);
create policy tenant_incidents on incidents  using (company_id = current_setting('app.company_id', true)::uuid);
create policy tenant_alarms    on alarm_jobs using (company_id = current_setting('app.company_id', true)::uuid);
create policy tenant_events    on events     using (company_id = current_setting('app.company_id', true)::uuid);

-- ───────────────────────── lock down every other table ─────────────────────────
-- Supabase exposes the public schema over its API. With RLS on and no policy, a table
-- is only reachable by the service role / server code, not by the public anon key.
do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;
