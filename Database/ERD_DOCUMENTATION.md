# 📊 CinemaVerse - Entity Relationship Diagram (ERD) Documentation

## Overview

This document provides a comprehensive breakdown of the CinemaVerse database schema with detailed ERD information. The updated schema includes advanced features for enterprise-level cinema ticket booking management.

---

## 🏗️ Schema Architecture

### Layer 1: Core Domain Entities

```
┌─────────────────────────────────────────────────────────────────┐
│                    CORE DOMAIN ENTITIES                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐      ┌──────────────┐    ┌─────────────┐   │
│   │    USERS     │      │    ADMIN     │    │    CITY     │   │
│   ├──────────────┤      ├──────────────┤    ├─────────────┤   │
│   │* user_email  │      │* admin_email │    │* city_name  │   │
│   │  name        │      │  name        │    │  [location] │   │
│   │  phone_no    │      │  phone_no    │    └─────────────┘   │
│   │  password    │      │  password    │           △            │
│   │  created_at  │      │  created_at  │           │            │
│   └──────────────┘      └──────────────┘           │            │
│         △                      △                   │            │
│         │                      │                   │            │
│         └──────────┬───────────┘                   │            │
│                    │                               │            │
│                    └───────────────────────────────┘            │
│                                                                  │
│   ┌──────────────┐      ┌──────────────┐                       │
│   │    MOVIE     │      │    CINEMA    │                       │
│   ├──────────────┤      ├──────────────┤                       │
│   │* movie_title │      │* cinema_name │                       │
│   │  genre       │      │  cinema_area │                       │
│   │  duration    │      │  admin_email │ ◄─── FK to ADMIN     │
│   │  release_date│      │  cinema_city │ ◄─── FK to CITY      │
│   │  price       │      │  pincode     │                       │
│   │  created_at  │      │  total_scr   │                       │
│   └──────────────┘      │  created_at  │                       │
│                         └──────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 2: Cinema Infrastructure

```
┌─────────────────────────────────────────────────────────────────┐
│                  CINEMA INFRASTRUCTURE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│         CINEMA (1)                                              │
│            │                                                    │
│            │ has many (1:N)                                     │
│            ▼                                                    │
│         SCREEN (N)                  SEAT (M)                   │
│         ┌────────┐                ┌────────┐                  │
│         │ screen │─────(1:M)─────►│ seat   │                  │
│         └────────┘                └────────┤                  │
│            │                       * seat_id                   │
│            │ 1 screen has many     * screen_id (FK)            │
│            │ showtimes             * seat_row                  │
│            ▼                        * seat_number              │
│         SHOWTIME (N)               * seat_type                │
│         ┌──────────┐               * is_available             │
│         │showtime  │                                           │
│         ├──────────┤        SHOWTIME_SEAT_AVAILABILITY         │
│         │* st_id   │        ┌────────────────────┐            │
│         │* movie_t │        │* avail_id          │            │
│         │  screen  │        │* showtime_id (FK)  │            │
│         │  show_d  │       ►│* seat_id (FK)      │            │
│         │  start_t │        │  is_booked         │            │
│         │  end_t   │        │  booked_by         │            │
│         │  is_acti │        └────────────────────┘            │
│         └──────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 3: Booking & Payment

