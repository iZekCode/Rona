-- One row per saved painting; the id is created on the client so a retried insert is safe.
create table public.paintings (
    id uuid primary key,
    user_id uuid not null references public.profiles(id) on delete cascade,
    template_id text,
    painted_at timestamptz not null,
    image_path text not null,
    recording_path text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

-- The gallery lists a user's live paintings, newest first.
create index paintings_user_painted_at_idx 
    on public.paintings (user_id, painted_at desc)
    where deleted_at is null;

create trigger paintings_set_updated_at
    before update on public.paintings
    for each row execute function public.set_updated_at();

alter table public.paintings enable row level security;