create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique references public.applications(id)
    on delete cascade,
  applicant_id uuid not null references public.profiles(id) on delete cascade,
  employer_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  last_message_at timestamptz not null default now(),
  applicant_last_read_at timestamptz not null default now(),
  employer_last_read_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (applicant_id <> employer_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id)
    on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index conversations_applicant_last_message_idx
  on public.conversations (applicant_id, last_message_at desc);
create index conversations_employer_last_message_idx
  on public.conversations (employer_id, last_message_at desc);
create index messages_conversation_created_idx
  on public.messages (conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

revoke all on public.conversations, public.messages from public, anon, authenticated;
grant select on public.conversations, public.messages to authenticated;
grant insert (conversation_id, sender_id, body)
  on public.messages to authenticated;

create policy "Conversation participants can read conversations"
  on public.conversations for select to authenticated
  using (
    applicant_id = (select auth.uid())
    or employer_id = (select auth.uid())
  );

create policy "Conversation participants can read messages"
  on public.messages for select to authenticated
  using (
    exists (
      select 1
      from public.conversations c
      where c.id = conversation_id
        and (
          c.applicant_id = (select auth.uid())
          or c.employer_id = (select auth.uid())
        )
    )
  );

create policy "Participants can send conversation messages"
  on public.messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1
      from public.conversations c
      where c.id = conversation_id
        and (
          c.applicant_id = (select auth.uid())
          or c.employer_id = (select auth.uid())
        )
    )
  );

create or replace function public.get_or_create_application_conversation(
  p_application_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conversation_id uuid;
  v_applicant_id uuid;
  v_employer_id uuid;
  v_job_id uuid;
begin
  select a.applicant_id, c.owner_id, j.id
  into v_applicant_id, v_employer_id, v_job_id
  from public.applications a
  join public.jobs j on j.id = a.job_id
  join public.companies c on c.id = j.company_id
  where a.id = p_application_id;

  if not found then
    raise exception 'Application not found';
  end if;
  if auth.uid() is null
    or auth.uid() not in (v_applicant_id, v_employer_id) then
    raise exception 'Only the applicant or hiring employer can start this conversation';
  end if;

  insert into public.conversations (
    application_id, applicant_id, employer_id, job_id
  )
  values (
    p_application_id, v_applicant_id, v_employer_id, v_job_id
  )
  on conflict (application_id) do update
    set application_id = excluded.application_id
  returning id into v_conversation_id;

  return v_conversation_id;
end;
$$;

revoke all on function public.get_or_create_application_conversation(uuid)
  from public, anon;
grant execute on function public.get_or_create_application_conversation(uuid)
  to authenticated;

create or replace function public.get_my_conversations()
returns table (
  conversation_id uuid,
  application_id uuid,
  applicant_id uuid,
  employer_id uuid,
  job_id uuid,
  job_title text,
  company_name text,
  applicant_name text,
  last_message text,
  last_sender_id uuid,
  last_message_at timestamptz,
  unread boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    c.id,
    c.application_id,
    c.applicant_id,
    c.employer_id,
    c.job_id,
    j.title,
    co.name,
    p.full_name,
    latest.body,
    latest.sender_id,
    coalesce(latest.created_at, c.created_at),
    latest.created_at is not null
      and latest.sender_id <> auth.uid()
      and latest.created_at > case
        when auth.uid() = c.applicant_id then c.applicant_last_read_at
        else c.employer_last_read_at
      end
  from public.conversations c
  join public.jobs j on j.id = c.job_id
  join public.companies co on co.id = j.company_id
  join public.profiles p on p.id = c.applicant_id
  left join lateral (
    select m.body, m.sender_id, m.created_at
    from public.messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) latest on true
  where auth.uid() is not null
    and auth.uid() in (c.applicant_id, c.employer_id)
  order by coalesce(latest.created_at, c.created_at) desc;
$$;

revoke all on function public.get_my_conversations() from public, anon;
grant execute on function public.get_my_conversations() to authenticated;

create or replace function public.mark_conversation_read(
  p_conversation_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
  set applicant_last_read_at = case
        when applicant_id = auth.uid() then now()
        else applicant_last_read_at
      end,
      employer_last_read_at = case
        when employer_id = auth.uid() then now()
        else employer_last_read_at
      end
  where id = p_conversation_id
    and auth.uid() in (applicant_id, employer_id);

  if not found then
    raise exception 'Conversation not found or access denied';
  end if;
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public, anon;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

create or replace function public.bump_conversation_last_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
  set last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_bump_conversation_last_message
  after insert on public.messages
  for each row execute function public.bump_conversation_last_message();

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end;
$$;
