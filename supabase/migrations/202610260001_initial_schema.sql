create extension if not exists pgcrypto;

create type public.account_role as enum ('applicant', 'employer', 'admin');
create type public.job_status as enum ('draft', 'published', 'closed');
create type public.application_status as enum (
  'applied',
  'interview',
  'offer',
  'rejected',
  'withdrawn'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role public.account_role not null default 'applicant',
  created_at timestamptz not null default now()
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  industry text not null default '',
  location text not null default '',
  website text,
  created_at timestamptz not null default now()
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 160),
  location text not null,
  employment_type text not null default 'Full-time',
  salary_min integer check (salary_min is null or salary_min >= 0),
  salary_max integer check (salary_max is null or salary_max >= salary_min),
  description text not null check (char_length(description) between 20 and 12000),
  status public.job_status not null default 'draft',
  created_at timestamptz not null default now()
);

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  applicant_id uuid not null references public.profiles(id) on delete cascade,
  resume_path text not null,
  cover_letter text not null default '' check (char_length(cover_letter) <= 500),
  status public.application_status not null default 'applied',
  created_at timestamptz not null default now(),
  unique (job_id, applicant_id)
);

create index jobs_status_created_at_idx
  on public.jobs (status, created_at desc);
create index jobs_company_id_idx on public.jobs (company_id);
create index applications_job_id_created_at_idx
  on public.applications (job_id, created_at desc);
create index applications_applicant_id_created_at_idx
  on public.applications (applicant_id, created_at desc);

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text := new.raw_user_meta_data ->> 'role';
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    case
      when requested_role = 'employer' then 'employer'::public.account_role
      else 'applicant'::public.account_role
    end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.create_profile_for_new_user();

create or replace function public.has_published_company_job(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.jobs j
    where j.company_id = p_company_id and j.status = 'published'
  );
$$;

revoke all on function public.has_published_company_job(uuid) from public;
grant execute on function public.has_published_company_job(uuid)
  to anon, authenticated;

alter table public.profiles enable row level security;
alter table public.companies enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;

revoke all on public.profiles, public.companies, public.jobs, public.applications
  from public, anon, authenticated;
grant select on public.profiles to authenticated;
grant select on public.companies, public.jobs to anon, authenticated;
grant insert, update on public.companies, public.jobs to authenticated;
grant select, insert on public.applications to authenticated;
revoke update on public.profiles from authenticated;
grant update (full_name) on public.profiles to authenticated;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "Hiring employers can read applicant names"
  on public.profiles for select to authenticated
  using (
    exists (
      select 1
      from public.applications a
      join public.jobs j on j.id = a.job_id
      join public.companies c on c.id = j.company_id
      where a.applicant_id = profiles.id and c.owner_id = (select auth.uid())
    )
  );
create policy "Users can update their own name"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Company owners can read their companies"
  on public.companies for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "Public can read companies with published jobs"
  on public.companies for select to anon, authenticated
  using (public.has_published_company_job(id));
create policy "Employers can create companies"
  on public.companies for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'employer'
    )
  );
create policy "Company owners can update their companies"
  on public.companies for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "Anyone can read published jobs"
  on public.jobs for select to anon, authenticated
  using (
    status = 'published'
    or exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = (select auth.uid())
    )
  );
create policy "Company owners can create jobs"
  on public.jobs for insert to authenticated
  with check (
    exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = (select auth.uid())
    )
  );
create policy "Company owners can update jobs"
  on public.jobs for update to authenticated
  using (
    exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.companies c
      where c.id = company_id and c.owner_id = (select auth.uid())
    )
  );
create policy "Applicants and hiring employers can read applications"
  on public.applications for select to authenticated
  using (
    applicant_id = (select auth.uid())
    or exists (
      select 1
      from public.jobs j
      join public.companies c on c.id = j.company_id
      where j.id = job_id and c.owner_id = (select auth.uid())
    )
  );
create policy "Applicants can apply to published jobs"
  on public.applications for insert to authenticated
  with check (
    applicant_id = (select auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'applicant'
    )
    and exists (
      select 1 from public.jobs j where j.id = job_id and j.status = 'published'
    )
    and status = 'applied'
    and (storage.foldername(resume_path))[1] = (select auth.uid())::text
  );

revoke update on public.applications from authenticated;

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
  if p_status not in (
    'interview'::public.application_status,
    'offer'::public.application_status,
    'rejected'::public.application_status
  ) then
    raise exception 'Unsupported hiring status';
  end if;

  update public.applications a
  set status = p_status
  from public.jobs j
  join public.companies c on c.id = j.company_id
  where a.id = p_application_id
    and j.id = a.job_id
    and c.owner_id = auth.uid()
    and a.status in (
      'applied'::public.application_status,
      'interview'::public.application_status
    );

  if not found then
    raise exception 'Application not found or status cannot be changed';
  end if;
end;
$$;

revoke all on function public.set_application_status(uuid, public.application_status)
  from public, anon;
grant execute on function public.set_application_status(uuid, public.application_status)
  to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'resumes',
  'resumes',
  false,
  10485760,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do nothing;

create policy "Applicants can upload their own resumes"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'resumes'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Applicants and hiring employers can read resumes"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'resumes'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or exists (
        select 1
        from public.applications a
        join public.jobs j on j.id = a.job_id
        join public.companies c on c.id = j.company_id
        where a.resume_path = name and c.owner_id = (select auth.uid())
      )
    )
  );
create policy "Applicants can delete unsubmitted resumes"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'resumes'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and not exists (
      select 1 from public.applications a where a.resume_path = name
    )
  );