```
┌─────────────────────────────────────────────────────────────────┐
│                   BOOKING & PAYMENT FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   USER (1)                                                      │
│     │                                                           │
│     │ places (1:N)                                             │
│     ▼                                                           │
│   BOOKING (N)                        BOOKING_STATUS_HISTORY    │
│   ┌─────────────┐                    ┌──────────────────┐     │
│   │ booking_id  │◄─────────────────►│ status_hist_id   │     │
│   │ user_email  │ references         │ booking_id (FK)  │     │
│   │ showtime_id │                    │ prev_status      │     │
│   │ total_amt   │                    │ new_status       │     │
│   │ booking_sts │                    │ changed_at       │     │
│   │ is_deleted  │                    └──────────────────┘     │
│   └─────────────┘                                              │
│     │ 1:N                                                       │
│     ▼                                                           │
│   BOOKING_SEAT                       CANCELLATION_REQUEST      │
│   ┌──────────────┐                   ┌─────────────────┐      │
│   │ booking_id   │◄────────────────►│ cancel_id       │      │
│   │ seat_number  │ N:1               │ booking_id (FK) │      │
│   │ seat_type    │                   │ reason          │      │
│   │ price_seat   │                   │ status          │      │
│   │ booked_at    │                   │ refund_amt      │      │
│   └──────────────┘                   └─────────────────┘      │
│     │                                                           │
│     │ 1:N                                                       │
│     ▼                                                           │
│   PAYMENT                            PAYMENT_REFUND           │
│   ┌─────────────┐                    ┌──────────────────┐     │
│   │ tx_id       │◄───────────────────│ refund_id        │     │
│   │ booking_id  │ 1:N                │ payment_id (FK)  │     │
│   │ amount      │                    │ refund_amt       │     │
│   │ method      │                    │ refund_reason    │     │
│   │ status      │                    │ status           │     │
│   │ payment_dt  │                    │ refund_dt        │     │
│   └─────────────┘                    └──────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 4: Pricing & Promotions

```
┌─────────────────────────────────────────────────────────────────┐
│              PRICING & PROMOTIONAL ENGINE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   MOVIE (1)                                                     │
│     │                                                           │
│     │ has (1:N)                                               │
│     ▼                                                           │
│   MOVIE_PRICING                      PRICING_TIER             │
│   ┌──────────────┐                   ┌─────────────┐          │
│   │ pricing_id   │                   │ tier_id     │          │
│   │ movie_title  │                   │ tier_name   │          │
│   │ std_price    │                   │ discount%   │          │
│   │ prem_price   │                   │ min_booking │          │
│   │ weekend_mult │                   │ is_active   │          │
│   │ holiday_mult │                   └─────────────┘          │
│   │ eff_from     │                                             │
│   │ eff_to       │                                             │
│   └──────────────┘                                             │
│                                                                 │
│              ┌──────────────────┐                              │
│              │   PROMO_CODE     │                              │
│              ├──────────────────┤                              │
│              │ code_id          │                              │
│              │ promo_code       │                              │
│              │ discount_type    │                              │
│              │ discount_value   │                              │
│              │ max_uses         │                              │
│              │ current_uses     │                              │
│              │ valid_from       │                              │
│              │ valid_to         │                              │
│              │ min_booking_amt  │                              │
│              │ is_active        │                              │
│              └──────────────────┘                              │
│                                                                 │
│              REFUND_POLICY                                     │
│              ┌──────────────────┐                              │
│              │ policy_id        │                              │
│              │ policy_name      │                              │
│              │ days_before_show │                              │
│              │ refund%          │                              │
│              │ applicable_for   │                              │
│              │ is_active        │                              │
│              └──────────────────┘                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 5: Analytics & Reporting

