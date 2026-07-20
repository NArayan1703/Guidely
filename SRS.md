# Software Requirements Specification (SRS)
## Guidely — Local Tour Guide Booking Platform

**Version:** 1.0 (MVP)
**Date:** July 16, 2026
**Prepared for:** Guidely Founding Team
**Launch Market:** Pokhara, Nepal

---

## 1. Introduction

### 1.1 Purpose
This document specifies the functional and non-functional requirements for the MVP (Minimum Viable Product) version of **Guidely**, a two-sided marketplace connecting tourists with independent local tour guides. This SRS serves as the reference for design, development, and testing of the initial release.

### 1.2 Scope
Guidely connects tourists visiting Pokhara, Nepal with verified local guides across multiple categories (trekking, adventure/sports, nature/wildlife, cultural/city, wellness). The platform facilitates **discovery and booking requests only** — it does not process payments between tourists and guides, nor does it provide in-app messaging between them. Guide subscription fees are collected and verified manually by the admin team in v1.

**In scope for v1 (MVP):**
- Tourist-facing guide search, filtering, and booking requests
- Guide profile creation, category selection, and document upload
- Admin-managed guide verification
- Admin-managed subscription activation (manual, no live payment gateway)
- "Contact Us" flow for both tourists and guides
- Push notifications for booking status changes

**Out of scope for v1 (deferred to v2+):**
- In-app payment processing (eSewa integration) for guide subscriptions
- In-app payment/escrow between tourist and guide
- In-app real-time chat/messaging
- AI-based guide recommendations
- Multi-city expansion (Kathmandu, Chitwan, Lumbini)
- Automated license/document verification (OCR)

### 1.3 Definitions, Acronyms, Abbreviations

| Term | Definition |
|---|---|
| Tourist | End user seeking to book a local guide |
| Guide | Independent local tour guide offering services on the platform |
| Admin | Guidely internal team member managing verification, subscriptions, and support |
| MVP | Minimum Viable Product |
| OSM | OpenStreetMap |
| FCM | Firebase Cloud Messaging |
| SRS | Software Requirements Specification |

### 1.4 References
- Guidely Idea Validation & Research document (internal)
- Nepal Tourism Board guide licensing guidelines (external, to be confirmed with legal counsel)

---

## 2. Overall Description

### 2.1 Product Perspective
Guidely is a new, standalone mobile and web application. It is not an extension of an existing system. It targets an underserved niche — direct tourist-to-guide booking — currently handled informally via hotels, agencies, and social messaging apps in Nepal.

### 2.2 User Classes and Characteristics

| User Class | Description | Technical Proficiency |
|---|---|---|
| Tourist | Domestic and international travelers, ages 18–50 | Moderate to high (smartphone-native) |
| Guide | Independent local guides, ages 22–60 | Low to moderate |
| Admin | Guidely internal staff | High |

### 2.3 Operating Environment
- **Mobile:** iOS 13+, Android 8+
- **Web:** Modern browsers (Chrome, Safari, Firefox, Edge) — latest two versions
- **Backend:** Supabase (hosted, managed Postgres + Auth + Storage)
- **Connectivity:** Must function on low-bandwidth mobile networks common in Nepal

### 2.4 Design and Implementation Constraints
- Single Flutter codebase must serve iOS, Android, and Web
- No live payment gateway integration in v1 (manual admin-managed subscriptions and verification only)
- Must comply with Nepal's data privacy norms and any applicable tourism regulations for guide licensing (to be reviewed with legal counsel before launch)
- Budget and timeline constraints require use of managed/hosted services (Supabase, FCM) over custom infrastructure

### 2.5 Assumptions and Dependencies
- Guides have basic smartphone literacy and internet access
- OpenStreetMap data coverage for Pokhara is sufficiently accurate for guide location display
- Admin team has capacity to manually process verification and subscription requests within a reasonable SLA (e.g., 24–48 hours)

---

## 3. System Features (Functional Requirements)

### 3.1 Epic A — Tourist: Discovery & Booking

**FR-A1: Account Creation**
The system shall allow tourists to register via email or Google sign-in.

