create extension if not exists pgcrypto;
create type appointment_status as enum ('PENDING_CONFIRMATION','CONFIRMED','RESCHEDULE_REQUESTED','CANCELLED','COMPLETED','NO_SHOW');
create type price_display_type as enum ('FIXED','STARTING_FROM','CONTACT');
create type payment_status as enum ('PENDING','PAID','FAILED','REFUNDED','PAY_AT_SALON');
create table if not exists service_categories(id uuid primary key default gen_random_uuid(),name text not null,description text,image_url text,sort_order int default 0,is_active boolean default true,created_at timestamptz default now());
create table if not exists services(id uuid primary key default gen_random_uuid(),category_id uuid references service_categories(id),name text not null,description text,price numeric(10,2),duration_minutes int not null,image_url text,is_active boolean default true,is_featured boolean default false,price_display_type price_display_type default 'FIXED',discounted_price numeric(10,2),created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists customers(id uuid primary key default gen_random_uuid(),name text not null,phone text unique not null check(phone ~ '^[6-9][0-9]{9}$'),created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists staff(id uuid primary key default gen_random_uuid(),name text not null,role text, specialization text,image_url text,is_active boolean default true,created_at timestamptz default now());
create table if not exists staff_working_hours(id uuid primary key default gen_random_uuid(),staff_id uuid references staff(id) on delete cascade,day_of_week int not null check(day_of_week between 0 and 6),start_time time not null,end_time time not null,break_start time,break_end time);
create table if not exists staff_leaves(id uuid primary key default gen_random_uuid(),staff_id uuid references staff(id) on delete cascade,date date not null,reason text,unique(staff_id,date));
create table if not exists salon_settings(id uuid primary key default gen_random_uuid(),salon_name text not null default 'Silver Beauty Parlour',phone text,whatsapp_number text,address text not null default 'Bhopalpura 2nd Street, Udaipur, Rajasthan – 313001, India',opening_time time default '10:00',closing_time time default '20:00',currency text default 'INR',booking_settings jsonb default '{}'::jsonb,whatsapp_config jsonb default '{}'::jsonb);
create table if not exists salon_holidays(id uuid primary key default gen_random_uuid(),date date unique not null,reason text);
create sequence if not exists appointment_number_seq start 1;
create table if not exists appointments(id uuid primary key default gen_random_uuid(),appointment_number text unique not null,customer_id uuid references customers(id),requested_date date not null,requested_time time not null,confirmed_date date,confirmed_time time,staff_id uuid references staff(id),status appointment_status not null default 'PENDING_CONFIRMATION',customer_note text,estimated_total numeric(10,2) default 0,estimated_duration int default 0,cancellation_reason text,cancelled_by text,created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists appointment_services(id uuid primary key default gen_random_uuid(),appointment_id uuid references appointments(id) on delete cascade,service_id uuid references services(id),service_name_snapshot text not null,price_snapshot numeric(10,2),duration_snapshot int);
create table if not exists payments(id uuid primary key default gen_random_uuid(),appointment_id uuid references appointments(id),payment_method text not null,payment_provider text,transaction_id text,amount numeric(10,2) not null,status payment_status not null default 'PENDING',created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists appointment_history(id uuid primary key default gen_random_uuid(),appointment_id uuid references appointments(id) on delete cascade,old_status appointment_status,new_status appointment_status,changed_by uuid,notes text,created_at timestamptz default now());
create table if not exists admin_users(id uuid primary key references auth.users(id) on delete cascade,name text,role text not null default 'STAFF' check(role in ('OWNER','MANAGER','STAFF')),created_at timestamptz default now());
create table if not exists gallery(id uuid primary key default gen_random_uuid(),image_url text not null,title text,category text,is_active boolean default true,created_at timestamptz default now());
create table if not exists testimonials(id uuid primary key default gen_random_uuid(),customer_name text not null,review text not null,rating int check(rating between 1 and 5),is_featured boolean default false,is_active boolean default true,created_at timestamptz default now());
create table if not exists offers(id uuid primary key default gen_random_uuid(),name text not null,description text,original_price numeric(10,2),discounted_price numeric(10,2),start_date date,end_date date,is_active boolean default true,created_at timestamptz default now());
create table if not exists contact_enquiries(id uuid primary key default gen_random_uuid(),name text not null,phone text not null,message text not null,created_at timestamptz default now());

create or replace function create_pending_appointment(p_customer_id uuid,p_date date,p_time time,p_note text,p_total numeric,p_duration int) returns json language plpgsql security definer set search_path=public as $$declare aid uuid; anum text; begin if p_date < current_date then raise exception 'Past date'; end if; if exists(select 1 from salon_holidays where date=p_date) then raise exception 'Salon closed'; end if; anum:='SBP-'||to_char(current_date,'YYYY')||'-'||lpad(nextval('appointment_number_seq')::text,6,'0'); insert into appointments(appointment_number,customer_id,requested_date,requested_time,customer_note,estimated_total,estimated_duration) values(anum,p_customer_id,p_date,p_time,p_note,p_total,p_duration) returning id into aid; return json_build_object('appointment_id',aid,'appointment_number',anum); end; $$;
create or replace function staff_has_conflict(p_staff_id uuid,p_date date,p_time time,p_duration int,p_ignore_appointment_id uuid default null) returns boolean language sql stable security definer set search_path=public as $$
select exists(select 1 from appointments a where a.staff_id=p_staff_id and a.status='CONFIRMED' and a.confirmed_date=p_date and (p_ignore_appointment_id is null or a.id<>p_ignore_appointment_id) and (a.confirmed_time < p_time + make_interval(mins=>p_duration) and p_time < a.confirmed_time + make_interval(mins=>a.estimated_duration)));
$$;

insert into salon_settings(salon_name,address) select 'Silver Beauty Parlour','Bhopalpura 2nd Street, Udaipur, Rajasthan – 313001, India' where not exists(select 1 from salon_settings);
insert into service_categories(name,description,sort_order) select * from (values ('Hair Care','Hair cuts, styling, spa, colour and treatments.',1),('Skin Care','Facials, cleanup, de-tan and skin care.',2),('Waxing','Waxing services for women.',3),('Nail Services','Manicure, pedicure, nail art and extensions.',4),('Makeup','Party, engagement and bridal makeup.',5),('Bridal & Special Packages','Pre-bridal and customized beauty packages.',6)) v(name,description,sort_order) where not exists(select 1 from service_categories c where c.name=v.name);
insert into services(category_id,name,description,price,duration_minutes,is_featured) select c.id,v.name,v.description,v.price,v.duration,v.featured from service_categories c join (values ('Hair Care','Hair Spa','A restorative hair care session.',1200,60,true),('Hair Care','Hair Styling','Styling for special occasions.',800,45,true),('Skin Care','Basic Facial','A gentle facial care session.',900,60,true),('Skin Care','Premium Facial','An extended facial care session.',1500,75,false),('Waxing','Full Arms','Full arm waxing service.',500,30,false),('Waxing','Full Legs','Full leg waxing service.',700,45,false),('Nail Services','Basic Manicure','Classic hand and nail care.',500,45,false),('Nail Services','Spa Pedicure','Relaxing foot and nail care.',800,60,true),('Nail Services','Nail Art','Custom nail art.',600,45,false),('Makeup','Party Makeup','Party-ready makeup.',2500,90,true),('Makeup','Engagement Makeup','Engagement makeup service.',5000,120,false),('Makeup','Bridal Makeup','Bridal makeup consultation/service.',10000,150,true)) v(cat,name,description,price,duration,featured) on c.name=v.cat where not exists(select 1 from services s where s.name=v.name);

-- RLS: public users only get intentionally public catalogue/settings; mutations are server-side via service role.
alter table service_categories enable row level security; alter table services enable row level security; alter table salon_settings enable row level security; alter table salon_holidays enable row level security;
create policy "public read active categories" on service_categories for select using(is_active=true);
create policy "public read active services" on services for select using(is_active=true);
create policy "public read holidays" on salon_holidays for select using(true);
create or replace function staff_slot_available(p_staff_id uuid,p_date date,p_time time,p_duration int,p_ignore_appointment_id uuid default null) returns boolean language plpgsql stable security definer set search_path=public as $$
declare finish time; dow int; sh time; eh time; bs time; be time; has_schedule boolean;
begin
 finish:=p_time + make_interval(mins=>p_duration); dow:=extract(dow from p_date);
 if exists(select 1 from salon_holidays where date=p_date) then return false; end if;
 if exists(select 1 from staff_leaves where staff_id=p_staff_id and date=p_date) then return false; end if;
 select exists(select 1 from staff_working_hours where staff_id=p_staff_id and day_of_week=dow) into has_schedule;
 if has_schedule then
   select start_time,end_time,break_start,break_end into sh,eh,bs,be from staff_working_hours where staff_id=p_staff_id and day_of_week=dow order by start_time limit 1;
 else
   select opening_time,closing_time into sh,eh from salon_settings limit 1;
 end if;
 if sh is null or eh is null or p_time < sh or finish > eh then return false; end if;
 if bs is not null and be is not null and p_time < be and finish > bs then return false; end if;
 if staff_has_conflict(p_staff_id,p_date,p_time,p_duration,p_ignore_appointment_id) then return false; end if;
 return true;
end; $$;

alter table customers enable row level security; alter table staff enable row level security; alter table staff_working_hours enable row level security; alter table staff_leaves enable row level security; alter table appointments enable row level security; alter table appointment_services enable row level security; alter table payments enable row level security; alter table appointment_history enable row level security; alter table admin_users enable row level security; alter table gallery enable row level security; alter table testimonials enable row level security; alter table offers enable row level security; alter table contact_enquiries enable row level security;
-- All writes and private reads go through authenticated server routes using the Supabase service role.
create policy "public read active gallery" on gallery for select using(is_active=true);
create policy "public read active testimonials" on testimonials for select using(is_active=true);
create policy "public read active offers" on offers for select using(is_active=true);
