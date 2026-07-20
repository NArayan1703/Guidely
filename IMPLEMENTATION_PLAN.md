# Guidely MVP — Implementation Specification

## 1. Product boundary

Guidely is a Pokhara-only marketplace that helps tourists discover and request fixed tour packages from local guides.

- Tourists may browse without an account. Signing in is required to request a booking, withdraw a pending request, or review a completed booking.
- Guides create profiles and fixed packages. A guide is searchable only after admin verification and an active subscription.
- Admins verify guides, maintain subscriptions and the place catalogue, handle support, and suspend unsafe listings.
- Payments and trip coordination occur outside the app. After a guide accepts a request, the app reveals each party's phone and email with an off-platform disclaimer.
- In-app chat, tourist-to-guide payment, refunds, automatic document verification, and locations outside Pokhara are not part of this MVP.

## 2. Technology and architecture

| Area | Choice |
| --- | --- |
| Client | Flutter, one codebase for Android, iOS, and web |
| State/navigation | Feature-first Flutter structure with declarative routes and repository-backed controllers |
| Authentication | Supabase Auth: email/password and Google OAuth |
| Data | Supabase Postgres with Row-Level Security (RLS) |
| Files | Supabase Storage private buckets for IDs/licenses; public or signed profile images |
| Server rules | Supabase SQL functions and Edge Functions for transactional actions and notifications |
| Notifications | Firebase Cloud Messaging, triggered for new bookings and status changes |
| Maps | OpenStreetMap-compatible tile/geocoding provider; maps are limited to Pokhara catalogue places |
| Localization | English and Nepali, with English as the fallback |

The Flutter application has three protected experiences in the same project:

1. Tourist discovery and booking pages (mobile-first, also web).
2. Guide onboarding, package management, calendar, and booking pages.
3. Admin-only responsive web routes for operations.

## 3. Roles and publication rules

### Roles

| Role | Capability |
| --- | --- |
| Guest | Browse only publicly visible guides and packages. |
| Tourist | Manage their profile, submit/withdraw requests, view their bookings, and review their completed bookings. |
| Guide | Manage their guide profile, documents, packages, availability, and incoming booking decisions. |
| Admin | Verify guides, manage subscriptions/places/support, moderate packages, suspend guides, and view metrics. |

### Visibility rule

A guide and its active packages appear in public results only when all conditions are true:

- `guides.verification_status = approved`
- `subscriptions.status = active` and `ends_at` is in the future
- `guides.status = active`
- `tour_packages.status = active`

Suspension or an expired subscription removes the guide and all packages from public search immediately. Existing participants and admins retain access to the affected booking record.

## 4. Data model

Use UUID primary keys, `created_at`, and `updated_at` timestamps on mutable tables. IDs below are foreign keys unless marked otherwise.

### Identity and profile tables

| Table | Required fields |
| --- | --- |
| `profiles` | `id` (Auth user ID), `role` (`tourist`, `guide`, `admin`), `full_name`, `phone`, `preferred_locale`, `email`, `created_at` |
| `tourist_profiles` | `user_id`, optional country and avatar URL |
| `guides` | `user_id`, `bio`, `photo_path`, `languages text[]`, `categories guide_category[]`, `years_experience`, `verification_status`, `status`, `rejection_reason` |
| `guide_documents` | `id`, `guide_id`, `document_type`, `storage_path`, `review_status`, `reviewed_by`, `reviewed_at`, `rejection_reason` |
| `subscriptions` | `id`, `guide_id`, `tier` (`monthly`, `yearly`), `status` (`pending_payment`, `active`, `expired`), `starts_at`, `ends_at`, `managed_by` |
| `device_tokens` | `id`, `user_id`, `token`, `platform`, `last_seen_at` |

`guide_category` values: `trekking`, `adventure_sports`, `nature_wildlife`, `cultural_city`, `wellness`.

Trekking and adventure/sports guides cannot move to verification review without at least one license/certification document. Other categories require an identity document.

### Places and packages

| Table | Required fields |
| --- | --- |
| `places` | `id`, `name_en`, `name_ne`, `description_en`, `description_ne`, `category`, `latitude`, `longitude`, `image_path`, `is_active`, `created_by` |
| `tour_packages` | `id`, `guide_id`, `title`, `category`, `duration_days`, `capacity`, `price_npr`, `inclusions text[]`, `itinerary_notes`, `status`, `created_at` |
| `tour_package_places` | `package_id`, `place_id`, `sort_order` |
| `guide_availability_blocks` | `id`, `guide_id`, `starts_on`, `ends_on`, `kind` (`unavailable`, `available_override`), `note` |

Packages are public immediately when created or updated by an already verified, active guide. Admins may set `tour_packages.status` to `inactive` to moderate content. Guides select one or more admin-managed places and may add free-text itinerary notes.

### Bookings, reviews, and support

| Table | Required fields |
| --- | --- |
| `bookings` | `id`, `tourist_id`, `guide_id`, `package_id`, `starts_on`, `ends_on`, `headcount`, `trip_details`, `status`, `guide_completed_at`, `created_at` |
| `reviews` | `id`, `booking_id` (unique), `tourist_id`, `guide_id`, `rating` (1–5), `comment`, `created_at` |
| `contact_requests` | `id`, nullable `user_id`, `sender_role`, `subject`, `message`, `status` (`open`, `in_progress`, `closed`), `handled_by`, `created_at` |
| `admin_audit_log` | `id`, `admin_id`, `action`, `entity_type`, `entity_id`, `metadata`, `created_at` |

