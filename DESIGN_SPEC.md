# Guidely MVP — Product & UI Design Specification

## 1. Design direction

Guidely should feel reassuring, local, and outdoors-oriented: polished enough for international travellers while remaining simple for guides with low-to-moderate technical confidence.

- **Brand personality:** warm, capable, grounded, and adventurous.
- **Visual motif:** Himalayan landscape colours, generous photography, rounded cards, clear route/itinerary structure.
- **Primary audience:** tourists on mobile; guides who need large, plain-language controls; admins using desktop web.
- **Principles:** show trust early, keep the next action obvious, avoid dense forms, and never hide the fact that payment and coordination are off-platform.

## 2. Information architecture

### Tourist navigation

Mobile bottom navigation: **Explore**, **Bookings**, **Saved**, **Profile**.

| Area | Screens |
| --- | --- |
| Explore | Home, search/filter sheet, results, package detail, guide profile, place detail/map |
| Booking | Request form, request confirmation, booking detail, contact handoff, review form |
| Account | Sign in/sign up, language choice, profile, Contact Us, legal pages |

Guests can browse Explore and package/guide pages. Any protected action routes to sign in, then returns to the original action.

### Guide navigation

Mobile bottom navigation: **Dashboard**, **Packages**, **Requests**, **Profile**.

| Area | Screens |
| --- | --- |
| Dashboard | Verification/subscription banner, next requests, quick actions, profile visibility status |
| Packages | Package list, create/edit package, place picker, availability calendar |
| Requests | Request list, request detail, accept/decline confirmation, completed-trip action |
| Profile | Profile/editor, document uploads, subscription selection, Contact Us |

### Admin navigation (web)

Persistent left rail: **Overview**, **Verification**, **Guides**, **Subscriptions**, **Packages**, **Places**, **Support**, **Audit log**.

## 3. Core tourist journeys

### Discover and request a package

1. **Explore home:** destination-led hero for Pokhara, category chips, “Popular packages,” and “Verified local guides.”
2. **Search/results:** a compact search control and filter button. Results are package cards—not generic guide cards—because tourists buy a defined trip.
3. **Package detail:** imagery, package title, guide identity/verification, price in NPR, duration, capacity, places, inclusions, itinerary notes, reviews, and date availability.
4. **Request form:** dates, headcount, trip details, and a fixed summary card. Before submit, explain that this is a request—not a payment or confirmed booking.
5. **Pending state:** confirmation explains when to expect a response and offers Contact Us.
6. **Accepted state:** show a prominent “Contact your guide” section with phone/email and the off-platform payment/coordination disclaimer.
7. **Completed state:** present a review invitation only after the guide marks the trip completed.

### Trust cues

- Display a visible “Verified guide” badge beside the guide’s name and in package cards.
- Include number of completed/reviewed trips when data exists; do not fabricate popularity or reviews.
- Label subscription/verification information only for the guide and admin; tourists see only the verified public badge.
- Show cancellation limitations before a request is submitted: tourists may withdraw only while the request is pending.

## 4. Core guide journeys

### Onboarding

Use a saved multi-step flow with a progress indicator:

1. Account and contact details.
2. Profile: photo, bio, languages, experience, categories.
3. Documents: required-document checklist based on selected categories; upload, retry, and review-pending states.
4. Subscription request: monthly or yearly selection and manual-payment guidance.
5. Review and submit for verification.

The guide dashboard always shows one clear status banner: **Complete profile**, **Documents needed**, **Under review**, **Changes requested**, **Subscription pending**, **Active**, or **Suspended**. It must explain the exact next action.

### Create package

Use a single scrollable form with progressive sections:

1. Basics: title and category.
2. Trip details: duration, capacity, NPR price, and inclusions.
3. Places: searchable admin catalogue, selected-place chips, ordering, plus itinerary notes.
4. Preview and publish.

Use direct language, local examples, numeric keyboards for price/capacity, and inline validation. A guide with an active account may publish immediately; inactive/under-review guides can draft but cannot make a package public.

### Booking requests