```
┌─────────────────────────────────────────────────────────────────┐
│           ANALYTICS & BUSINESS INTELLIGENCE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────────┐    ┌──────────────────────┐         │
│   │DAILY_REVENUE_SUMMARY │    │  MOVIE_ANALYTICS    │         │
│   ├──────────────────────┤    ├──────────────────────┤         │
│   │ summary_date (PK)    │    │ analytics_id (PK)   │         │
│   │ total_bookings       │    │ movie_title (FK)    │         │
│   │ total_revenue        │    │ analytics_date      │         │
│   │ total_refunds        │    │ total_shows         │         │
│   │ net_revenue          │    │ total_seats_booked  │         │
│   │ avg_ticket_price     │    │ occupancy%          │         │
│   │ occupancy_rate       │    │ revenue_generated   │         │
│   │ last_updated         │    │ avg_revenue_per_show│         │
│   └──────────────────────┘    └──────────────────────┘         │
│                                                                  │
│   ┌──────────────────────┐    ┌──────────────────────┐         │
│   │ CINEMA_ANALYTICS     │    │USER_BOOKING_STATS   │         │
│   ├──────────────────────┤    ├──────────────────────┤         │
│   │ analytics_id (PK)    │    │ stat_id (PK)        │         │
│   │ cinema_name (FK)     │    │ user_email (FK)     │         │
│   │ analytics_date       │    │ total_bookings      │         │
│   │ total_shows          │    │ total_spent         │         │
│   │ total_bookings       │    │ avg_booking_value   │         │
│   │ total_revenue        │    │ favorite_genre      │         │
│   │ occupancy_rate       │    │ last_booking_date   │         │
│   │ avg_booking_value    │    │ member_since        │         │
│   └──────────────────────┘    │ tier_status         │         │
│                                └──────────────────────┘         │
│                                                                  │
│   ┌──────────────────────┐                                      │
│   │USER_PREFERENCES      │                                      │
│   ├──────────────────────┤                                      │
│   │ preference_id (PK)   │                                      │
│   │ user_email (FK)      │                                      │
│   │ preferred_genre      │                                      │
│   │ preferred_cinema     │                                      │
│   │ seat_preference      │                                      │
│   │ notification_email   │                                      │
│   │ notification_sms     │                                      │
│   └──────────────────────┘                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 6: Audit & Security

```
┌─────────────────────────────────────────────────────────────────┐
│              AUDIT & SECURITY TRACKING                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────────┐    ┌──────────────────────┐         │
│   │   AUDIT_LOG          │    │USER_ACTIVITY_LOG    │         │
│   ├──────────────────────┤    ├──────────────────────┤         │
│   │ audit_id (PK)        │    │ activity_id (PK)    │         │
│   │ table_name           │    │ user_email (FK)     │         │
│   │ operation            │    │ activity_type       │         │
│   │ record_id            │    │ activity_desc       │         │
│   │ old_values (JSONB)   │    │ ip_address          │         │
│   │ new_values (JSONB)   │    │ user_agent          │         │
│   │ changed_by           │    │ activity_timestamp  │         │
│   │ changed_at           │    │ status              │         │
│   │ ip_address           │    └──────────────────────┘         │
│   └──────────────────────┘                                      │
│                                                                  │
│   ┌──────────────────���───┐    ┌──────────────────────┐         │
│   │   USER_ROLE          │    │ USER_ROLE_MAPPING   │         │
│   ├──────────────────────┤    ├──────────────────────┤         │
│   │ role_id (PK)         │    │ mapping_id (PK)     │         │
│   │ role_name            │    │ user_email (FK)     │         │
│   │ description          │    │ role_id (FK)        │         │
│   │ created_at           │    │ assigned_at         │         │
│   └──────────────────────┘    │ assigned_by         │         │
│                                └──────────────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Complete Table Reference

### Users & Administration

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `users` | user_email, name, phone_number, password, created_at, updated_at | User registration | 1:N with booking, user_preferences, user_activity_log |
| `admin` | admin_email, name, phone_number, password, created_at | Admin management | 1:N with cinema |
| `user_role` | role_id, role_name, description | Role definitions | 1:N with user_role_mapping |
| `user_role_mapping` | mapping_id, user_email, role_id | User-role assignment | N:1 with user_role |

### Cinema Infrastructure

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `city` | city_name | City reference | 1:N with cinema |
| `cinema` | cinema_name, cinema_area, admin_email, cinema_city, cinema_pincode, total_screens, created_at | Cinema information | 1:N with screen; N:1 with admin, city |
| `screen` | screen_id, cinema_name, cinema_pincode, capacity | Screen details | N:1 with cinema; 1:N with seat, showtime |
| `seat` | seat_id, screen_id, seat_row, seat_number, seat_type, is_available | Seat inventory | N:1 with screen; 1:N with showtime_seat_availability |
| `showtime` | showtime_id, movie_title, is_active, screen_id, show_date, start_time, end_time, created_at | Show scheduling | N:1 with movie, screen; 1:N with booking, showtime_seat_availability |

