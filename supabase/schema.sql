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
  rep_name text not null default '',
  branch_name text,
  month_key text not null default '',
  status text not null default 'draft',
  weeks jsonb not null default '[]'::jsonb,
  total_amount numeric(14, 2) not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.forecast_month_plans (
  id text primary key,
  plan jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

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
    created_at timestamp with time zone default now()
);

-- 3. Seed the developer/admin account (idempotent).
insert into public.app_users (username, email, role, password, is_active)
values (
    'osama',
    'osama@dream.com',
    'admin',
    '123456',
    true
)
on conflict (username) do nothing;

-- 4. Secure login RPC.
--    SECURITY DEFINER so the anonymous role can never read the
--    password column directly; RLS on app_users stays enabled.
create or replace function public.app_login(p_username text, p_password text)
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
      'id', u.id,
      'name', u.username,
      'username', u.username,
      'email', u.email,
      'role', u.role,
      'is_active', u.is_active,
      'created_at', u.created_at
    ) - 'password'
  from public.app_users u
  where coalesce(u.is_active, true)
    and (lower(coalesce(u.username,'')) = lower(trim(p_username))
         or lower(coalesce(u.email,'')) = lower(trim(p_username)))
    and (u.password = p_password
         or u.password = crypt(p_password, u.password))
  limit 1;
$$;

revoke all on function public.app_login(text, text) from public;
grant execute on function public.app_login(text, text) to anon, authenticated;

-- 5. List application users (password excluded). Used by the admin
--    dashboard in the web app. SECURITY DEFINER so RLS on app_users
--    never blocks the listing.
create or replace function public.list_app_users()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(jsonb_build_object(
      'id', id,
      'username', username,
      'email', coalesce(email, username),
      'role', role,
      'is_active', is_active,
      'created_at', created_at
    ) order by created_at desc),
    '[]'::jsonb
  )
  from public.app_users
  where coalesce(is_active, true);
$$;

revoke all on function public.list_app_users() from public;
grant execute on function public.list_app_users() to anon, authenticated;

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