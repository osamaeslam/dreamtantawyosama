-- Base schema for the Tantawy sales application.
-- Safe to run repeatedly: this script does not drop tables or existing data.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.users (
  id text primary key default gen_random_uuid()::text,
  name text not null default '',
  username text unique,
  email text unique,
  password text not null,
  role text not null default 'sales_rep',
  branch_name text not null default '',
  phone text not null default '',
  supervisor_name text,
  supervisor_id text,
  avatar text,
  is_active boolean not null default true,
  approval_status text not null default 'active',
  code text,
  commission_rate numeric(10, 4),
  registration_date date,
  created_at timestamptz not null default now()
);

alter table public.users
  add column if not exists permissions jsonb not null default '{}'::jsonb;

create table if not exists public.branches (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  address text,
  phone text,
  manager_name text,
  manager_id text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key default gen_random_uuid()::text,
  code text not null default '',
  name text not null default '',
  department text not null default 'عام',
  category text not null default '',
  piece_price numeric(14, 2) not null default 0,
  carton_price numeric(14, 2) not null default 0,
  promo_price numeric(14, 2),
  carton_quantity integer not null default 1,
  branch_stock_actual integer not null default 0,
  branch_stock_reserved integer not null default 0,
  main_warehouse_actual integer not null default 0,
  main_warehouse_reserved integer not null default 0,
  image_url text,
  status text not null default 'متاح',
  sales_priority text not null default 'عادي',
  size text,
  color text,
  branch_stocks jsonb,
  item_group text,
  promo_piece_price numeric(14, 2),
  offer_price numeric(14, 2),
  discount_percent numeric(8, 3),
  discount_percentage numeric(8, 3),
  sales_price numeric(14, 2),
  price numeric(14, 2),
  stock integer not null default 0,
  barcode text,
  min_order_quantity integer,
  notes text,
  variant_id text,
  variant_name text,
  unified_code text,
  classification text,
  family_name text,
  cloudinary_public_id text,
  cloudinary_url text,
  created_at timestamptz not null default now()
);

alter table public.products add column if not exists stock integer not null default 0;

