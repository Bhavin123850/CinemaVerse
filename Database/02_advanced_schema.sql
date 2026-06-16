-- ============================================================================
-- CINEMAVERSE: ADVANCED ENTERPRISE DATABASE SCHEMA
-- Purpose: Production-ready schema with auditing, analytics, and optimization
-- ============================================================================

SET search_path TO cinema_ticket_booking;

-- ============================================================================
-- 1. AUDIT & LOGGING TABLES
-- ============================================================================

-- Comprehensive audit log for compliance and troubleshooting
CREATE TABLE IF NOT EXISTS audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id VARCHAR(255),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(250),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    INDEX audit_table_op_idx (table_name, operation, changed_at),
    INDEX audit_user_idx (changed_by, changed_at)
);

-- User activity tracking for security and analytics
CREATE TABLE IF NOT EXISTS user_activity_log (
    activity_id BIGSERIAL PRIMARY KEY,
    user_email VARCHAR(250) NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT,
    ip_address INET,
    user_agent TEXT,
    activity_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'SUCCESS',
    FOREIGN KEY (user_email) REFERENCES users(user_email) ON DELETE CASCADE
);

-- ============================================================================
-- 2. SEAT MANAGEMENT TABLES (CORRECTS MISSING SEATS CONCEPT)
-- ============================================================================

-- Define screen layout with seat details
CREATE TABLE IF NOT EXISTS seat (
    seat_id SERIAL PRIMARY KEY,
    screen_id INT NOT NULL,
    seat_row CHAR(1) NOT NULL CHECK (seat_row ~ '^[A-Z]$'),
    seat_number INT NOT NULL CHECK (seat_number > 0),
    seat_type VARCHAR(20) DEFAULT 'STANDARD' CHECK (seat_type IN ('STANDARD', 'PREMIUM', 'WHEELCHAIR', 'COUPLE')),
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (screen_id) REFERENCES screen(screen_id) ON DELETE CASCADE,
    UNIQUE(screen_id, seat_row, seat_number)
);

-- Track seat availability per showtime
CREATE TABLE IF NOT EXISTS showtime_seat_availability (
    availability_id SERIAL PRIMARY KEY,
    showtime_id INT NOT NULL,
    seat_id INT NOT NULL,
    is_booked BOOLEAN DEFAULT FALSE,
    booked_at TIMESTAMP,
    booked_by VARCHAR(250),
    FOREIGN KEY (showtime_id) REFERENCES showtime(showtime_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id) REFERENCES seat(seat_id) ON DELETE CASCADE,
    FOREIGN KEY (booked_by) REFERENCES users(user_email),
    UNIQUE(showtime_id, seat_id)
);

-- ============================================================================
-- 3. PRICING & DISCOUNT MANAGEMENT
-- ============================================================================

