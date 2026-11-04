-- Lets painting_stats point at a painting and its owner together.
alter table public.paintings
    add constraint paintings_id_user_id_key unique (id, user_id);

-- Movement stats of one painting, kept as a JSON document with its own format version.
create table public.painting_stats (
    painting_id uuid primary key,
    user_id uuid not null,
    schema_version int not null,
    stats jsonb not null,
    updated_at timestamptz not null default now(),
    foreign key (painting_id, user_id)
        references public.paintings (id, user_id) on delete cascade
);

create trigger painting_stats_set_updated_at
    before update on public.painting_stats
    for each row execute function public.set_updated_at();

alter table public.painting_stats enable row level security;