Request detail opens with dates, headcount, traveller note, and package summary. It has a persistent **Accept** and **Decline** action area. Accepting asks for confirmation because it blocks overlapping dates. Decline permits an optional private reason but does not promise a counter-offer.

## 5. Visual system

### Colour palette

| Token | Value | Use |
| --- | --- | --- |
| `primary` | `#146B63` | Primary actions, selected controls, active states |
| `primaryContainer` | `#D9F1EC` | Calm highlights and tags |
| `accent` | `#E66F3A` | Booking calls to action and important emphasis |
| `surface` | `#FFFBF6` | App background |
| `surfaceRaised` | `#FFFFFF` | Cards and sheets |
| `ink` | `#1C2927` | Primary text |
| `muted` | `#667370` | Secondary text |
| `success` | `#27835A` | Approved/accepted/completed states |
| `warning` | `#B86A12` | Pending/review-required states |
| `danger` | `#BA3D3D` | Rejected/suspended/destructive actions |

Use colour with labels and icons; never rely on colour alone for status.

### Typography

- Use a highly legible sans serif with strong Devanagari support, such as **Noto Sans** for interface/body text.
- Use a distinct but compatible display face only if it supports both English and Nepali; otherwise use Noto Sans with a heavier heading weight.
- Base body size: 16 px mobile. Never use less than 14 px for meaningful content.
- Heading scale: 28/34 px page title, 22/28 px section title, 18/24 px card title.

### Components

- 12 px rounded cards, 16 px horizontal screen padding, 12 px vertical spacing rhythm.
- Primary buttons are full-width in forms; destructive actions are always outlined or confirmed.
- Use chips for categories, languages, places, and filters. Chips must wrap and remain keyboard-accessible on web.
- Show image placeholders and neutral loading skeletons rather than empty card layouts.
- Use a persistent bottom action bar on package and request-detail screens where an action is available.

## 6. Responsive behavior and accessibility

- **Mobile (< 600 px):** single column, bottom navigation, filter bottom sheet, full-width actions.
- **Tablet (600–1024 px):** two-column result cards where space permits; side-sheet filters.
- **Desktop (> 1024 px):** content width capped near 1200 px; package detail uses content + booking summary columns; admin uses a left rail and data tables.
- All interactive controls need visible focus, semantic labels, and a minimum 44 × 44 px touch target.
- Support screen readers, dynamic type, keyboard navigation on web, colour contrast of at least 4.5:1 for normal text, and text expansion without clipping.
- English and Nepali strings must be designed as flexible content; avoid fixed-width labels and text embedded in images.

## 7. Status and empty-state language

| Situation | Message direction | Primary action |
| --- | --- | --- |
| No search results | “Try changing your dates or filters.” | Clear filters |
| Guide under review | “We’re reviewing your documents.” | View requirements |
| Documents rejected | State the admin reason plainly. | Update documents |
| Subscription pending | “Activate your subscription to become discoverable.” | View payment guidance |
| Booking pending | “Your guide will review this request.” | View request |
| Booking accepted | “Your guide accepted. Coordinate your trip directly.” | Contact guide |
| Connectivity issue | “We couldn’t refresh this yet.” | Retry |

## 8. Required design deliverables before coding

1. Brand reference/moodboard and final logo decision.
2. Low-fidelity flows for tourist request, guide onboarding/package creation, and admin verification.
3. High-fidelity mobile screens for the critical flows and responsive admin desktop screens.
4. Component inventory and design tokens matching the visual system above.
5. Clickable prototype tested with at least three tourists and three guides in Pokhara or comparable target users.
6. A revised implementation backlog that incorporates findings before UI code begins.

## 9. Design acceptance criteria

- A first-time tourist can identify a verified guide, package cost, duration, inclusions, and request action without explanation.
- A guide can identify their current approval blocker and next required action from the dashboard.
- A user understands before submission that a request is not a payment or a confirmed booking.
- An accepted booking makes the contact handoff and off-platform disclaimer unmistakable.
- All core flows remain understandable in English and Nepali at mobile width and on desktop web.