-- Dynamic pricing based on multiple factors
CREATE TABLE IF NOT EXISTS pricing_tier (
    tier_id SERIAL PRIMARY KEY,
    tier_name VARCHAR(50) UNIQUE NOT NULL,
    discount_percentage DECIMAL(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    min_booking_count INT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Movie-specific pricing
CREATE TABLE IF NOT EXISTS movie_pricing (
    pricing_id SERIAL PRIMARY KEY,
    movie_title VARCHAR(255) NOT NULL,
    standard_price DECIMAL(10, 2) NOT NULL CHECK (standard_price > 0),
    premium_price DECIMAL(10, 2) NOT NULL CHECK (premium_price > 0),
    weekend_multiplier DECIMAL(3, 2) DEFAULT 1.0 CHECK (weekend_multiplier >= 1.0),
    holiday_multiplier DECIMAL(3, 2) DEFAULT 1.0 CHECK (holiday_multiplier >= 1.0),
    effective_from DATE NOT NULL,
    effective_to DATE,
    FOREIGN KEY (movie_title) REFERENCES movie(movie_title) ON DELETE CASCADE,
    CHECK (effective_to IS NULL OR effective_to > effective_from)
);

-- Discount and promotional codes
CREATE TABLE IF NOT EXISTS promo_code (
    code_id SERIAL PRIMARY KEY,
    promo_code VARCHAR(50) UNIQUE NOT NULL,
    discount_type VARCHAR(20) CHECK (discount_type IN ('PERCENTAGE', 'FIXED')),
    discount_value DECIMAL(10, 2) NOT NULL CHECK (discount_value > 0),
    max_uses INT,
    current_uses INT DEFAULT 0,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    min_booking_amount DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(250),
    CHECK (valid_to > valid_from)
);

-- ============================================================================
-- 4. SHOW & BOOKING ENHANCEMENTS
-- ============================================================================

-- Enhanced booking status tracking
CREATE TABLE IF NOT EXISTS booking_status_history (
    status_history_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    previous_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL CHECK (new_status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'REFUNDED', 'EXPIRED')),
    status_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(250),
    reason TEXT,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE
);

-- Seat details in booking
ALTER TABLE booking_seat ADD COLUMN seat_type VARCHAR(20) DEFAULT 'STANDARD';
ALTER TABLE booking_seat ADD COLUMN price_per_seat DECIMAL(10, 2);
ALTER TABLE booking_seat ADD COLUMN booked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- ============================================================================
-- 5. PAYMENT ENHANCEMENTS
-- ============================================================================

ALTER TABLE payment ADD COLUMN payment_method VARCHAR(50) NOT NULL DEFAULT 'CREDIT_CARD' 
    CHECK (payment_method IN ('CREDIT_CARD', 'DEBIT_CARD', 'UPI', 'NET_BANKING', 'WALLET'));
ALTER TABLE payment ADD COLUMN payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (payment_status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'));
ALTER TABLE payment ADD COLUMN payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE payment ADD COLUMN refund_date TIMESTAMP;
ALTER TABLE payment ADD COLUMN gateway_transaction_id VARCHAR(255) UNIQUE;

-- Payment refund tracking
CREATE TABLE IF NOT EXISTS payment_refund (
    refund_id SERIAL PRIMARY KEY,
    payment_id INT NOT NULL,
    refund_amount DECIMAL(10, 2) NOT NULL CHECK (refund_amount > 0),
    refund_reason VARCHAR(200),
    refund_status VARCHAR(20) DEFAULT 'PENDING' CHECK (refund_status IN ('PENDING', 'PROCESSED', 'FAILED', 'REJECTED')),
    refund_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    processed_by VARCHAR(250),
    FOREIGN KEY (payment_id) REFERENCES payment(transaction_id) ON DELETE CASCADE
);

-- ============================================================================
-- 6. CANCELLATION & REFUND POLICY
-- ============================================================================

CREATE TABLE IF NOT EXISTS refund_policy (
    policy_id SERIAL PRIMARY KEY,
    policy_name VARCHAR(100) UNIQUE NOT NULL,
    days_before_show INT NOT NULL,
    refund_percentage DECIMAL(5, 2) NOT NULL CHECK (refund_percentage >= 0 AND refund_percentage <= 100),
    applicable_for VARCHAR(50) DEFAULT 'ALL',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User cancellation requests
CREATE TABLE IF NOT EXISTS cancellation_request (
    cancellation_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    requested_by VARCHAR(250) NOT NULL,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancellation_reason TEXT,
    refund_amount DECIMAL(10, 2),
    cancellation_status VARCHAR(20) DEFAULT 'PENDING' CHECK (cancellation_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    approved_by VARCHAR(250),
    approved_at TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by) REFERENCES users(user_email)
);

-- ============================================================================
-- 7. ANALYTICS & REPORTING TABLES
-- ============================================================================

-- Daily revenue summary (materialized view data)
CREATE TABLE IF NOT EXISTS daily_revenue_summary (
    summary_date DATE PRIMARY KEY,
    total_bookings INT DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0,
    total_refunds DECIMAL(15, 2) DEFAULT 0,
    net_revenue DECIMAL(15, 2) DEFAULT 0,
    avg_ticket_price DECIMAL(10, 2),
    occupancy_rate DECIMAL(5, 2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Movie performance analytics
CREATE TABLE IF NOT EXISTS movie_analytics (
    analytics_id SERIAL PRIMARY KEY,
    movie_title VARCHAR(255) NOT NULL,
    analytics_date DATE NOT NULL,
    total_shows INT DEFAULT 0,
    total_seats_available INT DEFAULT 0,
    total_seats_booked INT DEFAULT 0,
    occupancy_percentage DECIMAL(5, 2),
    revenue_generated DECIMAL(15, 2) DEFAULT 0,
    avg_revenue_per_show DECIMAL(10, 2),
    FOREIGN KEY (movie_title) REFERENCES movie(movie_title) ON DELETE CASCADE,
    UNIQUE(movie_title, analytics_date)
);

-- Cinema performance metrics
CREATE TABLE IF NOT EXISTS cinema_analytics (
    analytics_id SERIAL PRIMARY KEY,
    cinema_name VARCHAR(255) NOT NULL,
    cinema_pincode VARCHAR(6) NOT NULL,
    analytics_date DATE NOT NULL,
    total_shows INT DEFAULT 0,
    total_bookings INT DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0,
    occupancy_rate DECIMAL(5, 2),
    avg_booking_value DECIMAL(10, 2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cinema_name, cinema_pincode) REFERENCES cinema(cinema_name, cinema_pincode) ON DELETE CASCADE,
    UNIQUE(cinema_name, cinema_pincode, analytics_date)
);

-- ============================================================================
-- 8. USER PREFERENCES & PERSONALIZATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_preferences (
    preference_id SERIAL PRIMARY KEY,
    user_email VARCHAR(250) NOT NULL UNIQUE,
    preferred_genre VARCHAR(50),
    preferred_cinema_name VARCHAR(255),
    preferred_cinema_pincode VARCHAR(6),
    seat_preference VARCHAR(50),
    notification_email BOOLEAN DEFAULT TRUE,
    notification_sms BOOLEAN DEFAULT TRUE,
    language_preference VARCHAR(20) DEFAULT 'EN',
    dark_mode BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_email) REFERENCES users(user_email) ON DELETE CASCADE
);

-- User booking history view (for analytics)
CREATE TABLE IF NOT EXISTS user_booking_stats (
    stat_id SERIAL PRIMARY KEY,
    user_email VARCHAR(250) NOT NULL UNIQUE,
    total_bookings INT DEFAULT 0,
    total_amount_spent DECIMAL(15, 2) DEFAULT 0,
    avg_booking_value DECIMAL(10, 2),
    favorite_genre VARCHAR(50),
    last_booking_date DATE,
    member_since DATE,
    tier_status VARCHAR(50) DEFAULT 'REGULAR',
    FOREIGN KEY (user_email) REFERENCES users(user_email) ON DELETE CASCADE
);

-- ============================================================================
-- 9. OPTIMIZED INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(user_email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Movies
CREATE INDEX IF NOT EXISTS idx_movie_title ON movie(movie_title);
CREATE INDEX IF NOT EXISTS idx_movie_genre_release ON movie(genre, release_date DESC);

-- Cinema
CREATE INDEX IF NOT EXISTS idx_cinema_city ON cinema(cinema_city);
CREATE INDEX IF NOT EXISTS idx_cinema_admin ON cinema(admin_email);

-- Showtime
CREATE INDEX IF NOT EXISTS idx_showtime_date ON showtime(show_date);
CREATE INDEX IF NOT EXISTS idx_showtime_movie_date ON showtime(movie_title, show_date);
CREATE INDEX IF NOT EXISTS idx_showtime_screen ON showtime(screen_id);
CREATE INDEX IF NOT EXISTS idx_showtime_active ON showtime(is_active, show_date);

-- Booking
CREATE INDEX IF NOT EXISTS idx_booking_user ON booking(user_email);
CREATE INDEX IF NOT EXISTS idx_booking_showtime ON booking(showtime_id);
CREATE INDEX IF NOT EXISTS idx_booking_date ON booking(booking_date DESC);
CREATE INDEX IF NOT EXISTS idx_booking_not_deleted ON booking(is_deleted, booking_date);

-- Seat Availability
CREATE INDEX IF NOT EXISTS idx_seat_availability_showtime ON showtime_seat_availability(showtime_id);
CREATE INDEX IF NOT EXISTS idx_seat_availability_booked ON showtime_seat_availability(is_booked);

-- Payment
CREATE INDEX IF NOT EXISTS idx_payment_booking ON payment(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_user ON payment(user_email);
CREATE INDEX IF NOT EXISTS idx_payment_status_date ON payment(payment_status, payment_date DESC);

-- Audit
CREATE INDEX IF NOT EXISTS idx_audit_table ON audit_log(table_name, changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(changed_by, changed_at DESC);

-- Activity Log
CREATE INDEX IF NOT EXISTS idx_activity_user_date ON user_activity_log(user_email, activity_timestamp DESC);

-- ============================================================================
-- 10. CONSTRAINTS & DATA INTEGRITY
-- ============================================================================

-- Add timestamps to main tables
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE admin ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE movie ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE movie ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE cinema ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE showtime ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Add default booking status
ALTER TABLE booking ADD COLUMN IF NOT EXISTS booking_status VARCHAR(30) DEFAULT 'CONFIRMED' 
    CHECK (booking_status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'REFUNDED', 'EXPIRED'));
ALTER TABLE booking ADD COLUMN IF NOT EXISTS total_amount DECIMAL(15, 2);
ALTER TABLE booking ADD COLUMN IF NOT EXISTS cancellation_date TIMESTAMP;
ALTER TABLE booking ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- ============================================================================
-- PERMISSIONS & USER ROLES (for access control)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL CHECK (role_name IN ('ADMIN', 'SUPER_ADMIN', 'USER', 'SUPPORT_STAFF')),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_role_mapping (
    mapping_id SERIAL PRIMARY KEY,
    user_email VARCHAR(250) NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by VARCHAR(250),
    UNIQUE(user_email, role_id),
    FOREIGN KEY (role_id) REFERENCES user_role(role_id)
);

-- Insert default roles
INSERT INTO user_role (role_name, description) VALUES
    ('ADMIN', 'Cinema admin with full access'),
    ('SUPER_ADMIN', 'Super admin with system-wide access'),
    ('USER', 'Regular user'),
    ('SUPPORT_STAFF', 'Support team member')
ON CONFLICT (role_name) DO NOTHING;

-- ============================================================================
-- 11. QUERY PERFORMANCE STATISTICS (Optional for monitoring)
-- ============================================================================

CREATE TABLE IF NOT EXISTS query_performance_log (
    log_id SERIAL PRIMARY KEY,
    query_text TEXT,
    execution_time_ms DECIMAL(10, 2),
    rows_affected INT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20)
);

COMMIT;