### Booking System

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `booking` | booking_id, user_email, showtime_id, is_deleted, booking_date, booking_status, total_amount, cancellation_date, cancellation_reason, created_at | Ticket reservations | N:1 with users, showtime; 1:N with booking_seat, payment, cancellation_request |
| `booking_seat` | booking_id, seat_number, seat_type, price_per_seat, booked_at | Seat-level booking | N:1 with booking, seat |
| `showtime_seat_availability` | availability_id, showtime_id, seat_id, is_booked, booked_at, booked_by | Real-time availability | N:1 with showtime, seat, users |
| `booking_status_history` | status_history_id, booking_id, previous_status, new_status, status_changed_at, changed_by, reason | Booking lifecycle | N:1 with booking |

### Payment & Refunds

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `payment` | transaction_id, amount, booking_id, is_refunded, user_email, payment_method, payment_status, payment_date, refund_date, gateway_transaction_id | Payment records | N:1 with booking, users; 1:N with payment_refund |
| `payment_refund` | refund_id, payment_id, refund_amount, refund_reason, refund_status, refund_date, processed_at, processed_by | Refund tracking | N:1 with payment |
| `cancellation_request` | cancellation_id, booking_id, requested_by, requested_at, cancellation_reason, refund_amount, cancellation_status, approved_by, approved_at | Cancellation workflow | N:1 with booking, users |

### Pricing & Promotions

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `pricing_tier` | tier_id, tier_name, discount_percentage, min_booking_count, description, is_active, created_at | Discount tiers | Supports pricing strategy |
| `movie_pricing` | pricing_id, movie_title, standard_price, premium_price, weekend_multiplier, holiday_multiplier, effective_from, effective_to | Dynamic pricing | N:1 with movie |
| `promo_code` | code_id, promo_code, discount_type, discount_value, max_uses, current_uses, valid_from, valid_to, min_booking_amount, is_active, created_by | Promotional codes | Booking validation |
| `refund_policy` | policy_id, policy_name, days_before_show, refund_percentage, applicable_for, is_active, created_at | Refund rules | Cancellation logic |

### Analytics & Reporting

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `daily_revenue_summary` | summary_date, total_bookings, total_revenue, total_refunds, net_revenue, avg_ticket_price, occupancy_rate, last_updated | Daily metrics | Reporting |
| `movie_analytics` | analytics_id, movie_title, analytics_date, total_shows, total_seats_available, total_seats_booked, occupancy_percentage, revenue_generated, avg_revenue_per_show | Movie performance | N:1 with movie |
| `cinema_analytics` | analytics_id, cinema_name, cinema_pincode, analytics_date, total_shows, total_bookings, total_revenue, occupancy_rate, avg_booking_value, last_updated | Cinema performance | N:1 with cinema |
| `user_booking_stats` | stat_id, user_email, total_bookings, total_amount_spent, avg_booking_value, favorite_genre, last_booking_date, member_since, tier_status | Customer metrics | N:1 with users |
| `user_preferences` | preference_id, user_email, preferred_genre, preferred_cinema_name, preferred_cinema_pincode, seat_preference, notification_email, notification_sms, language_preference, dark_mode, created_at, updated_at | User preferences | N:1 with users |

### Audit & Security

| Table | Columns | Purpose | Relationships |
|-------|---------|---------|----------------|
| `audit_log` | audit_id, table_name, operation, record_id, old_values, new_values, changed_by, changed_at, ip_address | Change tracking | Compliance |
| `user_activity_log` | activity_id, user_email, activity_type, activity_description, ip_address, user_agent, activity_timestamp, status | Activity tracking | N:1 with users |

---

## 🔑 Key Relationships

### One-to-Many (1:N) Relationships

