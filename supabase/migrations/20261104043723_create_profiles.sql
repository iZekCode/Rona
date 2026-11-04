-- One row per account, with no personal data on purpose.
create table public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    consented_at timestamptz not null,
    consent_version int not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Policies come in a later migration; until then no one can read or write rows through the API.
alter table public.profiles enable row level security;