`bookings.status` values are `pending`, `accepted`, `declined`, `withdrawn`, and `completed`.

## 5. Booking and review workflow

1. A tourist selects a visible package, dates, headcount, and trip details.
2. The server validates authentication, package visibility, valid date range, headcount no greater than package capacity, and guide availability.
3. The request is stored as `pending`; the guide receives an FCM notification.
4. A tourist may withdraw only their own `pending` booking.
5. The guide may accept or decline only their own `pending` booking. Acceptance transactionally confirms no overlapping accepted booking exists for that package and blocks overlapping new requests.
6. Accepted bookings show both parties’ phone/email and the off-platform coordination/payment disclaimer.
7. The guide marks an accepted booking as `completed` after the trip. The tourist may then create exactly one rating and written review.

The package capacity is shown to tourists but is not pooled across bookings in v1: one accepted booking makes that package unavailable for conflicting dates.

## 6. Public and protected user experiences

### Tourist

- Home and package discovery with category, language, price, rating, place, and date filters.
- Guide profile: verification badge, bio, languages, experience, packages, places, ratings, and reviews.
- Package detail: duration, capacity, inclusions, places/map, itinerary notes, price in NPR, availability, and booking form.
- My bookings: pending, accepted, declined, withdrawn, and completed sections; pending withdrawal; contact handoff after acceptance; review form after completion.
- Contact Us form available to guests and authenticated tourists.

### Guide

- Role-aware sign-up and onboarding with identity/profile details, categories, required documents, and subscription selection.
- Verification and subscription status pages with rejection reasons and support entry point.
- Profile editor, package list/editor, place picker, and availability calendar.
- Incoming booking inbox with request detail and accept/decline decisions.
- Completed-booking action and Contact Us form.

### Admin web dashboard

- Overview metrics: tourist count, guides by status/category, booking counts by state, active subscriptions, and open support requests.
- Verification queue with private signed document viewer and approve/reject actions.
- Subscription management: monthly/yearly tier, active/pending/expired status, start/end dates.
- Guide moderation: suspend/reactivate and package deactivate/reactivate actions.
- Place catalogue CRUD, including localized fields and Pokhara coordinates.
- Support inbox with assignment and open/in-progress/closed states.
- Audit log for all admin moderation, verification, and subscription changes.

## 7. Security and server-side rules

- Do not trust Flutter clients for role checks, status transitions, public visibility, storage URLs, or booking overlap rules.
- RLS permits users to read/update only their profile and role-specific records; tourists can access only their bookings/reviews; guides only their own packages/documents/bookings; admins use a custom JWT role claim.
- Public queries use a read-only `public_packages` view that applies every visibility condition and never exposes private phone/email/document fields.
- Store document files in a private `guide-documents` bucket. Use short-lived signed URLs only for the owning guide and admins.
- Permit review insertion only through a database function that checks booking ownership, completed state, and one-review-per-booking.
- Implement booking creation, accept, decline, withdraw, complete, and admin status changes as database RPCs or Edge Functions with explicit authorization and audit logging.
- Validate file MIME type/size, dates, NPR price greater than zero, capacity at least one, rating range, and all user-entered string lengths.

## 8. Delivery sequence

1. Add project configuration, environment template, Supabase client initialization, theme, localization, authentication, profile/role routing, and shared error/loading states.
2. Add migrations, enums, indexes, storage policies, RLS, public views, transactional RPCs, and seed Pokhara places.
3. Build guide onboarding, documents, verification/subscription status, profile management, package editor, place selection, and availability calendar.
4. Build tourist discovery, filters, guide/package pages, booking request flow, booking history, contact handoff, and review flow.
5. Build admin web routes for all operational workflows and metrics.
6. Integrate FCM token registration and notifications, maps, localization, accessibility, and low-bandwidth image/loading behaviour.
7. Add tests, deployment documentation, Supabase setup instructions, and a pre-launch verification checklist.

## 9. Testing and acceptance criteria

- Guests can discover only active packages from approved, subscribed, non-suspended guides.
- A guide cannot submit required-category verification without required documents; only admins can approve/reject.
- Tourists cannot create invalid date/headcount requests, book their own package, access another tourist’s data, or review early/more than once.
- Pending bookings can be withdrawn; only the receiving guide can accept/decline; accepted conflicts are prevented atomically.
- Acceptance reveals contact information only to the two booking parties; completion enables exactly one review.
- Private documents are inaccessible to public users and other guides, including by direct storage URL attempts.
- Admin changes to subscription, verification, moderation, places, and support state are authorized and audited.
- Widget tests cover forms, state rendering, and route guards; integration tests cover authentication, RLS/RPC actions, booking lifecycle, and admin workflows.
- Flutter analysis and target-platform builds complete successfully; English and Nepali layouts remain usable on phone and desktop widths.

## 10. Configuration required before deployment

- `SUPABASE_URL` and `SUPABASE_ANON_KEY` for Flutter runtime configuration.
- Supabase OAuth redirect URLs for Android, iOS, and web; Google OAuth credentials.
- FCM Firebase configuration for Android, iOS, and web, plus server credentials for notification delivery.
- OpenStreetMap-compatible map/geocoding provider policy and attribution configuration.
- Initial admin account assignment, manual verification SLA, subscription terms, privacy policy, and off-platform payment disclaimer approved by the founding team.
