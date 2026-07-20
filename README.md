# Guidely

Guidely is a Flutter travel marketplace that helps travellers discover trusted local guides and tour packages in Nepal.

The MVP supports three roles:

- **Travellers** discover, search, save, and request trips.
- **Guides** manage their profile, tour packages, cover photos, and booking requests.
- **Admins** review guide applications, moderate packages, and manage support requests.

## Features

- Email/password authentication with persistent sessions and password reset.
- Traveller package discovery, filters, saved packages, reviews, and secure booking requests.
- Guide dashboard, profile editing, package drafts, active-package editing, and request management.
- Admin moderation for guide verification, packages, bookings, and support requests.
- Supabase Storage for profile photos and package cover images.
- Custom Guidely app name and launcher icon for Android, iOS, and web.

## Stack

- [Flutter](https://flutter.dev/) and Dart
- [Supabase](https://supabase.com/) Auth, Postgres, Storage, and Row Level Security
- Resend SMTP for authentication emails

## Run locally

```bash
flutter pub get
flutter run
```

The Supabase project URL and publishable key are configured in `lib/app/bootstrap.dart`. The publishable key is safe for client apps; never add a Supabase service-role or secret key to this repository.

## Database setup

Run the SQL files in `supabase/migrations/` in filename order through the Supabase SQL Editor. They create the tables, policies, storage buckets, booking logic, and security controls required by the app.

Optional local demo data is available in `supabase/seed.sql`.

## Security

Guidely uses Supabase Row Level Security and narrowly scoped database permissions. Sensitive actions, including trip requests, package changes, and guide approval, are validated server-side.

Before releasing, verify that Supabase Security Advisor has no unresolved errors, enable email confirmation, and keep service-role keys server-only.

## Build Android APK

```bash
flutter build apk --release
```

The generated APK is at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Project structure

```text
lib/                  Flutter app source
supabase/migrations/  Database schema and security migrations
supabase/seed.sql     Optional demo data
assets/branding/      Guidely brand assets
test/                 Widget tests
```

## Status

Version `1.0.0+1` is the first MVP release. Planned future work includes availability calendars, notifications, payments, richer reviews, and expansion to more destinations across Nepal.
