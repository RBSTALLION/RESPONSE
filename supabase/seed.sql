-- RESPONSE · demo seed (matches the prototype's illustrative data)
-- Run after the schema migration. Coordinates are illustrative (Peterborough area).

begin;

set local search_path = public, extensions;

insert into companies (id, name) values ('00000000-0000-0000-0000-000000000001', '[Company name]');
set local app.company_id = '00000000-0000-0000-0000-000000000001';

-- controllers
insert into users (id, company_id, role, full_name, email) values
 ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'controller', 'Dana Marsh', 'dana@company.example');

-- officers
insert into users (id, company_id, role, full_name, mobile) values
 ('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','officer','Daniel Owusu','+447700900482'),
 ('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','officer','Karan Patel','+447700900101'),
 ('20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','officer','Aleksander Novak','+447700900102'),
 ('20000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','officer','Jade Evans','+447700900103'),
 ('20000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000001','officer','Samira Hussain','+447700900104'),
 ('20000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000001','officer','Tom Brooks','+447700900105'),
 ('20000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000001','officer','Leah Grant','+447700900106');

insert into officers (user_id, full_name_cache, employment_start, pattern, vehicle_callsign, holiday_days_left) values
 ('20000000-0000-0000-0000-000000000001','Daniel Owusu','2023-02-01','Nights',null,14),
 ('20000000-0000-0000-0000-000000000002','Karan Patel','2021-06-14','Mobile','RX-04',9),
 ('20000000-0000-0000-0000-000000000003','Aleksander Novak','2022-09-05','Nights',null,11),
 ('20000000-0000-0000-0000-000000000004','Jade Evans','2020-03-30','Days',null,6),
 ('20000000-0000-0000-0000-000000000005','Samira Hussain','2024-01-08','Days',null,18),
 ('20000000-0000-0000-0000-000000000006','Tom Brooks','2019-11-11','Nights',null,3),
 ('20000000-0000-0000-0000-000000000007','Leah Grant','2023-07-17','Days',null,12);

insert into sia_licences (officer_id, sector, licence_no, expires_on, verified_at) values
 ('20000000-0000-0000-0000-000000000001','Security Guarding','1017000000002291','2028-03-14',now()),
 ('20000000-0000-0000-0000-000000000002','Door Supervisor','1017000000004410','2027-06-02',now()),
 ('20000000-0000-0000-0000-000000000003','Security Guarding','1017000000000871','2027-11-19',now()),
 ('20000000-0000-0000-0000-000000000004','Security Guarding','1017000000007732','2029-01-30',now()),
 ('20000000-0000-0000-0000-000000000005','Security Guarding','1017000000005519','2027-08-08',now()),
 ('20000000-0000-0000-0000-000000000006','Security Guarding','1017000000003306','2026-10-12',now()),
 ('20000000-0000-0000-0000-000000000007','Security Guarding','1017000000009925','2028-05-22',now());

-- clients (anonymised) & sites
insert into clients (id, company_id, name) values
 ('30000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-000000000001','[Client A]'),
 ('30000000-0000-0000-0000-00000000000b','00000000-0000-0000-0000-000000000001','[Client B]'),
 ('30000000-0000-0000-0000-00000000000c','00000000-0000-0000-0000-000000000001','[Client C]'),
 ('30000000-0000-0000-0000-00000000000d','00000000-0000-0000-0000-000000000001','[Client D]'),
 ('30000000-0000-0000-0000-00000000000e','00000000-0000-0000-0000-000000000001','[Client E]'),
 ('30000000-0000-0000-0000-00000000000f','00000000-0000-0000-0000-000000000001','[Client F]'),
 ('30000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000001','[Client G]');

insert into sites (id, company_id, client_id, name, kind, location, contract_hours_per_week, notes) values
 ('40000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-00000000000a','Riverside Distribution Centre','static_patrol', st_setsrid(st_makepoint(-0.2525,52.5525),4326)::geography, 336, 'Gate House post. Bay 4 contractor access from 28 Sep.'),
 ('40000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-00000000000b','Northgate Retail Park','static', st_setsrid(st_makepoint(-0.2410,52.6015),4326)::geography, 168, null),
 ('40000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-00000000000c','Canal Wharf Apartments','concierge', st_setsrid(st_makepoint(-0.2445,52.5760),4326)::geography, 168, null),
 ('40000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-00000000000d','Hospital Car Park B','static', st_setsrid(st_makepoint(-0.2820,52.5850),4326)::geography, 168, null),
 ('40000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-00000000000e','Fengate Industrial Estate','keyholding', st_setsrid(st_makepoint(-0.2085,52.5685),4326)::geography, null, 'Enter via Gate 2 (code on key tag). Alarm panel inside rear fire door. Guard dog on adjacent site after 22:00.'),
 ('40000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-00000000000f','City Centre Office Campus','static_patrol', st_setsrid(st_makepoint(-0.2430,52.5730),4326)::geography, 336, null),
 ('40000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000010','Station Road Retail','mobile', st_setsrid(st_makepoint(-0.2005,52.5905),4326)::geography, 40, null);

