-- Sirat Digital Services: run this whole script in Supabase SQL Editor.
-- Replace the admin email below if you use a different owner email.
create extension if not exists pgcrypto;

create table if not exists public.site_settings (
  id integer primary key default 1 check (id = 1),
  brand text not null default 'Sirat Digital Services',
  phone text not null default '8801913022305',
  email text not null default 'siratakanda06@gmail.com',
  hero text not null default 'YouTube watch-time consulting, monetization guidance, video editing and channel SEO for creators.',
  payment text not null default 'bKash, Nagad, Bank Transfer, Visa Card, Western Union, Ria Money Transfer and GCash. Confirm payment details directly before paying.',
  watch_price text not null default '$100',
  updated_at timestamptz not null default now()
);
insert into public.site_settings (id) values (1) on conflict (id) do nothing;

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  price text not null default 'Custom',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
insert into public.services (title,description,price,sort_order)
select * from (values
 ('YouTube Watch Time Growth Consulting','Channel analytics review, audience-retention recommendations and genuine watch-time strategy.','$100',1),
 ('YouTube Monetization Guidance','Understand eligibility, original-content requirements and monetization policy readiness.','Custom',2),
 ('Video Editing','Editing support for long-form videos, Shorts, captions and pacing.','Custom',3),
 ('Facebook Monetization Guidance','Guidance on creator eligibility, content quality and monetization policy readiness.','Custom',4),
 ('Channel SEO','Review titles, descriptions, thumbnails and channel discoverability.','Custom',5)
) as v(title,description,price,sort_order)
where not exists (select 1 from public.services);

create table if not exists public.proof_images (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  caption text,
  storage_path text,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_phone text not null,
  service text not null,
  channel_url text,
  details text,
  created_at timestamptz not null default now()
);

alter table public.site_settings enable row level security;
alter table public.services enable row level security;
alter table public.proof_images enable row level security;
alter table public.orders enable row level security;

-- Public visitors may read site content.
drop policy if exists "Public read site settings" on public.site_settings;
create policy "Public read site settings" on public.site_settings for select using (true);
drop policy if exists "Admin manages site settings" on public.site_settings;
create policy "Admin manages site settings" on public.site_settings for all to authenticated
using ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com')
with check ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');

drop policy if exists "Public read services" on public.services;
create policy "Public read services" on public.services for select using (true);
drop policy if exists "Admin manages services" on public.services;
create policy "Admin manages services" on public.services for all to authenticated
using ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com')
with check ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');

drop policy if exists "Public read proofs" on public.proof_images;
create policy "Public read proofs" on public.proof_images for select using (true);
drop policy if exists "Admin manages proofs" on public.proof_images;
create policy "Admin manages proofs" on public.proof_images for all to authenticated
using ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com')
with check ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');

-- Public order form can submit; only the owner admin can read/manage requests.
drop policy if exists "Anyone can submit order request" on public.orders;
create policy "Anyone can submit order request" on public.orders for insert
with check (length(customer_name) between 1 and 120 and length(customer_phone) between 5 and 40 and length(service) between 1 and 200);
drop policy if exists "Admin reads orders" on public.orders;
create policy "Admin reads orders" on public.orders for select to authenticated
using ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');
drop policy if exists "Admin manages orders" on public.orders;
create policy "Admin manages orders" on public.orders for update to authenticated
using ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com')
with check ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');
drop policy if exists "Admin deletes orders" on public.orders;
create policy "Admin deletes orders" on public.orders for delete to authenticated
using ((auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');

-- Public image bucket; only owner can upload/delete.
insert into storage.buckets (id,name,public) values ('proof-images','proof-images',true)
on conflict (id) do update set public=true;
drop policy if exists "Public view proof image files" on storage.objects;
create policy "Public view proof image files" on storage.objects for select
using (bucket_id = 'proof-images');
drop policy if exists "Admin uploads proof image files" on storage.objects;
create policy "Admin uploads proof image files" on storage.objects for insert to authenticated
with check (bucket_id = 'proof-images' and (auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');
drop policy if exists "Admin deletes proof image files" on storage.objects;
create policy "Admin deletes proof image files" on storage.objects for delete to authenticated
using (bucket_id = 'proof-images' and (auth.jwt() ->> 'email') = 'siratakanda06@gmail.com');
