alter table public.profiles
  add column if not exists headline text not null default '',
  add column if not exists phone text not null default '',
  add column if not exists location text not null default '',
  add column if not exists years_experience integer
    check (years_experience is null or years_experience between 0 and 80),
  add column if not exists avatar_path text;

grant update (headline, phone, location, years_experience, avatar_path)
  on public.profiles to authenticated;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'avatars',
  'avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = false,
      file_size_limit = 5242880,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "Users can read their own profile photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can upload their own profile photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can update their own profile photos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can delete their own profile photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
