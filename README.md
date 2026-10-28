# JobFinder

JobFinder is a Flutter job-search client with a Supabase-backed applicant and
employer workflow. When Supabase is not configured, the app remains available
as a clearly labelled local demo; demo applications are not sent to employers.

## Supabase project setup

1. Create a Supabase project and keep its database credentials private.
2. In the Supabase SQL Editor, run
   [`supabase/migrations/202610260001_initial_schema.sql`](supabase/migrations/202610260001_initial_schema.sql).
   It creates profiles, companies, jobs, applications, row-level security
   policies, a private `resumes` storage bucket, and a guarded hiring-status
   function.
3. Then run
   [`supabase/migrations/202610270001_application_chat.sql`](supabase/migrations/202610270001_application_chat.sql).
   It creates application-linked conversations, participant-only message
   access, real-time message delivery, read tracking, and guarded conversation
   creation.
4. Then run
   [`supabase/migrations/202610280001_job_post_details.sql`](supabase/migrations/202610280001_job_post_details.sql).
   It adds structured work arrangement, compensation, responsibilities,
   qualifications, skills, and benefits to job posts.
5. Then run
   [`supabase/migrations/202610290001_application_lifecycle.sql`](supabase/migrations/202610290001_application_lifecycle.sql).
   It adds offer acceptance, applicant withdrawal, guarded interview/offer
   transitions, and unlocks application chat at the interview stage.
6. Then run
   [`supabase/migrations/202610300001_profile_media_details.sql`](supabase/migrations/202610300001_profile_media_details.sql).
   It adds structured profile details and a private, user-scoped avatar bucket.
7. Then run
   [`supabase/migrations/202610310001_live_job_updates.sql`](supabase/migrations/202610310001_live_job_updates.sql).
   It enables Realtime events for job-post changes. The app reloads the job
   feed when a post is created, updated, or removed, and polls as a fallback.
8. In **Authentication → Providers**, enable Email. For production, configure
   verified sender email/SMTP, and appropriate sign-up rate limits. Add
   `com.jobfinder.finderjob://auth/**` to **Authentication → URL Configuration
   → Redirect URLs** for email confirmation and password recovery.
9. Copy the project URL and its **publishable** key (or legacy anon key). Never
   put a `service_role` key in the Flutter app.
10. Run the app with local compile-time values:

   ```powershell
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

   These values are not committed to source control. For release builds, supply
   them through your CI secret/configuration system. The publishable/anon key
   is intended for clients; the RLS policies, not that key, enforce access.

## Included flows

- Email/password applicant or employer registration, sign-in, and password
  reset. Email verification can be enabled in Supabase Auth.
- Employers can self-register, create a company, and publish structured jobs
  with location, workplace arrangement, employment type, job summary,
  responsibilities, qualifications, and required skills. Salary and benefits
  are optional. Employers can review applications, open short-lived signed
  resume links, move applications to interview, offer, or rejected, and start
  an application-linked chat with each applicant from the review card.
- Application progression is guarded: Applied → Interview → Offer → Accepted.
  Employers can reject at the application or interview stage; applicants can
  decline an offer or withdraw before accepting. Messaging unlocks at Interview
  and remains available through an accepted offer. Employers can filter their
  applicant review by job post.
- Applicants can browse published Supabase jobs, upload a private PDF/DOC/DOCX
  resume up to 10 MB, submit a cover letter, track application status, accept or
  decline offers, withdraw active applications, and message the hiring
  employer from the interview stage onward.
- Profiles load account and professional details from the protected profile
  record. Users can update their name, professional title, phone, location,
  skills, years of experience, experience summary, and preferred job types.
  Profile photos use a private, user-scoped storage path and short-lived signed
  URLs; applicants can also see securely linked resumes attached to their
  applications. Local demo profile edits and selected photos last for the
- The Home job feed listens for Supabase Realtime job-post updates and refreshes
  periodically as a fallback. External job boards are not connected; integrate
  them only through an authorized API or feed configured on trusted server
  infrastructure. Local demo profile edits and selected photos last for the
  current app session.
- Messages are stored in Supabase and delivered to the other participant in
  real time. Row-level security limits conversation access to its applicant and
  employer. Install the chat migration above before using these features.
- Without project configuration, sample jobs remain browseable and applications
  are explicitly identified as demo-only. The job seeker and employer demo
  entry points allow an end-to-end local preview: create a job post, find it in
  the job feed, submit a demo application, review it in the employer workspace,
  change its status, and preview both sides of a chat. Demo posts, applications,
  and messages are held in app memory for the current session on one device;
  they do not synchronize between people or devices. Resumes are not uploaded
  and nothing is sent online.

## Production launch checklist

Self-service employer registration is enabled by product choice. Before public
launch, add employer/company verification and moderation, abuse reporting,
privacy/retention and account-deletion flows, audit logs, backups, monitoring,
and a separate staging project. The custom email callback is configured for
Android and iOS; configure and test equivalent deep links for any other shipped
platform. Test RLS and storage policies with
separate applicant and employer accounts; do not treat UI visibility as access
control. Keep all privileged service keys on trusted server infrastructure.