create table if not exists public.parent_products (
  id text primary key default gen_random_uuid()::text,
  primary_code text not null default '',
  unified_code text,
  name text not null default '',
  department text not null default 'عام',
  category text not null default '',
  classification text,
  family_name text,
  sales_priority text not null default 'عادي',
  status text not null default 'متاح',
  carton_quantity integer not null default 1,
  image_url text,
  min_price numeric(14, 2),
  max_price numeric(14, 2),
  total_october_stock integer not null default 0,
  variants_count integer not null default 0,
  has_multiple_variants boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.variants (
  id text primary key default gen_random_uuid()::text,
  parent_product_id text not null references public.parent_products(id) on delete cascade,
  product_id text,
  code text not null default '',
  unified_code text,
  name text not null default '',
  window_number integer,
  color text not null default '',
  color_code text,
  image_url text,
  branch_stock_actual integer not null default 0,
  branch_stock_reserved integer not null default 0,
  main_warehouse_actual integer not null default 0,
  main_warehouse_reserved integer not null default 0,
  carton_quantity integer not null default 1,
  piece_price numeric(14, 2) not null default 0,
  carton_price numeric(14, 2) not null default 0,
  promo_price numeric(14, 2),
  promo_piece_price numeric(14, 2),
  status text not null default 'متاح',
  barcode text,
  notes text
);

create table if not exists public.product_variants (
  id text primary key default gen_random_uuid()::text,
  product_id text not null references public.products(id) on delete cascade,
  code text not null default '',
  name text not null default '',
  color text not null default '',
  color_code text,
  image_url text,
  branch_stock_actual integer not null default 0,
  branch_stock_reserved integer not null default 0,
  main_warehouse_actual integer not null default 0,
  main_warehouse_reserved integer not null default 0,
  carton_quantity integer not null default 1,
  piece_price numeric(14, 2) not null default 0,
  carton_price numeric(14, 2) not null default 0,
  promo_price numeric(14, 2),
  promo_piece_price numeric(14, 2),
  status text not null default 'متاح',
  barcode text,
  notes text
);

create table if not exists public.product_stocks (
  id text primary key default gen_random_uuid()::text,
  product_id text not null,
  branch_name text not null,
  quantity_actual integer not null default 0 check (quantity_actual >= 0),
  quantity_reserved integer not null default 0 check (quantity_reserved >= 0),
  updated_at timestamptz not null default now(),
  unique (product_id, branch_name)
);

create table if not exists public.clients (
  id text primary key default gen_random_uuid()::text,
  client_code text,
  client_name text not null default '',
  store_name text,
  phone text,
  address text,
  branch text,
  branch_name text,
  rep_name text,
  mandoub_name text,
  balance numeric(14, 2) not null default 0,
  debt numeric(14, 2) not null default 0,
  credit_limit numeric(14, 2) not null default 0,
  overdue_balance numeric(14, 2) not null default 0,
  tier text not null default 'عادي',
  metadata jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.customers (
  id text primary key default gen_random_uuid()::text,
  code text not null default '',
  name text not null default '',
  store_name text not null default '',
  phone text not null default '',
  address text,
  branch_name text not null default '',
  rep_name text,
  current_balance numeric(14, 2) not null default 0,
  credit_limit numeric(14, 2) not null default 0,
  overdue_balance numeric(14, 2) not null default 0,
  tier text not null default 'عادي',
  governorate text,
  region text,
  sales_rep_name text,
  sales_rep_id text,
  supervisor_name text,
  supervisor_id text,
  tax_number text,
  balance numeric(14, 2),
  due_balance numeric(14, 2),
  total_overdue_and_due numeric(14, 2),
  last_order_date timestamptz,
  last_collection_date timestamptz,
  last_collection_amount numeric(14, 2),
  total_orders_count integer,
  total_spent numeric(14, 2),
  annual_target numeric(14, 2),
  deal_eligibility text,
  debt_status text,
  payment_terms text,
  client_type text,
  activity_type text,
  guarantee_amount numeric(14, 2),
  has_guarantee boolean,
  district text,
  route text,
  notes text,
  last_visit_date timestamptz,
  next_visit_date date,
  visit_count_2026 integer,
  created_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id text primary key default gen_random_uuid()::text,
  invoice_number text not null default '',
  customer_id text not null default '',
  customer_name text not null default '',
  customer_code text not null default '',
  rep_id text not null default '',
  rep_name text not null default '',
  branch_name text not null default '',
  date timestamptz not null default now(),
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(14, 2) not null default 0,
  discount numeric(14, 2) not null default 0,
  total_amount numeric(14, 2) not null default 0,
  status text not null default 'pending',
  payment_type text not null default 'آجل',
  notes text,
  supervisor_name text,
  time text,
  created_at timestamptz not null default now(),
  timestamp timestamptz,
  total_cartons integer,
  total_pieces integer,
  discount_percentage numeric(8, 3),
  discount_amount numeric(14, 2),
  tax_percentage numeric(8, 3),
  tax_amount numeric(14, 2),
  estimated_grand_total numeric(14, 2),
  synced_to_accounting boolean not null default false,
  accounting_sync_date timestamptz,
  qr_payload text,
  customer_balance_before numeric(14, 2),
  customer_credit_limit numeric(14, 2),
  customer_balance_after numeric(14, 2),
  customer_overdue_balance numeric(14, 2),
  credit_limit_exceeded boolean,
  required_down_payment numeric(14, 2),
  is_shortage_invoice boolean,
  parent_invoice_id text,
  parent_invoice_number text,
  has_shortage_split boolean,
  shortage_invoice_number text,
  has_october_shortages boolean,
  shortage_items_count integer,
  shortage_cartons_count integer,
  october_supply_requested boolean,
  october_supply_requested_at timestamptz,
  october_supply_requested_by text,
  october_supply_dispatched boolean,
  october_supply_dispatched_at timestamptz,
  october_supply_dispatched_by text,
  cancellation_reason text,
  cancelled_by text,
  cancelled_at timestamptz,
  restored_stock_details text,
  has_returns boolean,
  is_partial_return boolean,
  total_refunded_amount numeric(14, 2),
  net_amount_after_returns numeric(14, 2),
  last_return_date timestamptz,
  customer_phone text,
  customer_address text,
  customer_tax_number text,
  return_records jsonb,
  unique (invoice_number)
);

create table if not exists public.visits (
  id text primary key default gen_random_uuid()::text,
  customer_id text,
  customer_name text not null default '',
  customer_code text,
  client_code text,
  client_name text,
  rep_id text,
  mandoub_id text,
  rep_name text,
  mandoub_name text,
  branch_name text,
  branch text,
  supervisor_id text,
  supervisor_name text,
  date timestamptz not null default now(),
  timestamp timestamptz not null default now(),
  type text not null default '',
  outcome text,
  amount numeric(14, 2) not null default 0,
  collected_amount numeric(14, 2) not null default 0,
  notes text,
  location jsonb,
  status text,
  check_in_time timestamptz,
  check_out_time timestamptz,
  duration_minutes integer,
  store_stock_status text,
  competitor_notes text,
  customer_rating integer,
  next_visit_date date,
  order_id text,
  order_amount numeric(14, 2),
  sync_status text,
  is_return boolean,
  return_value numeric(14, 2),
  return_reason text,
  return_items text,
  return_status text,
  return_handled_by text,
  return_handled_at timestamptz,
  return_handled_role text,
  return_note text,
  is_archived boolean not null default false,
  archived_at timestamptz,
  archived_by text,
  review_status text,
  reviewed_by_name text,
  review_note text,
  reviewed_at timestamptz,
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  duplicate_of_visit_id text,
  allow_same_day_second_visit boolean,
  accuracy numeric(10, 7),
  address text,
  map_url text
);

create table if not exists public.returns (
  id text primary key default gen_random_uuid()::text,
  invoice_id text,
  invoice_number text not null default '',
  customer_id text,
  customer_name text,
  rep_name text,
  branch_name text,
  date timestamptz not null default now(),
  items jsonb not null default '[]'::jsonb,
  total_amount numeric(14, 2) not null default 0,
  reason text,
  status text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.customer_comments (
  id text primary key default gen_random_uuid()::text,
  customer_id text,
  customer_code text,
  customer_name text,
  branch_name text,
  rep_name text,
  comment text,
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists public.targets (
  id text primary key default gen_random_uuid()::text,
  rep_id text,
  rep_name text not null default '',
  branch_name text not null default '',
  month integer,
  year integer,
  date date not null default current_date,
  target_amount numeric(14, 2) not null default 0,
  sales_achieved numeric(14, 2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.forecasts (
  id text primary key default gen_random_uuid()::text,
  rep_id text,
  supervisor_id text,
  rep_name text not null default '',
  branch_name text,
  month_key text not null default '',
  week_index integer not null default 0,
  customer_id text,
  customer_code text,
  customer_name text,
  collection_forecast numeric(14, 2) not null default 0,
  sales_forecast numeric(14, 2) not null default 0,
  rep_collection_forecast numeric(14, 2),
  rep_sales_forecast numeric(14, 2),
  status text not null default 'draft',
  approval_stage text not null default 'rep_submitted',
  collection_method text not null default 'cash',
  return_expected boolean not null default false,
  return_expected_amount numeric(14, 2) not null default 0,
  return_status text not null default 'none',
  return_note text,
  legal_referral_status text not null default 'none',
  legal_referral_note text,
  scheduled_visit_date date,
  scheduled_visit_id text,
  supervisor_approved_by text,
  supervisor_approved_at timestamptz,
  branch_manager_approved_by text,
  branch_manager_approved_at timestamptz,
  submitted_at timestamptz,
  approved_by text,
  approved_at timestamptz,
  change_request_note text,
  change_requested_by text,
  change_requested_at timestamptz,
  weeks jsonb not null default '[]'::jsonb,
  total_amount numeric(14, 2) not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.forecast_month_plans (
  id text primary key,
  year integer not null default 0,
  month integer not null default 0,
  month_start date,
  month_end date,
  weeks jsonb not null default '[]'::jsonb,
  is_closed boolean not null default false,
  created_by text,
  created_at timestamptz not null default now(),
  updated_by text,
  updated_at timestamptz not null default now(),
  plan jsonb not null default '{}'::jsonb,
  constraint forecast_month_plans_month_range check (month between 0 and 12)
);

alter table public.forecasts
  add column if not exists supervisor_id text,
  add column if not exists week_index integer not null default 0,
  add column if not exists customer_id text,
  add column if not exists customer_code text,
  add column if not exists customer_name text,
  add column if not exists collection_forecast numeric(14, 2) not null default 0,
  add column if not exists sales_forecast numeric(14, 2) not null default 0,
  add column if not exists rep_collection_forecast numeric(14, 2),
  add column if not exists rep_sales_forecast numeric(14, 2),
  add column if not exists approval_stage text not null default 'rep_submitted',
  add column if not exists collection_method text not null default 'cash',
  add column if not exists return_expected boolean not null default false,
  add column if not exists return_expected_amount numeric(14, 2) not null default 0,
  add column if not exists return_status text not null default 'none',
  add column if not exists return_note text,
  add column if not exists legal_referral_status text not null default 'none',
  add column if not exists legal_referral_note text,
  add column if not exists scheduled_visit_date date,
  add column if not exists scheduled_visit_id text,
  add column if not exists supervisor_approved_by text,
  add column if not exists supervisor_approved_at timestamptz,
  add column if not exists branch_manager_approved_by text,
  add column if not exists branch_manager_approved_at timestamptz,
  add column if not exists submitted_at timestamptz,
  add column if not exists approved_by text,
  add column if not exists approved_at timestamptz,
  add column if not exists change_request_note text,
  add column if not exists change_requested_by text,
  add column if not exists change_requested_at timestamptz;

alter table public.forecast_month_plans
  add column if not exists year integer not null default 0,
  add column if not exists month integer not null default 0,
  add column if not exists month_start date,
  add column if not exists month_end date,
  add column if not exists weeks jsonb not null default '[]'::jsonb,
  add column if not exists is_closed boolean not null default false,
  add column if not exists created_by text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_by text;

create table if not exists public.promotions (
  id text primary key default gen_random_uuid()::text,
  name text not null default '',
  product_code text,
  product_id text,
  branch_name text,
  description text,
  discount numeric(8, 3),
  promo_price numeric(14, 2),
  start_date timestamptz,
  end_date timestamptz,
  status text not null default 'نشط',
  created_at timestamptz not null default now()
);

create table if not exists public.inventory_transactions (
  id text primary key default gen_random_uuid()::text,
  product_id text,
  product_code text,
  product_name text,
  branch_name text,
  transaction_type text,
  quantity integer not null default 0,
  previous_quantity integer,
  new_quantity integer,
  reference_id text,
  notes text,
  user_name text,
  date date not null default current_date,
  timestamp timestamptz not null default now()
);

create table if not exists public.audit_log (
  id text primary key default gen_random_uuid()::text,
  user_id text,
  user_name text,
  action text not null default '',
  entity_type text,
  entity_id text,
  invoice_id text,
  details jsonb,
  timestamp timestamptz not null default now()
);

create table if not exists public.customer_analytics (
  id text primary key default gen_random_uuid()::text,
  customer_id text,
  customer_code text,
  customer_name text not null default '',
  branch_name text,
  rep_name text,
  tier text,
  total_sales numeric(14, 2) not null default 0,
  total_orders integer not null default 0,
  current_balance numeric(14, 2) not null default 0,
  overdue_balance numeric(14, 2) not null default 0,
  last_order_date timestamptz,
  metadata jsonb
);

create table if not exists public.rep_performance (
  id text primary key default gen_random_uuid()::text,
  rep_id text,
  rep_name text not null default '',
  branch_name text,
  month integer,
  year integer,
  sales_achieved numeric(14, 2) not null default 0,
  target_amount numeric(14, 2) not null default 0,
  collections numeric(14, 2) not null default 0,
  visits_count integer not null default 0,
  metadata jsonb
);

create table if not exists public.company_info (
  id text primary key default gen_random_uuid()::text,
  name text,
  address text,
  phone text,
  email text,
  tax_number text,
  logo_url text,
  settings jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.cloudinary_config (
  id text primary key default gen_random_uuid()::text,
  cloud_name text,
  api_key text,
  upload_preset text,
  folder text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- جداول الموردين والمصروفات (جديدة)
-- ============================================================

create table if not exists public.suppliers (
  id text primary key default gen_random_uuid()::text,
  code text unique,
  name text not null default '',
  phone text,
  address text,
  email text,
  tax_number text,
  contact_person text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_suppliers_name on public.suppliers (name);
create index if not exists idx_suppliers_active on public.suppliers (is_active);

create table if not exists public.expenses (
  id text primary key default gen_random_uuid()::text,
  branch_name text not null default '',
  rep_name text,
  supplier_id text references public.suppliers(id),
  supplier_name text,
  category text not null default '',
  amount numeric(14, 2) not null default 0,
  payment_method text,
  date date not null default current_date,
  notes text,
  receipt_image_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_expenses_date on public.expenses (date desc);
create index if not exists idx_expenses_branch on public.expenses (branch_name);
create index if not exists idx_expenses_category on public.expenses (category);

-- ============================================================
-- Soft Deletes: إضافة عمود deleted_at على الجداول الرئيسية
-- (تم إنشاء جدول جديد بـ deleted_at مباشرة، مع إتاحة الترقيم اللاحق)
-- ============================================================

-- جداول جديدة تستخدم deleted_at مباشرة
-- (يمكن تشغيل ALTER TABLE ... ADD COLUMN IF NOT EXISTS deleted_at على الجداول القديمة)
alter table public.products add column if not exists deleted_at timestamptz;
alter table public.customers add column if not exists deleted_at timestamptz;
alter table public.invoices add column if not exists deleted_at timestamptz;
alter table public.visits add column if not exists deleted_at timestamptz;
alter table public.returns add column if not exists deleted_at timestamptz;
alter table public.suppliers add column if not exists deleted_at timestamptz;
alter table public.expenses add column if not exists deleted_at timestamptz;

-- فهارس جزئية: المهمة فقط غير المحذوفة
create index if not exists idx_products_active on public.products (deleted_at) where deleted_at is null;
create index if not exists idx_customers_active on public.customers (deleted_at) where deleted_at is null;
create index if not exists idx_invoices_active on public.invoices (deleted_at) where deleted_at is null;
create index if not exists idx_visits_active on public.visits (deleted_at) where deleted_at is null;
create index if not exists idx_returns_active on public.returns (deleted_at) where deleted_at is null;
create index if not exists idx_suppliers_active on public.suppliers (deleted_at) where deleted_at is null;
create index if not exists idx_expenses_active on public.expenses (deleted_at) where deleted_at is null;

create index if not exists idx_products_name on public.products (name);
create index if not exists idx_product_stocks_branch on public.product_stocks (branch_name);
create index if not exists idx_clients_client_name on public.clients (client_name);
create index if not exists idx_customers_name on public.customers (name);
create index if not exists idx_invoices_date on public.invoices (date desc);
create index if not exists idx_invoices_branch_rep on public.invoices (branch_name, rep_name);
create index if not exists idx_visits_timestamp on public.visits (timestamp desc);
create index if not exists idx_targets_rep_month on public.targets (rep_name, year, month);
create index if not exists idx_forecasts_month on public.forecasts (month_key desc);
create index if not exists idx_audit_log_timestamp on public.audit_log (timestamp desc);

-- GIN indexes لأعمدة JSONB — تسريع الاستعلامات الداخلية والمتداخلة
create index if not exists idx_products_branch_stocks_gin on public.products using gin (branch_stocks);
create index if not exists idx_clients_metadata_gin on public.clients using gin (metadata);
create index if not exists idx_customers_metadata_gin on public.customers using gin (metadata);
create index if not exists idx_invoices_return_records_gin on public.invoices using gin (return_records);
create index if not exists idx_forecasts_weeks_gin on public.forecasts using gin (weeks);
create index if not exists idx_customer_analytics_metadata_gin on public.customer_analytics using gin (metadata);
create index if not exists idx_rep_performance_metadata_gin on public.rep_performance using gin (metadata);
create index if not exists idx_audit_log_details_gin on public.audit_log using gin (details);

-- Keep user records private; sign-in is exposed through the sanitized RPC below.
alter table public.users enable row level security;

-- ============================================================
-- App login system (app_users table + app_login RPC)
-- ============================================================

-- 1. Ensure the pgcrypto extension is available for crypt().
create extension if not exists pgcrypto with schema extensions;

-- 2. Dedicated application-users table.
--    Kept separate from the legacy `users` table so the sales-app
--    credentials never touch the broader user directory.
create table if not exists public.app_users (
    id uuid primary key default gen_random_uuid(),
    username text unique not null,
    email text unique not null,
    role text not null default 'rep',
    password text not null,
    is_active boolean default true,
    permissions jsonb not null default '{}'::jsonb,
    created_at timestamp with time zone default now()
);

alter table public.app_users enable row level security;
alter table public.app_users
  add column if not exists permissions jsonb not null default '{}'::jsonb;
alter table public.app_users
  add column if not exists branch_name text not null default 'المركز الرئيسي';

create or replace function public.verify_app_admin(p_admin_id text, p_admin_password text)
returns boolean
language sql
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.app_users u
    where u.id::text = p_admin_id
      and coalesce(u.is_active, true)
      and lower(u.role) in ('admin', 'administrator', 'مدير عام', 'ادمن', 'أدمن')
      and (u.password = p_admin_password
        or (u.password like '$2%' and crypt(p_admin_password, u.password) = u.password))
    union all
    select 1
    from public.users u
    where u.id = p_admin_id
      and u.is_active
      and lower(u.role) in ('admin', 'administrator', 'مدير عام', 'ادمن', 'أدمن')
      and (u.password = p_admin_password
        or (u.password like '$2%' and crypt(p_admin_password, u.password) = u.password))
  );
$$;

revoke all on function public.verify_app_admin(text, text) from public;

-- Passwords are never returned by this RPC. It supports both the web
-- app's app_users table and the Flutter app's legacy users table.
create or replace function public.app_login(p_username text, p_password text)
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  with matching_accounts as (
    select
      jsonb_build_object(
        'id', u.id,
        'name', u.username,
        'username', u.username,
        'email', u.email,
        'role', u.role,
        'branch_name', u.branch_name,
        'is_active', coalesce(u.is_active, true),
        'permissions', u.permissions
      ) as profile,
      1 as priority
    from public.app_users u
    where coalesce(u.is_active, true)
      and (lower(u.username) = lower(trim(p_username))
        or lower(u.email) = lower(trim(p_username)))
      and (u.password = p_password
        or (u.password like '$2%' and crypt(p_password, u.password) = u.password))

    union all

    select
      to_jsonb(u) - 'password' as profile,
      2 as priority
    from public.users u
    where u.is_active
      and (lower(coalesce(u.username, '')) = lower(trim(p_username))
        or lower(coalesce(u.email, '')) = lower(trim(p_username))
        or u.id = trim(p_username)
        or lower(u.name) = lower(trim(p_username)))
      and (u.password = p_password
        or (u.password like '$2%' and crypt(p_password, u.password) = u.password))
  )
  select profile
  from matching_accounts
  order by priority
  limit 1;
$$;

revoke all on function public.app_login(text, text) from public;
grant execute on function public.app_login(text, text) to anon, authenticated;

-- List safe profile fields for the admin dashboard; passwords are excluded.
create or replace function public.list_app_users(
  p_admin_id text,
  p_admin_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result_json jsonb;
begin
  if not public.verify_app_admin(p_admin_id, p_admin_password) then
    raise exception 'Admin access required';
  end if;

  with user_profiles as (
    select jsonb_build_object(
      'id', id,
      'username', username,
      'email', coalesce(email, username),
      'role', role,
      'branch', branch_name,
      'is_active', coalesce(is_active, true),
      'permissions', permissions,
      'source', 'app_users',
      'created_at', created_at
    ) as profile, created_at
    from public.app_users
    where coalesce(is_active, true)

    union all

    select jsonb_build_object(
      'id', id,
      'username', coalesce(username, email, name),
      'email', email,
      'role', role,
      'branch', branch_name,
      'is_active', is_active,
      'permissions', permissions,
      'source', 'users',
      'created_at', created_at
    ) as profile, created_at
    from public.users
    where is_active
  )
  select coalesce(jsonb_agg(profile order by created_at desc), '[]'::jsonb)
  into result_json
  from user_profiles;

  return result_json;
end;
$$;

revoke all on function public.list_app_users(text, text) from public;
grant execute on function public.list_app_users(text, text) to anon, authenticated;

create or replace function public.reserve_product_stock(p_id text, quantity integer)
returns boolean
language plpgsql
security invoker
set search_path = public
as $$
declare
  updated_rows integer;
begin
  if quantity <= 0 then
    return false;
  end if;

  -- استخدام SELECT ... FOR UPDATE لمنع race conditions عند حجز متزامن
  -- يقفل الصف أثناء العملية ويمنع باقي العمليات من قراءة الرصيد المنقضي
  perform 1 from public.product_stocks
  where product_id = p_id
    and quantity_actual - quantity_reserved >= 0
  for update;

  update public.product_stocks
  set quantity_reserved = quantity_reserved + reserve_product_stock.quantity,
      updated_at = now()
  where product_id = p_id
    and quantity_actual - quantity_reserved >= reserve_product_stock.quantity;

  get diagnostics updated_rows = row_count;
  return updated_rows > 0;
end;
$$;

grant execute on function public.reserve_product_stock(text, integer) to anon, authenticated;

create unique index if not exists import_products_code_key
  on public.products (code) where code <> '';
create unique index if not exists import_clients_code_key
  on public.clients (client_code) where client_code is not null and client_code <> '';

create or replace function public.add_app_user(
  p_admin_id text,
  p_admin_password text,
  p_username text,
  p_email text,
  p_role text,
  p_password text,
  p_branch_name text,
  p_permissions jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  new_user public.app_users;
begin
  if not public.verify_app_admin(p_admin_id, p_admin_password) then
    raise exception 'Admin access required';
  end if;
  if length(trim(p_password)) < 8 then
    raise exception 'Password must contain at least 8 characters';
  end if;

  insert into public.app_users (username, email, role, password, is_active, branch_name, permissions)
  values (
    trim(p_username), lower(trim(p_email)), p_role,
    crypt(p_password, gen_salt('bf')), true,
    coalesce(nullif(trim(p_branch_name), ''), 'المركز الرئيسي'),
    coalesce(p_permissions, '{}'::jsonb)
  )
  returning * into new_user;

  return jsonb_build_object(
    'id', new_user.id, 'username', new_user.username, 'email', new_user.email,
    'role', new_user.role, 'branch', new_user.branch_name,
    'permissions', new_user.permissions, 'source', 'app_users', 'is_active', true
  );
end;
$$;

create or replace function public.update_app_user(
  p_admin_id text,
  p_admin_password text,
  p_user_id uuid,
  p_role text,
  p_is_active boolean,
  p_branch_name text,
  p_permissions jsonb,
  p_new_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  updated_user public.app_users;
begin
  if not public.verify_app_admin(p_admin_id, p_admin_password) then
    raise exception 'Admin access required';
  end if;
  if p_new_password is not null and length(p_new_password) < 8 then
    raise exception 'Password must contain at least 8 characters';
  end if;

  update public.app_users
  set role = coalesce(p_role, role),
      is_active = coalesce(p_is_active, is_active),
      branch_name = coalesce(nullif(trim(p_branch_name), ''), branch_name),
      permissions = coalesce(p_permissions, permissions),
      password = case when p_new_password is null then password
                      else crypt(p_new_password, gen_salt('bf')) end
  where id = p_user_id
  returning * into updated_user;

  if updated_user.id is null then
    raise exception 'User not found';
  end if;

  return jsonb_build_object(
    'id', updated_user.id, 'username', updated_user.username, 'email', updated_user.email,
    'role', updated_user.role, 'branch', updated_user.branch_name,
    'permissions', updated_user.permissions, 'source', 'app_users',
    'is_active', updated_user.is_active
  );
end;
$$;

revoke all on function public.add_app_user(text, text, text, text, text, text, text, jsonb) from public;
revoke all on function public.update_app_user(text, text, uuid, text, boolean, text, jsonb, text) from public;
grant execute on function public.add_app_user(text, text, text, text, text, text, text, jsonb) to anon, authenticated;
grant execute on function public.update_app_user(text, text, uuid, text, boolean, text, jsonb, text) to anon, authenticated;

create or replace function public.sheet_text(p_row jsonb, p_keys text[])
returns text
language sql
immutable
as $$
  select value
  from jsonb_each_text(coalesce(p_row, '{}'::jsonb)) as item(key, value)
  where lower(trim(key)) = any (select lower(trim(candidate)) from unnest(p_keys) as keys(candidate))
  limit 1;
$$;

create or replace function public.sheet_number(p_value text)
returns numeric
language plpgsql
immutable
as $$
declare
  cleaned text;
begin
  cleaned := regexp_replace(coalesce(p_value, ''), '[^0-9.\-]', '', 'g');
  if cleaned = '' or cleaned in ('-', '.') then return 0; end if;
  return cleaned::numeric;
exception when invalid_text_representation then
  return 0;
end;
$$;

create or replace function public.import_sheet_rows(
  p_admin_id text,
  p_admin_password text,
  p_kind text,
  p_rows jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  row_data jsonb;
  row_count integer := 0;
  total_rows integer := 0;
  row_code text;
  row_name text;
  row_email text;
  found_id text;
begin
  if not public.verify_app_admin(p_admin_id, p_admin_password) then
    raise exception 'Admin access required';
  end if;
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 5000 then
    raise exception 'Rows must be an array with at most 5000 records';
  end if;

  total_rows := jsonb_array_length(p_rows);

  for row_data in select value from jsonb_array_elements(p_rows)
  loop
    if p_kind = 'products' then
      row_code := coalesce(nullif(public.sheet_text(row_data, array['code','كود','كود الصنف','كود المنتج']), ''), gen_random_uuid()::text);
      row_name := public.sheet_text(row_data, array['name','اسم الصنف','الصنف','اسم المنتج']);
      if coalesce(row_name, '') = '' then continue; end if;
      insert into public.products (code, name, department, category, price, piece_price, carton_price, stock, main_warehouse_actual, image_url)
      values (
        row_code, row_name,
        coalesce(nullif(public.sheet_text(row_data, array['department','القسم','التصنيف']), ''), 'عام'),
        coalesce(nullif(public.sheet_text(row_data, array['category','الفئة']), ''), 'عام'),
        public.sheet_number(public.sheet_text(row_data, array['price','السعر','سعر الكرتونة','carton_price'])),
        public.sheet_number(public.sheet_text(row_data, array['piece_price','سعر القطعة'])),
        public.sheet_number(public.sheet_text(row_data, array['carton_price','سعر الكرتونة','price','السعر'])),
        public.sheet_number(public.sheet_text(row_data, array['stock','المخزون','الرصيد','رصيد المخزن']))::integer,
        public.sheet_number(public.sheet_text(row_data, array['stock','المخزون','الرصيد','رصيد المخزن']))::integer,
        public.sheet_text(row_data, array['image_url','image','رابط الصورة','الصورة'])
      )
      on conflict (code) where code <> '' do update set
        name = excluded.name, department = excluded.department, category = excluded.category,
        price = excluded.price, piece_price = excluded.piece_price,
        carton_price = excluded.carton_price, stock = excluded.stock,
        main_warehouse_actual = excluded.main_warehouse_actual,
        image_url = excluded.image_url;
    elsif p_kind = 'clients' then
      row_code := public.sheet_text(row_data, array['client_code','code','كود العميل','كود']);
      row_name := public.sheet_text(row_data, array['client_name','name','اسم العميل','العميل']);
      if coalesce(row_code, '') = '' or coalesce(row_name, '') = '' then continue; end if;
      insert into public.clients (client_code, client_name, phone, address, branch, branch_name, mandoub_name, rep_name, balance, debt, credit_limit, overdue_balance)
      values (
        row_code, row_name,
        public.sheet_text(row_data, array['phone','الهاتف','التليفون','رقم الهاتف']),
        public.sheet_text(row_data, array['address','العنوان']),
        public.sheet_text(row_data, array['branch','branch_name','الفرع']),
        public.sheet_text(row_data, array['branch_name','branch','الفرع']),
        public.sheet_text(row_data, array['mandoub_name','rep_name','المندوب','اسم المندوب']),
        public.sheet_text(row_data, array['rep_name','mandoub_name','المندوب','اسم المندوب']),
        public.sheet_number(public.sheet_text(row_data, array['balance','debt','المديونية','الرصيد'])),
        public.sheet_number(public.sheet_text(row_data, array['debt','balance','المديونية','الرصيد'])),
        public.sheet_number(public.sheet_text(row_data, array['credit_limit','حد الائتمان'])),
        public.sheet_number(public.sheet_text(row_data, array['overdue_balance','المتأخرات']))
      )
      on conflict (client_code) where client_code is not null and client_code <> '' do update set
        client_name = excluded.client_name, phone = excluded.phone, address = excluded.address,
        branch = excluded.branch, branch_name = excluded.branch_name,
        mandoub_name = excluded.mandoub_name, rep_name = excluded.rep_name,
        balance = excluded.balance, debt = excluded.debt,
        credit_limit = excluded.credit_limit, overdue_balance = excluded.overdue_balance;
    elsif p_kind = 'reps' then
      row_name := public.sheet_text(row_data, array['username','name','اسم المندوب','اسم المستخدم','الاسم']);
      row_email := lower(public.sheet_text(row_data, array['email','البريد','البريد الإلكتروني','الايميل']));
      if coalesce(row_name, '') = '' then continue; end if;
      if coalesce(row_email, '') = '' then
        row_email := lower(regexp_replace(row_name, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(gen_random_uuid()::text, 1, 8) || '@imported.invalid';
      end if;
      insert into public.app_users (username, email, role, password, is_active, branch_name, permissions)
      values (
        row_name, row_email,
        coalesce(nullif(public.sheet_text(row_data, array['role','الدور','الوظيفة']), ''), 'sales_rep'),
        crypt(gen_random_uuid()::text, gen_salt('bf')), true,
        coalesce(nullif(public.sheet_text(row_data, array['branch_name','branch','الفرع']), ''), 'المركز الرئيسي'),
        '{}'::jsonb
      )
      on conflict (username) do update set
        email = excluded.email, role = excluded.role, branch_name = excluded.branch_name;
    elsif p_kind = 'promotions' then
      row_name := public.sheet_text(row_data, array['name','اسم العرض','العرض']);
      if coalesce(row_name, '') = '' then continue; end if;
      row_code := public.sheet_text(row_data, array['product_code','code','كود الصنف','كود المنتج']);
      select id into found_id from public.promotions
      where name = row_name and coalesce(product_code, '') = coalesce(row_code, '')
      limit 1;
      if found_id is null then
        insert into public.promotions (name, product_code, branch_name, description, discount, promo_price, start_date, end_date, status)
        values (
          row_name, row_code,
          public.sheet_text(row_data, array['branch_name','branch','الفرع']),
          public.sheet_text(row_data, array['description','الوصف']),
          public.sheet_number(public.sheet_text(row_data, array['discount','نسبة الخصم'])),
          public.sheet_number(public.sheet_text(row_data, array['promo_price','سعر العرض','السعر'])),
          nullif(public.sheet_text(row_data, array['start_date','تاريخ البداية']), '')::timestamptz,
          nullif(public.sheet_text(row_data, array['end_date','تاريخ النهاية']), '')::timestamptz,
          coalesce(nullif(public.sheet_text(row_data, array['status','الحالة']), ''), 'نشط')
        );
      else
        update public.promotions set
          branch_name = public.sheet_text(row_data, array['branch_name','branch','الفرع']),
          description = public.sheet_text(row_data, array['description','الوصف']),
          discount = public.sheet_number(public.sheet_text(row_data, array['discount','نسبة الخصم'])),
          promo_price = public.sheet_number(public.sheet_text(row_data, array['promo_price','سعر العرض','السعر'])),
          status = coalesce(nullif(public.sheet_text(row_data, array['status','الحالة']), ''), status)
        where id = found_id;
      end if;
     elsif p_kind = 'suppliers' then
       row_name := public.sheet_text(row_data, array['name','اسم المورد','المورد']);
       if coalesce(row_name, '') = '' then continue; end if;
       row_code := public.sheet_text(row_data, array['code','كود المورد']);
       insert into public.suppliers (code, name, phone, address, email, tax_number, contact_person, notes, is_active)
       values (
         row_code, row_name,
         public.sheet_text(row_data, array['phone','الهاتف']),
         public.sheet_text(row_data, array['address','العنوان']),
         lower(public.sheet_text(row_data, array['email','البريد الإلكتروني'])),
         public.sheet_text(row_data, array['tax_number','الرقم الضريبي']),
         public.sheet_text(row_data, array['contact_person','جهة الاتصال']),
         public.sheet_text(row_data, array['notes','ملاحظات']),
         coalesce(nullif(public.sheet_text(row_data, array['is_active','الحالة']), ''), 'نشط') = 'نشط'
       )
       on conflict (code) where code is not null and code <> '' do update set
         name = excluded.name, phone = excluded.phone, address = excluded.address,
         email = excluded.email, tax_number = excluded.tax_number,
         contact_person = excluded.contact_person, notes = excluded.notes,
         is_active = excluded.is_active;

     elsif p_kind = 'expenses' then
       row_name := public.sheet_text(row_data, array['category','الفئة','نوع النفقة']);
       if coalesce(row_name, '') = '' then continue; end if;
       insert into public.expenses (branch_name, rep_name, supplier_name, category, amount, payment_method, date, notes)
       values (
         coalesce(nullif(public.sheet_text(row_data, array['branch_name','branch','الفرع']), ''), 'المركز الرئيسي'),
         public.sheet_text(row_data, array['rep_name','المندوب']),
         public.sheet_text(row_data, array['supplier_name','اسم المورد']),
         row_name,
         public.sheet_number(public.sheet_text(row_data, array['amount','المبلغ','المصاريف','quantity','الكمية'])),
         coalesce(nullif(public.sheet_text(row_data, array['payment_method','طريقة الدفع']), ''), 'نقدي'),
         nullif(public.sheet_text(row_data, array['date','التاريخ']), '')::date,
         public.sheet_text(row_data, array['notes','ملاحظات'])
       );
     else
       raise exception 'Unsupported import type';
     end if;
     row_count := row_count + 1;
   end loop;

  return jsonb_build_object(
    'kind', p_kind,
    'imported', row_count,
    'skipped', (total_rows - row_count)
  );
end;
$$;

revoke all on function public.import_sheet_rows(text, text, text, jsonb) from public;
grant execute on function public.import_sheet_rows(text, text, text, jsonb) to anon, authenticated;

-- ============================================================
-- دوال مساعدة للموردين والمصروفات
-- ============================================================

create or replace function public.fetch_suppliers(
  p_branch_name text default null
)
returns jsonb
language sql
security invoker
set search_path = public
as $$
  select coalesce(jsonb_agg(row_to_json(s)), '[]'::jsonb)
  from public.suppliers s
  where s.is_active
    and (p_branch_name is null or s.name ilike '%' || p_branch_name || '%')
  order by s.name;
$$;

create or replace function public.log_expense(
  p_branch_name text,
  p_supplier_id text,
  p_category text,
  p_amount numeric,
  p_payment_method text default 'نقدي',
  p_date date default current_date,
  p_notes text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  new_expense public.expenses;
begin
  insert into public.expenses (
    branch_name, supplier_id, supplier_name, category,
    amount, payment_method, date, notes
  ) values (
    p_branch_name, p_supplier_id, null, p_category,
    p_amount, p_payment_method, p_date, p_notes
  )
  returning * into new_expense;

  return to_jsonb(new_expense);
end;
$$;

create or replace function public.soft_delete_record(
  p_table_name text,
  p_record_id text
)
returns boolean
language plpgsql
security invoker
set search_path = public
as $$
begin
  if p_table_name not in ('products', 'customers', 'invoices', 'visits', 'returns', 'suppliers', 'expenses') then
    return false;
  end if;

  execute format('update public.%I set deleted_at = now() where id = $1 and deleted_at is null', p_table_name)
  using p_record_id;

  return found;
end;
$$;

grant execute on function public.fetch_suppliers(text) to anon, authenticated;
grant execute on function public.log_expense(text, text, text, numeric, text, date, text) to anon, authenticated;
grant execute on function public.soft_delete_record(text, text) to anon, authenticated;