-- Riverside documents, route and checkpoints
insert into site_documents (id, site_id, title, version) values
 ('50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Assignment instructions',4),
 ('50000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001','Fire procedure · Block B',1),
 ('50000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000001','Bay 4 contractor access',1);

insert into site_keys (id, site_id, tag, location) values
 ('51000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000005','K-114','Depot');

insert into patrol_routes (id, site_id, name) values
 ('60000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Route B');

with cps(seq, name, code, off) as (values
 (1,'Gate House','GH-A',0),(2,'Yard North','YN-A',8),(3,'Fuel Store','FS-A',16),(4,'Loading Bay 1','LB1-A',24),
 (5,'Loading Bay 2','LB2-A',32),(6,'Loading Bay 3','LB3-A',40),(7,'Bay 4','B4-A',48),(8,'Roof Access','RA-A',56),
 (9,'Plant Room','PR-A',64),(10,'Yard South','YS-A',72),(11,'Car Park','CP-A',80),(12,'Gate House (close)','GH-B',88)),
ins as (
  insert into checkpoints (site_id, name, tag_code)
  select '40000000-0000-0000-0000-000000000001', name, code from cps returning id, tag_code
)
insert into route_checkpoints (route_id, checkpoint_id, seq, offset_minutes)
select '60000000-0000-0000-0000-000000000001', ins.id, cps.seq, cps.off from ins join cps on cps.code = ins.tag_code;

insert into checkpoint_tasks (checkpoint_id, prompt, answer_type)
select id, p, t from checkpoints, (values ('Roller shutter closed','check'),('Trailers secured','check'),('Fire exit clear?','yes_no')) v(p,t)
where tag_code = 'LB3-A';

-- welfare policy: hourly check calls, 5/10/15 escalation
insert into welfare_policies (company_id, rule, interval_minutes) values ('00000000-0000-0000-0000-000000000001','interval',60);

-- tonight's shift for Daniel (booked on) and an open alarm job
insert into shifts (id, company_id, site_id, officer_id, kind, starts_at, ends_at, status, post_name, booked_on_at) values
 ('70000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','static_patrol', date_trunc('day',now()) + interval '22 hours', date_trunc('day',now()) + interval '30 hours','booked_on','Gate House', date_trunc('day',now()) + interval '21 hours 56 minutes'),
 ('70000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001', null,'20000000-0000-0000-0000-000000000002','mobile', date_trunc('day',now()) + interval '18 hours', date_trunc('day',now()) + interval '30 hours','booked_on', null, date_trunc('day',now()) + interval '17 hours 58 minutes'),
 ('70000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002', null,'static', date_trunc('day',now()) + interval '5 days 18 hours', date_trunc('day',now()) + interval '6 days 6 hours','open', null, null);

insert into alarm_jobs (id, company_id, site_id, zone, officer_id, key_id, status, received_at, eta_at, created_by) values
 ('80000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000005','Zone 3 · rear loading door','20000000-0000-0000-0000-000000000002','51000000-0000-0000-0000-000000000001','en_route', now() - interval '11 minutes', now() + interval '9 minutes','10000000-0000-0000-0000-000000000001');

insert into alarm_job_events (job_id, at, event, detail) values
 ('80000000-0000-0000-0000-000000000001', now() - interval '11 minutes','signal_received','Zone 3 · rear loading door'),
 ('80000000-0000-0000-0000-000000000001', now() - interval '10 minutes','offered','Auto-dispatch to nearest keyholder'),
 ('80000000-0000-0000-0000-000000000001', now() - interval '9 minutes','accepted','K. Patel'),
 ('80000000-0000-0000-0000-000000000001', now() - interval '8 minutes','keys_out','Key K-114 (NFC) · Depot'),
 ('80000000-0000-0000-0000-000000000001', now() - interval '7 minutes','client_notified','SMS + email · ETA shared');

insert into incidents (company_id, site_id, officer_id, type, occurred_at, location_text, raw_notes, report, status, action_needed) values
 ('00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','damage', now() - interval '1 day', 'Gate 2, north perimeter',
  'side gate lock forced, checked perimeter no entry, chained gate, called police',
  'Officer K. Patel attended at 02:17 following a panel activation. Side gate lock found forced. Building perimeter checked, no entry gained. Gate secured with temporary chain. Police informed.',
  'needs_review','Arrange gate repair');

commit;