**FR-A2: Guest Browsing**
The system shall allow tourists to browse guide listings without an account; account creation is required only to submit a booking request.

**FR-A3: Search & Filter**
The system shall allow tourists to filter guides by:
- Category (trekking, adventure/sports, nature/wildlife, cultural/city, wellness)
- Language spoken
- Price range
- Rating
- Availability dates

**FR-A4: Guide Profile View**
The system shall display, for each guide: bio, photo, categories/specialties, languages, years of experience, verification badge (if applicable), price, ratings, and reviews.

**FR-A5: Booking Request**
The system shall allow a tourist to submit a booking request specifying trip dates, headcount, and trip details.

**FR-A6: Booking Status Notification**
The system shall notify the tourist via push notification (FCM) when a guide accepts or declines a booking request.

**FR-A7: Contact Us**
The system shall provide a "Contact Us" form/button allowing tourists to message the Guidely admin team directly for support, payment coordination, or dispute reporting.

**FR-A8: Review Submission**
The system shall allow a tourist to submit a star rating and written review for a guide after a booking's trip dates have passed.

### 3.2 Epic B — Guide: Onboarding & Profile Management

**FR-B1: Guide Registration**
The system shall allow guides to register and create a profile including bio, photo, languages spoken, categories/specialties, and pricing.

**FR-B2: Category Selection**
The system shall allow guides to select one or more categories: Trekking, Adventure/Sports, Nature/Wildlife, Cultural/City, Wellness.

**FR-B3: Document Upload**
The system shall allow guides in license-required categories (Trekking, Adventure/Sports) to upload a government-issued guide license and relevant certifications.

**FR-B4: Verification Status Display**
The system shall display a guide's verification status (Pending, Approved, Rejected) to the guide, and show an "Approved/Verified" badge on their public profile once approved.

**FR-B5: Subscription Selection**
The system shall allow a guide to select a subscription plan (monthly or yearly) and submit a request; this request shall be routed to the admin for manual processing (no live payment gateway in v1).

**FR-B6: Availability Calendar**
The system shall allow a guide to mark available/unavailable dates on a calendar visible to tourists.

**FR-B7: Booking Management**
The system shall allow a guide to view, accept, or decline incoming booking requests.

**FR-B8: Booking Status Notification**
The system shall notify the guide via push notification (FCM) when a new booking request is received.

**FR-B9: Contact Us**
The system shall provide a "Contact Us" form/button allowing guides to message the Guidely admin team for subscription payment coordination or support.

### 3.3 Epic C — Admin: Verification, Subscription & Trust/Safety

**FR-C1: Verification Queue**
The system shall provide an admin dashboard listing all guide profiles pending verification, with document viewer and Approve/Reject actions.

**FR-C2: Verification Rules by Category**
The system shall apply the following minimum verification standards:
- Trekking / Adventure & Sports: mandatory license/certification upload, reviewed and approved by admin before profile goes live.
- Cultural / Nature / Wellness: basic identity verification; license optional.

**FR-C3: Subscription Management**
The system shall allow an admin to manually mark a guide's subscription as Active, Expired, or Pending Payment, and to set the subscription tier and renewal date.

**FR-C4: Guide Suspension**
The system shall allow an admin to suspend or remove a guide's profile from search results (e.g., due to complaints or safety violations).

**FR-C5: Support Inbox**
The system shall route all "Contact Us" submissions (from tourists and guides) into a single admin-accessible inbox/table for follow-up.

**FR-C6: Platform Metrics**
The system shall provide an admin view of basic platform metrics: number of registered guides (by category and verification status), number of registered tourists, number of booking requests, and active subscriptions.

---

## 4. External Interface Requirements

### 4.1 User Interfaces
- Mobile and web apps built with a single Flutter codebase, following a consistent design system across platforms.
- Admin dashboard may be a simpler web-only interface (Flutter Web or a lightweight admin panel).

### 4.2 Hardware Interfaces
- Standard smartphone hardware (camera for document/photo upload, GPS for location-based search).