```
USERS
  ├─► 1:N BOOKING (A user can have many bookings)
  ├─► 1:N USER_PREFERENCES (One preference per user)
  ├─► 1:N USER_ACTIVITY_LOG (Multiple activity logs)
  └─► 1:N BOOKING_SEAT (Through booking)

MOVIE
  ├─► 1:N SHOWTIME (A movie can have many shows)
  ├─► 1:N MOVIE_PRICING (Multiple pricing records over time)
  └─► 1:N MOVIE_ANALYTICS (Daily analytics per movie)

CINEMA
  ├─► 1:N SCREEN (A cinema has multiple screens)
  ├─► 1:N CINEMA_ANALYTICS (Daily analytics)
  └─► 1:N BOOKING_STATUS_HISTORY (Via showtime)

SCREEN
  ├─► 1:N SEAT (A screen has many seats)
  ├─► 1:N SHOWTIME (A screen shows multiple movies)
  └─► 1:N SHOWTIME_SEAT_AVAILABILITY (Per showtime)

SHOWTIME
  ├─► 1:N BOOKING (Multiple bookings per show)
  ├─► 1:N SHOWTIME_SEAT_AVAILABILITY (All seats in show)
  └─► 1:N BOOKING_STATUS_HISTORY (Status changes)

BOOKING
  ├─► 1:N BOOKING_SEAT (Multiple seats per booking)
  ├─► 1:N PAYMENT (One or more payments)
  ├─► 1:N CANCELLATION_REQUEST (Multiple requests)
  └─► 1:N BOOKING_STATUS_HISTORY (Status tracking)

PAYMENT
  └─► 1:N PAYMENT_REFUND (Multiple refund records)
```

### Many-to-One (N:1) Relationships

```
BOOKING ──N:1──► USERS
BOOKING ──N:1──► SHOWTIME
BOOKING_SEAT ──N:1──► BOOKING
BOOKING_SEAT ──N:1──► SEAT
BOOKING_STATUS_HISTORY ──N:1──► BOOKING
CANCELLATION_REQUEST ──N:1──► BOOKING
PAYMENT ──N:1──► BOOKING
PAYMENT ──N:1──► USERS
PAYMENT_REFUND ──N:1──► PAYMENT
SHOWTIME ──N:1──► MOVIE
SHOWTIME ──N:1──► SCREEN
SHOWTIME_SEAT_AVAILABILITY ──N:1──► SHOWTIME
SHOWTIME_SEAT_AVAILABILITY ──N:1──► SEAT
SHOWTIME_SEAT_AVAILABILITY ──N:1──► USERS
SEAT ──N:1──► SCREEN
SCREEN ──N:1──► CINEMA
CINEMA ──N:1──► ADMIN
CINEMA ──N:1──► CITY
MOVIE_PRICING ──N:1──► MOVIE
MOVIE_ANALYTICS ──N:1──► MOVIE
CINEMA_ANALYTICS ──N:1──► CINEMA
USER_BOOKING_STATS ──N:1──► USERS
USER_PREFERENCES ──N:1──► USERS
USER_ACTIVITY_LOG ──N:1──► USERS
USER_ROLE_MAPPING ──N:1──► USER_ROLE
```

---

## 🎯 Cardinality Rules

### Critical Business Rules

1. **One User → Many Bookings** ✅
   - A user can book multiple shows
   - Booking = User + Showtime + Seats

2. **One Showtime → Many Seats** ✅
   - Each showtime has all cinema seats
   - Seat availability tracked per showtime

3. **One Booking → Many Seats** ✅
   - Booking_seat junction table
   - Tracks individual seat details

4. **One Booking → One Payment** ✅
   - One transaction per booking
   - Can have refunds later

5. **One Payment → Many Refunds** ✅
   - Partial refunds supported
   - Full refund history maintained

6. **One Cinema → Many Admins** ⚠️
   - Current: One admin per cinema (UNIQUE constraint)
   - Can be modified for multiple admins

7. **One Screen → One Layout** ✅
   - Seats defined per screen
   - No dynamic layout changes

