alter table public.jobs
  add column workplace_type text not null default 'On-site'
    check (workplace_type in ('On-site', 'Hybrid', 'Remote')),
  add column salary_currency text not null default 'PKR'
    check (salary_currency in ('PKR', 'USD')),
  add column salary_period text not null default 'year'
    check (salary_period in ('year', 'month')),
  add column responsibilities text[] not null default '{}'::text[],
  add column requirements text[] not null default '{}'::text[],
  add column benefits text[] not null default '{}'::text[],
  add column skills text[] not null default '{}'::text[],
  add constraint jobs_salary_range_pair_check
    check ((salary_min is null) = (salary_max is null));