### 4.3 Software Interfaces
- **Supabase:** Authentication, Postgres database, file storage (license/photo uploads).
- **OpenStreetMap API:** Guide location display and map-based search.
- **Firebase Cloud Messaging (FCM):** Push notifications for booking status updates.

### 4.4 Communications Interfaces
- HTTPS for all client-server communication.
- No third-party messaging (e.g., WhatsApp) integration in v1 — all support/contact routed through in-app "Contact Us" to admin.

---

## 5. Non-Functional Requirements

### 5.1 Performance
- Search results shall load within 3 seconds under standard 4G mobile network conditions.
- The app shall remain functional (with graceful degradation) on low-bandwidth 3G connections common in parts of Pokhara.

### 5.2 Security
- All user credentials shall be managed via Supabase Auth with industry-standard hashing.
- Uploaded guide documents (licenses, ID) shall be stored securely with access restricted to the guide and admin roles only.
- Role-based access control (Row-Level Security) shall enforce that tourists, guides, and admins can only access data relevant to their role.

### 5.3 Usability
- The app shall support at minimum English and Nepali language interfaces at launch.
- Core booking flows (search → profile → request) shall be completable within 5 taps/screens for a first-time user.

### 5.4 Reliability & Availability
- Target uptime of 99% for MVP, relying on Supabase's managed infrastructure SLA.

### 5.5 Scalability
- Database schema shall be designed to support future expansion to additional cities and guide categories without requiring structural rework.

### 5.6 Maintainability
- Single Flutter codebase shall be structured to allow one developer to maintain and extend features across all three platforms (iOS, Android, Web).

### 5.7 Legal & Compliance
- Guide licensing verification standards shall be reviewed against Nepal Tourism Board / Department of Tourism requirements prior to launch.
- Terms of Service shall clearly state that Guidely does not process or guarantee payments between tourists and guides in v1, and bears no liability for off-platform payment disputes.

---

## 6. Data Model Overview (High-Level)

**Core entities (Supabase/Postgres):**
- `users` (tourists) — id, name, email, language, created_at
- `guides` — id, name, bio, categories[], languages[], price_range, location, verification_status, subscription_status, subscription_tier, subscription_expiry
- `guide_documents` — id, guide_id, document_type, file_url, review_status
- `bookings` — id, tourist_id, guide_id, trip_dates, headcount, status (pending/accepted/declined/completed), created_at
- `reviews` — id, booking_id, tourist_id, guide_id, rating, comment, created_at
- `contact_requests` — id, user_id (nullable), user_type (tourist/guide), message, status, created_at
- `admin_users` — id, name, role

---

## 7. Guide Category Taxonomy (Reference)

| Category | Examples | Verification |
|---|---|---|
| Trekking | ABC, Annapurna Circuit, Poon Hill, Mardi Himal | Mandatory license |
| Adventure/Sports | Paragliding, zip-lining, rafting, climbing, mountain biking | Mandatory certification |
| Nature/Wildlife | Bird watching, nature walks | Basic ID |
| Cultural/City | Heritage tours, walking tours, temple/cave tours | Basic ID |
| Wellness/Niche | Yoga, meditation, photography tours | Basic ID |

---

## 8. MVP Feature Summary (v1 vs. v2)

| Feature | v1 (MVP) | v2 (Future) |
|---|---|---|
| Guide search & filters | ✅ | Enhanced (AI recommendations) |
| Booking requests | ✅ | — |
| In-app payment (tourist–guide) | ❌ | Possible escrow model |
| In-app messaging | ❌ (Contact Us to admin instead) | Possible in-app chat |
| Guide subscription payment | ❌ (manual, admin-managed) | Live eSewa/Khalti integration |
| Guide verification | ✅ (manual, admin-reviewed) | Possibly semi-automated |
| Multi-city support | ❌ (Pokhara only) | Kathmandu, Chitwan, Lumbini |
| Reviews & ratings | ✅ | — |

---

## 9. Appendix: Open Items for Legal/Compliance Review
- Confirm exact Nepal Tourism Board licensing requirements per guide category.
- Confirm data privacy obligations for storing guide ID/license documents.
- Draft Terms of Service clarifying no payment guarantee/liability for off-platform transactions.

---

*End of Document*