---

## 📐 Normalization Analysis

### Normalization Levels Achieved

✅ **1NF (First Normal Form)**
- Atomic values only
- No repeating groups
- All attributes functional

✅ **2NF (Second Normal Form)**
- Meets 1NF requirements
- All non-key attributes depend on primary key
- No partial dependencies

✅ **3NF (Third Normal Form)**
- Meets 2NF requirements
- Non-key attributes don't depend on other non-key attributes
- Transitive dependencies removed

✅ **BCNF (Boyce-Codd Normal Form)**
- Every determinant is a candidate key
- All anomalies eliminated
- No redundancy

### Example: Booking Table

```
❌ NOT NORMALIZED:
booking_id | user_email | movie_title | cinema_name | seat_1 | seat_2 | seat_3

✅ NORMALIZED TO BCNF:
booking_id | user_email | showtime_id | total_amount

booking_seat:
booking_id | seat_number | seat_type | price_per_seat
```

---

## 🔗 Foreign Key Constraints

### All Foreign Keys with Actions

```
BOOKING:
  - FK: user_email → USERS (ON DELETE CASCADE)
  - FK: showtime_id → SHOWTIME (ON DELETE CASCADE)

BOOKING_SEAT:
  - FK: booking_id → BOOKING (ON DELETE CASCADE)
  - FK: seat_number → SEAT (relationship)

BOOKING_STATUS_HISTORY:
  - FK: booking_id → BOOKING (ON DELETE CASCADE)

PAYMENT:
  - FK: booking_id → BOOKING (ON DELETE CASCADE)
  - FK: user_email → USERS (ON DELETE CASCADE)

PAYMENT_REFUND:
  - FK: payment_id → PAYMENT (ON DELETE CASCADE)

CANCELLATION_REQUEST:
  - FK: booking_id → BOOKING (ON DELETE CASCADE)
  - FK: requested_by → USERS (ON DELETE RESTRICT)

SHOWTIME:
  - FK: movie_title → MOVIE (ON DELETE CASCADE)
  - FK: screen_id → SCREEN (ON DELETE CASCADE)

SHOWTIME_SEAT_AVAILABILITY:
  - FK: showtime_id → SHOWTIME (ON DELETE CASCADE)
  - FK: seat_id → SEAT (ON DELETE CASCADE)
  - FK: booked_by → USERS (ON DELETE RESTRICT)

SCREEN:
  - FK: (cinema_name, cinema_pincode) → CINEMA (ON DELETE CASCADE)

SEAT:
  - FK: screen_id → SCREEN (ON DELETE CASCADE)

CINEMA:
  - FK: admin_email → ADMIN (ON DELETE CASCADE)
  - FK: cinema_city → CITY (ON DELETE CASCADE)

MOVIE_PRICING:
  - FK: movie_title → MOVIE (ON DELETE CASCADE)

MOVIE_ANALYTICS:
  - FK: movie_title → MOVIE (ON DELETE CASCADE)

CINEMA_ANALYTICS:
  - FK: (cinema_name, cinema_pincode) → CINEMA (ON DELETE CASCADE)

USER_BOOKING_STATS:
  - FK: user_email → USERS (ON DELETE CASCADE)

USER_PREFERENCES:
  - FK: user_email → USERS (ON DELETE CASCADE)

USER_ACTIVITY_LOG:
  - FK: user_email → USERS (ON DELETE CASCADE)

USER_ROLE_MAPPING:
  - FK: role_id → USER_ROLE (ON DELETE CASCADE)
```

---

## 🎨 Schema Design Patterns Used

### 1. **Type Table Pattern**
```
user_role table for role definitions
pricing_tier table for discount levels
```

### 2. **History/Audit Pattern**
```
booking_status_history tracks state changes
audit_log tracks all modifications
user_activity_log tracks user actions
```

### 3. **Junction Table Pattern**
```
booking_seat links bookings to seats
user_role_mapping links users to roles
showtime_seat_availability links shows to seats
```

