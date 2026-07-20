# Development guide

Keep work feature-owned:

- `features/auth`: sign-in, traveller signup, guide registration, session flow.
- `features/tourist`: exploration, packages, bookings, saved trips, profile.
- `features/guide`: guide dashboard, packages, requests, onboarding.
- `features/admin`: admin-only screens and moderation workflows.
- `shared/widgets`: small UI elements reused by more than one feature.
- `supabase/migrations`: schema and RLS changes; never change authorization only in Flutter.

When adding a backend feature, ship its migration and RLS policy with the UI. Keep Supabase service or secret keys out of Flutter; only server-side code may use them.

Add a widget test for each new user flow and run:

```sh
flutter analyze
flutter test
```
