alter type public.application_status add value if not exists 'accepted';

alter table public.profiles
  add column if not exists skills text[] not null default '{}'::text[],
  add column if not exists experience_summary text not null default '',
  add column if not exists preferred_job_types text[] not null default '{}'::text[];

grant update (skills, experience_summary, preferred_job_types)
  on public.profiles to authenticated;

create or replace function public.set_application_status(
  p_application_id uuid,
  p_status public.application_status
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status::text not in ('interview', 'offer', 'rejected') then
    raise exception 'Unsupported hiring status';
  end if;

  update public.applications a
  set status = p_status
  from public.jobs j
  join public.companies c on c.id = j.company_id
  where a.id = p_application_id
    and j.id = a.job_id
    and c.owner_id = auth.uid()
    and (
      (a.status::text = 'applied' and p_status::text in ('interview', 'rejected'))
      or (
        a.status::text = 'interview'
        and p_status::text in ('offer', 'rejected')
      )
    );

  if not found then
    raise exception 'Application not found or status transition is not allowed';
  end if;
end;
$$;

create or replace function public.accept_application_offer(
  p_application_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.applications
  set status = 'accepted'
  where id = p_application_id
    and applicant_id = auth.uid()
    and status::text = 'offer';

  if not found then
    raise exception 'Offer not found or no longer available';
  end if;
end;
$$;

create or replace function public.decline_application_offer(
  p_application_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.applications
  set status = 'rejected'
  where id = p_application_id
    and applicant_id = auth.uid()
    and status::text = 'offer';

  if not found then
    raise exception 'Offer not found or no longer available';
  end if;
end;
$$;

create or replace function public.withdraw_application(
  p_application_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.applications
  set status = 'withdrawn'
  where id = p_application_id
    and applicant_id = auth.uid()
    and status::text in ('applied', 'interview', 'offer');

  if not found then
    raise exception 'Application cannot be withdrawn in its current state';
  end if;
end;
$$;

revoke all on function public.accept_application_offer(uuid)
  from public, anon;
revoke all on function public.decline_application_offer(uuid)
  from public, anon;
revoke all on function public.withdraw_application(uuid)
  from public, anon;
grant execute on function public.accept_application_offer(uuid)
  to authenticated;
grant execute on function public.decline_application_offer(uuid)
  to authenticated;
grant execute on function public.withdraw_application(uuid)
  to authenticated;

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
  v_status text;
begin
  select a.applicant_id, c.owner_id, j.id, a.status::text
  into v_applicant_id, v_employer_id, v_job_id, v_status
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
  if v_status not in ('interview', 'offer', 'accepted') then
    raise exception 'Messaging becomes available once the interview stage begins';
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

drop policy if exists "Participants can send conversation messages"
  on public.messages;
create policy "Participants can send active application messages"
  on public.messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1
      from public.conversations c
      join public.applications a on a.id = c.application_id
      where c.id = conversation_id
        and (
          c.applicant_id = (select auth.uid())
          or c.employer_id = (select auth.uid())
        )
        and a.status::text in ('interview', 'offer', 'accepted')
    )
  );