### 4. **Time-Series Pattern**
```
daily_revenue_summary for daily metrics
movie_analytics for movie performance
cinema_analytics for venue metrics
```

### 5. **Slowly Changing Dimension (SCD)**
```
movie_pricing tracks price changes over time
refund_policy versions for historical analysis
```

### 6. **Soft Delete Pattern**
```
booking.is_deleted for non-destructive deletes
user_preferences for personalization preservation
```

---

## 📊 Index Strategy

### Primary Key Indexes (Automatic)
```
All tables have PRIMARY KEY indexes on:
- booking_id (booking)
- transaction_id (payment)
- seat_id (seat)
- screen_id (screen)
- showtime_id (showtime)
- etc.
```

### Foreign Key Indexes
```
CREATE INDEX idx_booking_user ON booking(user_email);
CREATE INDEX idx_booking_showtime ON booking(showtime_id);
CREATE INDEX idx_payment_booking ON payment(booking_id);
CREATE INDEX idx_cinema_city ON cinema(cinema_city);
```

### Query Performance Indexes
```
CREATE INDEX idx_booking_date ON booking(booking_date DESC);
CREATE INDEX idx_showtime_availability ON showtime_seat_availability(showtime_id, is_booked);
CREATE INDEX idx_activity_user_date ON user_activity_log(user_email, activity_timestamp DESC);
```

---

## 🚀 Performance Considerations

### Query Optimization Tips

1. **Seat Availability** ⚡
   - Use `showtime_seat_availability` for real-time queries
   - Filter by `is_booked = FALSE` with index

2. **Revenue Reports** 📊
   - Use materialized views (`daily_revenue_summary`)
   - Refresh daily for reporting

3. **User Analysis** 👥
   - Use `user_booking_stats` for CLV calculations
   - Join with `user_preferences` for recommendations

4. **Movie Performance** 🎬
   - Query `movie_analytics` instead of raw bookings
   - Use window functions for ranking

---

## 📝 Migration Path

### From v1.0 to v2.0 (Enterprise)

```sql
-- Added Tables
✅ showtime_seat_availability (real-time tracking)
✅ booking_status_history (lifecycle tracking)
✅ movie_pricing (dynamic pricing)
✅ pricing_tier (customer tiers)
✅ promo_code (promotions)
✅ refund_policy (cancellation policy)
✅ payment_refund (refund tracking)
✅ cancellation_request (cancellation workflow)
✅ daily_revenue_summary (analytics)
✅ movie_analytics (movie metrics)
✅ cinema_analytics (venue metrics)
✅ user_booking_stats (customer metrics)
✅ user_preferences (personalization)
✅ audit_log (compliance)
✅ user_activity_log (activity tracking)
✅ user_role (access control)
✅ user_role_mapping (role assignment)

-- Added Columns
✅ booking_status, total_amount, cancellation_date
✅ payment_method, payment_status, payment_date
✅ seat.seat_type (STANDARD, PREMIUM, etc.)
✅ timestamps on all tables
```

---

## 🎓 Learning from This Schema

### Key Takeaways

1. **Proper Normalization** - Eliminates data redundancy
2. **Referential Integrity** - Foreign keys maintain consistency
3. **Temporal Tracking** - History tables for audit trails
4. **Performance Design** - Strategic denormalization in views
5. **Scalability** - Partitioning-ready design
6. **Security** - Audit logs and role-based access
7. **Analytics** - Pre-calculated summary tables
8. **Business Logic** - Stored procedures for complex operations

---

## 📞 Support & Questions

For detailed explanations of specific queries or relationships, refer to:
- `DATABASE_GUIDE.sql` - Comprehensive documentation
- `SQL_INTERVIEW_CHEAT_SHEET.sql` - Query examples
- `04_analytics_queries.sql` - Complex reporting queries

---

**Last Updated**: June 16, 2026  
**Schema Version**: 2.0 Enterprise  
**Status**: Production Ready ✅
