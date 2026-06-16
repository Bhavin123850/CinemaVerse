-- ============================================================================
-- CINEMAVERSE: SAMPLE DATA FOR TESTING & DEMONSTRATION
-- Purpose: Realistic test data to showcase all features
-- ============================================================================

SET search_path TO cinema_ticket_booking;

-- ============================================================================
-- 1. INSERT CITIES
-- ============================================================================

INSERT INTO city (city_name) VALUES 
    ('Mumbai'),
    ('Delhi'),
    ('Bangalore'),
    ('Hyderabad'),
    ('Pune'),
    ('Kolkata'),
    ('Chennai'),
    ('Ahmedabad')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. INSERT USERS
-- ============================================================================

INSERT INTO users (user_email, name, phone_number, password, created_at) VALUES
    ('john.doe@email.com', 'John Doe', '9876543210', 'SecurePass123@', CURRENT_TIMESTAMP - INTERVAL '90 days'),
    ('jane.smith@email.com', 'Jane Smith', '9876543211', 'Password456@', CURRENT_TIMESTAMP - INTERVAL '60 days'),
    ('mike.johnson@email.com', 'Mike Johnson', '9876543212', 'MyPass789@', CURRENT_TIMESTAMP - INTERVAL '45 days'),
    ('sarah.williams@email.com', 'Sarah Williams', '9876543213', 'Sarah@123Pass', CURRENT_TIMESTAMP - INTERVAL '30 days'),
    ('alex.brown@email.com', 'Alex Brown', '9876543214', 'Brown@Pass123', CURRENT_TIMESTAMP - INTERVAL '15 days'),
    ('emma.davis@email.com', 'Emma Davis', '9876543215', 'Emma@2024Pass', CURRENT_TIMESTAMP - INTERVAL '7 days'),
    ('david.miller@email.com', 'David Miller', '9876543216', 'David@Secure123', CURRENT_TIMESTAMP - INTERVAL '3 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. INSERT ADMINS
-- ============================================================================

INSERT INTO admin (admin_email, name, phone_number, password, created_at) VALUES
    ('admin.mumbai@cinema.com', 'Mumbai Admin', '9876543220', 'AdminPass123@', CURRENT_TIMESTAMP - INTERVAL '365 days'),
    ('admin.delhi@cinema.com', 'Delhi Admin', '9876543221', 'AdminPass456@', CURRENT_TIMESTAMP - INTERVAL '300 days'),
    ('admin.bangalore@cinema.com', 'Bangalore Admin', '9876543222', 'AdminPass789@', CURRENT_TIMESTAMP - INTERVAL '250 days'),
    ('admin.hyderabad@cinema.com', 'Hyderabad Admin', '9876543223', 'Admin@Pass123', CURRENT_TIMESTAMP - INTERVAL '200 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. INSERT MOVIES
-- ============================================================================

INSERT INTO movie (movie_title, genre, duration, release_date, price, created_at) VALUES
    ('Aamir Khan Adventures', 'Action', 130, CURRENT_DATE - INTERVAL '30 days', 250.00, CURRENT_TIMESTAMP - INTERVAL '30 days'),
    ('Romantic Hearts', 'Drama', 145, CURRENT_DATE - INTERVAL '20 days', 280.00, CURRENT_TIMESTAMP - INTERVAL '20 days'),
    ('Sci-Fi Galaxy', 'Sci-Fi', 150, CURRENT_DATE - INTERVAL '15 days', 300.00, CURRENT_TIMESTAMP - INTERVAL '15 days'),
    ('Comedy Gold', 'Comedy', 120, CURRENT_DATE - INTERVAL '10 days', 220.00, CURRENT_TIMESTAMP - INTERVAL '10 days'),
    ('Horror Night', 'Horror', 115, CURRENT_DATE - INTERVAL '5 days', 240.00, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    ('Documentary World', 'Documentary', 100, CURRENT_DATE - INTERVAL '2 days', 200.00, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    ('Action Blast', 'Action', 140, CURRENT_DATE + INTERVAL '5 days', 280.00, CURRENT_TIMESTAMP - INTERVAL '1 days'),
    ('Family Fun', 'Comedy', 110, CURRENT_DATE + INTERVAL '10 days', 230.00, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. INSERT CINEMAS
-- ============================================================================

INSERT INTO cinema (cinema_name, cinema_area, admin_email, cinema_city, cinema_pincode, total_screens, created_at) VALUES
    ('PVR Mumbai Downtown', 'Downtown', 'admin.mumbai@cinema.com', 'Mumbai', '400001', 5, CURRENT_TIMESTAMP - INTERVAL '365 days'),
    ('INOX Mumbai Central', 'Central', 'admin.mumbai@cinema.com', 'Mumbai', '400002', 4, CURRENT_TIMESTAMP - INTERVAL '350 days'),
    ('IMAX Delhi Premium', 'Connaught Place', 'admin.delhi@cinema.com', 'Delhi', '110001', 3, CURRENT_TIMESTAMP - INTERVAL '300 days'),
    ('Cinepolis Bangalore', 'MG Road', 'admin.bangalore@cinema.com', 'Bangalore', '560001', 6, CURRENT_TIMESTAMP - INTERVAL '250 days'),
    ('AMC Hyderabad', 'Banjara Hills', 'admin.hyderabad@cinema.com', 'Hyderabad', '500034', 4, CURRENT_TIMESTAMP - INTERVAL '200 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. INSERT SCREENS
-- ============================================================================

INSERT INTO screen (screen_id, cinema_name, cinema_pincode, capacity) VALUES
    (1, 'PVR Mumbai Downtown', '400001', 200),
    (2, 'PVR Mumbai Downtown', '400001', 250),
    (3, 'INOX Mumbai Central', '400002', 180),
    (4, 'INOX Mumbai Central', '400002', 220),
    (5, 'IMAX Delhi Premium', '110001', 300),
    (6, 'Cinepolis Bangalore', '560001', 240),
    (7, 'Cinepolis Bangalore', '560001', 200),
    (8, 'AMC Hyderabad', '500034', 220)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. INSERT SEATS
-- ============================================================================

-- Insert seats for Screen 1 (200 capacity)
INSERT INTO seat (screen_id, seat_row, seat_number, seat_type, is_available) 
SELECT 1, chr(64 + row_num), seat_num, 
    CASE 
        WHEN row_num >= 8 THEN 'PREMIUM'
        WHEN row_num >= 1 AND row_num <= 3 THEN 'WHEELCHAIR'
        ELSE 'STANDARD'
    END,
    TRUE
FROM generate_series(1, 10) row_num
CROSS JOIN generate_series(1, 20) seat_num
ON CONFLICT DO NOTHING;

-- Insert seats for Screen 2 (250 capacity)
INSERT INTO seat (screen_id, seat_row, seat_number, seat_type, is_available)
SELECT 2, chr(64 + row_num), seat_num,
    CASE 
        WHEN row_num >= 9 THEN 'COUPLE'
        WHEN row_num >= 1 AND row_num <= 2 THEN 'WHEELCHAIR'
        ELSE 'STANDARD'
    END,
    TRUE
FROM generate_series(1, 12) row_num
CROSS JOIN generate_series(1, 21) seat_num
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. INSERT SHOWTIMES
-- ============================================================================

INSERT INTO showtime (movie_title, is_active, screen_id, show_date, start_time, end_time, created_at) VALUES
    ('Aamir Khan Adventures', TRUE, 1, CURRENT_DATE + INTERVAL '1 day', '10:00'::TIME, '12:10'::TIME, CURRENT_TIMESTAMP),
    ('Aamir Khan Adventures', TRUE, 1, CURRENT_DATE + INTERVAL '1 day', '14:00'::TIME, '16:10'::TIME, CURRENT_TIMESTAMP),
    ('Aamir Khan Adventures', TRUE, 1, CURRENT_DATE + INTERVAL '1 day', '18:00'::TIME, '20:10'::TIME, CURRENT_TIMESTAMP),
    ('Romantic Hearts', TRUE, 2, CURRENT_DATE + INTERVAL '1 day', '11:00'::TIME, '13:25'::TIME, CURRENT_TIMESTAMP),
    ('Romantic Hearts', TRUE, 2, CURRENT_DATE + INTERVAL '1 day', '15:30'::TIME, '17:55'::TIME, CURRENT_TIMESTAMP),
    ('Sci-Fi Galaxy', TRUE, 3, CURRENT_DATE + INTERVAL '2 days', '12:00'::TIME, '14:30'::TIME, CURRENT_TIMESTAMP),
    ('Comedy Gold', TRUE, 4, CURRENT_DATE + INTERVAL '2 days', '16:00'::TIME, '17:40'::TIME, CURRENT_TIMESTAMP),
    ('Horror Night', TRUE, 5, CURRENT_DATE + INTERVAL '3 days', '20:00'::TIME, '21:55'::TIME, CURRENT_TIMESTAMP),
    ('Action Blast', TRUE, 6, CURRENT_DATE + INTERVAL '5 days', '14:00'::TIME, '16:20'::TIME, CURRENT_TIMESTAMP),
    ('Family Fun', TRUE, 7, CURRENT_DATE + INTERVAL '10 days', '10:30'::TIME, '12:20'::TIME, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 9. POPULATE SHOWTIME SEAT AVAILABILITY
-- ============================================================================

-- For each showtime, create seat availability records
INSERT INTO showtime_seat_availability (showtime_id, seat_id, is_booked, booked_at, booked_by)
SELECT 
    s.showtime_id,
    seat.seat_id,
    FALSE,
    NULL,
    NULL
FROM showtime s
CROSS JOIN seat
WHERE seat.screen_id = s.screen_id
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 10. INSERT PRICING TIERS
-- ============================================================================

INSERT INTO pricing_tier (tier_name, discount_percentage, min_booking_count, description, is_active) VALUES
    ('STANDARD', 0, NULL, 'Standard pricing - no discount', TRUE),
    ('EARLY_BIRD', 15, NULL, '15% discount for bookings 7+ days in advance', TRUE),
    ('GROUP_BOOKING', 20, 4, '20% discount for group bookings (4+ seats)', TRUE),
    ('BULK_WEEKEND', 10, 8, '10% discount for bulk bookings on weekends', TRUE),
    ('STUDENT', 25, NULL, '25% student discount with valid ID', TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 11. INSERT MOVIE PRICING
-- ============================================================================

INSERT INTO movie_pricing (movie_title, standard_price, premium_price, weekend_multiplier, holiday_multiplier, effective_from, effective_to) VALUES
    ('Aamir Khan Adventures', 250, 300, 1.2, 1.3, CURRENT_DATE - INTERVAL '30 days', NULL),
    ('Romantic Hearts', 280, 330, 1.2, 1.3, CURRENT_DATE - INTERVAL '20 days', NULL),
    ('Sci-Fi Galaxy', 300, 350, 1.25, 1.35, CURRENT_DATE - INTERVAL '15 days', NULL),
    ('Comedy Gold', 220, 270, 1.15, 1.25, CURRENT_DATE - INTERVAL '10 days', NULL),
    ('Horror Night', 240, 290, 1.2, 1.3, CURRENT_DATE - INTERVAL '5 days', NULL)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 12. INSERT PROMO CODES
-- ============================================================================

INSERT INTO promo_code (promo_code, discount_type, discount_value, max_uses, current_uses, valid_from, valid_to, min_booking_amount, is_active, created_by) VALUES
    ('WELCOME20', 'PERCENTAGE', 20, 1000, 156, CURRENT_TIMESTAMP - INTERVAL '30 days', CURRENT_TIMESTAMP + INTERVAL '30 days', 500, TRUE, 'admin.mumbai@cinema.com'),
    ('SUMMER50', 'FIXED', 50, 500, 234, CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP + INTERVAL '45 days', 200, TRUE, 'admin.delhi@cinema.com'),
    ('FRIDAY25', 'PERCENTAGE', 25, 2000, 567, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP + INTERVAL '60 days', 300, TRUE, 'admin.bangalore@cinema.com'),
    ('STUDENT30', 'PERCENTAGE', 30, 500, 123, CURRENT_TIMESTAMP - INTERVAL '60 days', CURRENT_TIMESTAMP + INTERVAL '90 days', 150, TRUE, 'admin.hyderabad@cinema.com')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 13. INSERT REFUND POLICIES
-- ============================================================================

INSERT INTO refund_policy (policy_name, days_before_show, refund_percentage, applicable_for, is_active) VALUES
    ('Full Refund', 7, 100, 'ALL', TRUE),
    ('Three Quarters Refund', 3, 75, 'ALL', TRUE),
    ('Half Refund', 1, 50, 'ALL', TRUE),
    ('No Refund', 0, 0, 'ALL', TRUE),
    ('Premium Full Refund', 3, 100, 'PREMIUM', TRUE),
    ('Premium Half Refund', 1, 50, 'PREMIUM', TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 14. INSERT BOOKINGS (Sample data)
-- ============================================================================

-- Booking 1: John Doe books 2 seats
INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date, created_at)
VALUES ('john.doe@email.com', 1, 'CONFIRMED', 500, CURRENT_DATE - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '10 days')
RETURNING booking_id INTO v_booking_id;

-- Booking 2: Jane Smith books 3 seats
INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date, created_at)
VALUES ('jane.smith@email.com', 2, 'CONFIRMED', 750, CURRENT_DATE - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '8 days')
RETURNING booking_id INTO v_booking_id;

-- Booking 3: Mike Johnson books 4 seats
INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date, created_at)
VALUES ('mike.johnson@email.com', 3, 'CONFIRMED', 920, CURRENT_DATE - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days')
RETURNING booking_id INTO v_booking_id;

-- Booking 4: Sarah Williams books 2 seats (CANCELLED)
INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date, 
                     cancellation_date, cancellation_reason, created_at)
VALUES ('sarah.williams@email.com', 4, 'CANCELLED', 560, CURRENT_DATE - INTERVAL '3 days',
        CURRENT_DATE - INTERVAL '2 days', 'Change of plans', CURRENT_TIMESTAMP - INTERVAL '3 days')
RETURNING booking_id INTO v_booking_id;

-- Booking 5: Alex Brown books 5 seats
INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date, created_at)
VALUES ('alex.brown@email.com', 5, 'CONFIRMED', 1300, CURRENT_DATE - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day')
RETURNING booking_id INTO v_booking_id;

-- Booking 6: Emma Davis books 2 seats
INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date, created_at)
VALUES ('emma.davis@email.com', 1, 'CONFIRMED', 480, CURRENT_DATE, CURRENT_TIMESTAMP)
RETURNING booking_id INTO v_booking_id;

-- ============================================================================
-- 15. INSERT BOOKING SEATS
-- ============================================================================

INSERT INTO booking_seat (booking_id, seat_number, seat_type, price_per_seat, booked_at) VALUES
    (100000, 1, 'STANDARD', 250, CURRENT_TIMESTAMP - INTERVAL '10 days'),
    (100000, 2, 'STANDARD', 250, CURRENT_TIMESTAMP - INTERVAL '10 days'),
    (100001, 3, 'STANDARD', 280, CURRENT_TIMESTAMP - INTERVAL '8 days'),
    (100001, 4, 'PREMIUM', 330, CURRENT_TIMESTAMP - INTERVAL '8 days'),
    (100001, 5, 'STANDARD', 280, CURRENT_TIMESTAMP - INTERVAL '8 days'),
    (100002, 6, 'STANDARD', 300, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    (100002, 7, 'STANDARD', 300, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    (100002, 8, 'PREMIUM', 350, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    (100002, 9, 'PREMIUM', 350, CURRENT_TIMESTAMP - INTERVAL '5 days'),
    (100004, 10, 'STANDARD', 280, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (100004, 11, 'STANDARD', 280, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (100004, 12, 'STANDARD', 280, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (100004, 13, 'STANDARD', 280, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (100004, 14, 'PREMIUM', 330, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (100005, 15, 'STANDARD', 250, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 16. INSERT PAYMENTS
-- ============================================================================

INSERT INTO payment (amount, booking_id, is_refunded, user_email, payment_method, payment_status, payment_date, gateway_transaction_id) VALUES
    (500, 100000, FALSE, 'john.doe@email.com', 'CREDIT_CARD', 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '10 days', 'TXN001'),
    (750, 100001, FALSE, 'jane.smith@email.com', 'UPI', 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '8 days', 'TXN002'),
    (920, 100002, FALSE, 'mike.johnson@email.com', 'DEBIT_CARD', 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '5 days', 'TXN003'),
    (1300, 100004, FALSE, 'alex.brown@email.com', 'NET_BANKING', 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '1 day', 'TXN005'),
    (480, 100005, FALSE, 'emma.davis@email.com', 'WALLET', 'SUCCESS', CURRENT_TIMESTAMP, 'TXN006')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 17. INSERT PAYMENT REFUNDS (for cancelled booking)
-- ============================================================================

INSERT INTO payment_refund (payment_id, refund_amount, refund_reason, refund_status, refund_date, processed_at, processed_by) VALUES
    (1000004, 420, 'Cancellation requested by user', 'PROCESSED', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days', 'admin.delhi@cinema.com')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 18. INSERT USER PREFERENCES
-- ============================================================================

INSERT INTO user_preferences (user_email, preferred_genre, preferred_cinema_name, preferred_cinema_pincode, seat_preference, notification_email, notification_sms, language_preference, dark_mode) VALUES
    ('john.doe@email.com', 'Action', 'PVR Mumbai Downtown', '400001', 'WINDOW_SEAT', TRUE, TRUE, 'EN', FALSE),
    ('jane.smith@email.com', 'Drama', 'INOX Mumbai Central', '400002', 'MIDDLE_SEAT', TRUE, FALSE, 'EN', TRUE),
    ('mike.johnson@email.com', 'Sci-Fi', 'Cinepolis Bangalore', '560001', 'PREMIUM_SEAT', TRUE, TRUE, 'EN', FALSE),
    ('sarah.williams@email.com', 'Comedy', 'PVR Mumbai Downtown', '400001', 'COUPLE_SEAT', FALSE, TRUE, 'EN', FALSE),
    ('alex.brown@email.com', 'Action', 'IMAX Delhi Premium', '110001', 'PREMIUM_SEAT', TRUE, TRUE, 'EN', TRUE),
    ('emma.davis@email.com', 'Drama', 'Cinepolis Bangalore', '560001', 'STANDARD_SEAT', TRUE, TRUE, 'EN', FALSE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 19. INSERT USER BOOKING STATS
-- ============================================================================

INSERT INTO user_booking_stats (user_email, total_bookings, total_amount_spent, avg_booking_value, favorite_genre, last_booking_date, member_since, tier_status) VALUES
    ('john.doe@email.com', 15, 5800, 386.67, 'Action', CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '90 days', 'REGULAR'),
    ('jane.smith@email.com', 12, 4200, 350, 'Drama', CURRENT_DATE - INTERVAL '8 days', CURRENT_DATE - INTERVAL '60 days', 'PREMIUM'),
    ('mike.johnson@email.com', 8, 2900, 362.50, 'Sci-Fi', CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE - INTERVAL '45 days', 'REGULAR'),
    ('sarah.williams@email.com', 20, 7500, 375, 'Comedy', CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE - INTERVAL '30 days', 'VIP'),
    ('alex.brown@email.com', 5, 1800, 360, 'Action', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '15 days', 'NEW'),
    ('emma.davis@email.com', 2, 650, 325, 'Drama', CURRENT_DATE, CURRENT_DATE - INTERVAL '7 days', 'NEW')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 20. INSERT USER ACTIVITY LOGS
-- ============================================================================

INSERT INTO user_activity_log (user_email, activity_type, activity_description, ip_address, status, activity_timestamp) VALUES
    ('john.doe@email.com', 'LOGIN', 'User logged in', '192.168.1.100'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
    ('john.doe@email.com', 'BOOKING_CREATED', 'Booking 100000 created', '192.168.1.100'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '10 days'),
    ('jane.smith@email.com', 'LOGIN', 'User logged in', '192.168.1.101'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '4 hours'),
    ('jane.smith@email.com', 'BOOKING_CREATED', 'Booking 100001 created', '192.168.1.101'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '8 days'),
    ('mike.johnson@email.com', 'LOGIN', 'User logged in', '192.168.1.102'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '3 hours'),
    ('mike.johnson@email.com', 'BOOKING_CREATED', 'Booking 100002 created', '192.168.1.102'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '5 days'),
    ('emma.davis@email.com', 'LOGIN', 'User logged in', '192.168.1.105'::INET, 'SUCCESS', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
    ('emma.davis@email.com', 'BOOKING_CREATED', 'Booking 100005 created', '192.168.1.105'::INET, 'SUCCESS', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 21. INSERT AUDIT LOG ENTRIES
-- ============================================================================

INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, changed_by, changed_at) VALUES
    ('booking', 'INSERT', '100000', NULL, '{"booking_id": 100000, "user_email": "john.doe@email.com"}'::JSONB, 'john.doe@email.com', CURRENT_TIMESTAMP - INTERVAL '10 days'),
    ('booking', 'INSERT', '100001', NULL, '{"booking_id": 100001, "user_email": "jane.smith@email.com"}'::JSONB, 'jane.smith@email.com', CURRENT_TIMESTAMP - INTERVAL '8 days'),
    ('booking', 'UPDATE', '100003', '{"booking_status": "CONFIRMED"}'::JSONB, '{"booking_status": "CANCELLED"}'::JSONB, 'sarah.williams@email.com', CURRENT_TIMESTAMP - INTERVAL '2 days'),
    ('payment', 'INSERT', '1000000', NULL, '{"transaction_id": 1000000, "amount": 500}'::JSONB, 'SYSTEM', CURRENT_TIMESTAMP - INTERVAL '10 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 22. INSERT DAILY REVENUE SUMMARY
-- ============================================================================

INSERT INTO daily_revenue_summary (summary_date, total_bookings, total_revenue, total_refunds, net_revenue, avg_ticket_price, occupancy_rate) VALUES
    (CURRENT_DATE - INTERVAL '10 days', 45, 12500, 0, 12500, 277.78, 35.5),
    (CURRENT_DATE - INTERVAL '9 days', 52, 14200, 0, 14200, 273.08, 38.2),
    (CURRENT_DATE - INTERVAL '8 days', 48, 13100, 0, 13100, 272.92, 36.8),
    (CURRENT_DATE - INTERVAL '7 days', 68, 19200, 420, 18780, 282.35, 52.1),
    (CURRENT_DATE - INTERVAL '6 days', 55, 15800, 0, 15800, 287.27, 42.3),
    (CURRENT_DATE - INTERVAL '5 days', 62, 18500, 0, 18500, 298.39, 47.9),
    (CURRENT_DATE - INTERVAL '4 days', 71, 21200, 0, 21200, 298.59, 54.6),
    (CURRENT_DATE - INTERVAL '3 days', 58, 16900, 0, 16900, 291.38, 44.7),
    (CURRENT_DATE - INTERVAL '2 days', 73, 22100, 0, 22100, 302.74, 56.2),
    (CURRENT_DATE - INTERVAL '1 day', 66, 19800, 0, 19800, 300, 50.8)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 23. UPDATE SHOWTIME SEAT AVAILABILITY (Mark some as booked)
-- ============================================================================

UPDATE showtime_seat_availability
SET is_booked = TRUE, booked_at = CURRENT_TIMESTAMP - INTERVAL '10 days', booked_by = 'john.doe@email.com'
WHERE showtime_id = 1 AND seat_id IN (1, 2);

UPDATE showtime_seat_availability
SET is_booked = TRUE, booked_at = CURRENT_TIMESTAMP - INTERVAL '8 days', booked_by = 'jane.smith@email.com'
WHERE showtime_id = 2 AND seat_id IN (3, 4, 5);

UPDATE showtime_seat_availability
SET is_booked = TRUE, booked_at = CURRENT_TIMESTAMP - INTERVAL '5 days', booked_by = 'mike.johnson@email.com'
WHERE showtime_id = 3 AND seat_id IN (6, 7, 8, 9);

-- ============================================================================
-- 24. VERIFY DATA INTEGRITY
-- ============================================================================

-- Display summary statistics
SELECT 'Users' as entity, COUNT(*) as count FROM users
UNION ALL
SELECT 'Movies', COUNT(*) FROM movie
UNION ALL
SELECT 'Cinemas', COUNT(*) FROM cinema
UNION ALL
SELECT 'Screens', COUNT(*) FROM screen
UNION ALL
SELECT 'Seats', COUNT(*) FROM seat
UNION ALL
SELECT 'Showtimes', COUNT(*) FROM showtime
UNION ALL
SELECT 'Bookings', COUNT(*) FROM booking
UNION ALL
SELECT 'Payments', COUNT(*) FROM payment
ORDER BY count DESC;

COMMIT;
