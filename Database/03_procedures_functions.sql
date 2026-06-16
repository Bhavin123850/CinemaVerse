-- ============================================================================
-- CINEMAVERSE: ADVANCED STORED PROCEDURES & FUNCTIONS
-- Purpose: Business logic automation, data integrity, and complex operations
-- ============================================================================

SET search_path TO cinema_ticket_booking;

-- ============================================================================
-- 1. BOOKING MANAGEMENT PROCEDURES
-- ============================================================================

-- Procedure: Create booking with seat reservation and validation
CREATE OR REPLACE FUNCTION create_booking(
    p_user_email VARCHAR,
    p_showtime_id INT,
    p_seat_ids INT[],
    p_promo_code VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    booking_id INT,
    total_amount DECIMAL,
    message TEXT,
    success BOOLEAN
) AS $$
DECLARE
    v_booking_id INT;
    v_movie_title VARCHAR;
    v_show_date DATE;
    v_price DECIMAL;
    v_total_amount DECIMAL := 0;
    v_discount DECIMAL := 0;
    v_seat_id INT;
    v_seat_type VARCHAR;
    v_available_count INT;
    v_promo_discount DECIMAL := 0;
BEGIN
    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_email = p_user_email) THEN
        RETURN QUERY SELECT 0, 0::DECIMAL, 'User not found', FALSE;
        RETURN;
    END IF;

    -- Validate showtime exists and is in future
    SELECT s.movie_title, s.show_date, m.price
    INTO v_movie_title, v_show_date, v_price
    FROM showtime s
    JOIN movie m ON s.movie_title = m.movie_title
    WHERE s.showtime_id = p_showtime_id
    AND s.show_date > CURRENT_DATE
    AND s.is_active = TRUE;

    IF v_movie_title IS NULL THEN
        RETURN QUERY SELECT 0, 0::DECIMAL, 'Invalid or expired showtime', FALSE;
        RETURN;
    END IF;

    -- Check seat availability
    SELECT COUNT(*)
    INTO v_available_count
    FROM showtime_seat_availability
    WHERE showtime_id = p_showtime_id
    AND seat_id = ANY(p_seat_ids)
    AND is_booked = FALSE;

    IF v_available_count < array_length(p_seat_ids, 1) THEN
        RETURN QUERY SELECT 0, 0::DECIMAL, 'Some seats are already booked', FALSE;
        RETURN;
    END IF;

    -- Validate promo code if provided
    IF p_promo_code IS NOT NULL THEN
        SELECT discount_value INTO v_promo_discount
        FROM promo_code
        WHERE promo_code = p_promo_code
        AND is_active = TRUE
        AND current_timestamp BETWEEN valid_from AND valid_to
        AND current_uses < max_uses;

        IF v_promo_discount IS NULL THEN
            v_promo_discount := 0;
        END IF;
    END IF;

    -- Calculate total amount
    v_total_amount := v_price * array_length(p_seat_ids, 1);
    v_total_amount := v_total_amount * (1 - (v_promo_discount / 100));

    -- Create booking
    INSERT INTO booking (user_email, showtime_id, booking_status, total_amount, booking_date)
    VALUES (p_user_email, p_showtime_id, 'CONFIRMED', v_total_amount, CURRENT_DATE)
    RETURNING booking.booking_id INTO v_booking_id;

    -- Add booking seats and update availability
    FOREACH v_seat_id IN ARRAY p_seat_ids LOOP
        SELECT seat_type INTO v_seat_type FROM seat WHERE seat_id = v_seat_id;

        INSERT INTO booking_seat (booking_id, seat_number, seat_type, price_per_seat)
        VALUES (v_booking_id, v_seat_id, v_seat_type, v_price);

        UPDATE showtime_seat_availability
        SET is_booked = TRUE, booked_at = CURRENT_TIMESTAMP, booked_by = p_user_email
        WHERE showtime_id = p_showtime_id AND seat_id = v_seat_id;
    END LOOP;

    -- Update promo code usage
    IF p_promo_code IS NOT NULL THEN
        UPDATE promo_code
        SET current_uses = current_uses + 1
        WHERE promo_code = p_promo_code;
    END IF;

    -- Log activity
    INSERT INTO user_activity_log (user_email, activity_type, activity_description, status)
    VALUES (p_user_email, 'BOOKING_CREATED', 'Booking ' || v_booking_id || ' created successfully', 'SUCCESS');

    RETURN QUERY SELECT v_booking_id, v_total_amount, 'Booking created successfully', TRUE;

END;
$$ LANGUAGE plpgsql;

-- Procedure: Cancel booking and process refund
CREATE OR REPLACE FUNCTION cancel_booking(
    p_booking_id INT,
    p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (
    refund_amount DECIMAL,
    refund_status VARCHAR,
    message TEXT,
    success BOOLEAN
) AS $$
DECLARE
    v_user_email VARCHAR;
    v_showtime_id INT;
    v_show_date DATE;
    v_original_amount DECIMAL;
    v_refund_percentage DECIMAL;
    v_refund_amount DECIMAL;
    v_days_before_show INT;
    v_payment_id INT;
    v_seat_id INT;
BEGIN
    -- Get booking details
    SELECT b.user_email, b.showtime_id, b.total_amount, s.show_date
    INTO v_user_email, v_showtime_id, v_original_amount, v_show_date
    FROM booking b
    JOIN showtime s ON b.showtime_id = s.showtime_id
    WHERE b.booking_id = p_booking_id
    AND b.is_deleted = FALSE
    AND b.booking_status != 'CANCELLED';

    IF v_user_email IS NULL THEN
        RETURN QUERY SELECT 0::DECIMAL, 'FAILED', 'Booking not found or already cancelled', FALSE;
        RETURN;
    END IF;

    -- Calculate days before show
    v_days_before_show := v_show_date - CURRENT_DATE;

    -- Get refund policy applicable
    SELECT refund_percentage
    INTO v_refund_percentage
    FROM refund_policy
    WHERE days_before_show <= v_days_before_show
    AND is_active = TRUE
    ORDER BY days_before_show DESC
    LIMIT 1;

    IF v_refund_percentage IS NULL THEN
        v_refund_percentage := 0;
    END IF;

    v_refund_amount := v_original_amount * (v_refund_percentage / 100);

    -- Mark booking as cancelled
    UPDATE booking
    SET booking_status = 'CANCELLED',
        cancellation_date = CURRENT_TIMESTAMP,
        cancellation_reason = p_reason
    WHERE booking_id = p_booking_id;

    -- Free up seats
    DELETE FROM showtime_seat_availability
    WHERE showtime_id = v_showtime_id
    AND booked_by = v_user_email;

    -- Create refund record
    SELECT transaction_id INTO v_payment_id
    FROM payment
    WHERE booking_id = p_booking_id
    AND payment_status = 'SUCCESS';

    IF v_payment_id IS NOT NULL THEN
        INSERT INTO payment_refund (payment_id, refund_amount, refund_reason, refund_status)
        VALUES (v_payment_id, v_refund_amount, p_reason, 'PROCESSED');

        UPDATE payment
        SET is_refunded = TRUE, refund_date = CURRENT_TIMESTAMP
        WHERE transaction_id = v_payment_id;
    END IF;

    -- Log activity
    INSERT INTO user_activity_log (user_email, activity_type, activity_description, status)
    VALUES (v_user_email, 'BOOKING_CANCELLED', 'Booking ' || p_booking_id || ' cancelled. Refund: ' || v_refund_amount, 'SUCCESS');

    RETURN QUERY SELECT v_refund_amount, 'PROCESSED', 'Booking cancelled. Refund will be processed', TRUE;

END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. AVAILABILITY & INVENTORY MANAGEMENT
-- ============================================================================

-- Function: Get available seats for a showtime
CREATE OR REPLACE FUNCTION get_available_seats(p_showtime_id INT)
RETURNS TABLE (
    seat_id INT,
    seat_row CHAR,
    seat_number INT,
    seat_type VARCHAR
) AS $$
SELECT 
    s.seat_id,
    s.seat_row,
    s.seat_number,
    s.seat_type
FROM seat s
JOIN showtime_seat_availability ssa ON s.seat_id = ssa.seat_id
WHERE ssa.showtime_id = p_showtime_id
AND ssa.is_booked = FALSE
AND s.is_available = TRUE
ORDER BY s.seat_row, s.seat_number;
$$ LANGUAGE SQL;

-- Function: Get seat occupancy rate
CREATE OR REPLACE FUNCTION get_occupancy_rate(p_showtime_id INT)
RETURNS DECIMAL AS $$
DECLARE
    v_total_seats INT;
    v_booked_seats INT;
    v_occupancy_rate DECIMAL;
BEGIN
    SELECT COUNT(*) INTO v_total_seats
    FROM showtime_seat_availability
    WHERE showtime_id = p_showtime_id;

    SELECT COUNT(*) INTO v_booked_seats
    FROM showtime_seat_availability
    WHERE showtime_id = p_showtime_id
    AND is_booked = TRUE;

    IF v_total_seats = 0 THEN
        RETURN 0;
    END IF;

    v_occupancy_rate := (v_booked_seats::DECIMAL / v_total_seats) * 100;
    RETURN ROUND(v_occupancy_rate, 2);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. ANALYTICS & REPORTING FUNCTIONS
-- ============================================================================

-- Function: Calculate revenue for a specific period
CREATE OR REPLACE FUNCTION calculate_revenue(
    p_start_date DATE,
    p_end_date DATE,
    p_cinema_name VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    total_bookings BIGINT,
    total_revenue DECIMAL,
    avg_booking_value DECIMAL,
    revenue_by_movie JSON
) AS $$
DECLARE
    v_total_bookings BIGINT;
    v_total_revenue DECIMAL;
    v_avg_booking_value DECIMAL;
    v_revenue_by_movie JSON;
BEGIN
    SELECT 
        COUNT(DISTINCT b.booking_id),
        COALESCE(SUM(b.total_amount), 0),
        COALESCE(AVG(b.total_amount), 0)
    INTO v_total_bookings, v_total_revenue, v_avg_booking_value
    FROM booking b
    JOIN showtime s ON b.showtime_id = s.showtime_id
    JOIN screen sc ON s.screen_id = sc.screen_id
    JOIN cinema c ON sc.cinema_name = c.cinema_name AND sc.cinema_pincode = c.cinema_pincode
    WHERE b.booking_date BETWEEN p_start_date AND p_end_date
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
    AND (p_cinema_name IS NULL OR c.cinema_name = p_cinema_name);

    SELECT json_agg(
        json_build_object(
            'movie_title', m.movie_title,
            'total_revenue', COALESCE(SUM(b.total_amount), 0),
            'bookings', COUNT(DISTINCT b.booking_id)
        )
    ) INTO v_revenue_by_movie
    FROM movie m
    LEFT JOIN showtime s ON m.movie_title = s.movie_title
    LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    WHERE b.booking_date BETWEEN p_start_date AND p_end_date
    OR b.booking_id IS NULL
    GROUP BY m.movie_title;

    RETURN QUERY SELECT v_total_bookings, v_total_revenue, v_avg_booking_value, v_revenue_by_movie;
END;
$$ LANGUAGE plpgsql;

-- Function: Get top performing movies
CREATE OR REPLACE FUNCTION get_top_movies(p_limit INT DEFAULT 10, p_period_days INT DEFAULT 30)
RETURNS TABLE (
    movie_title VARCHAR,
    total_bookings BIGINT,
    total_revenue DECIMAL,
    occupancy_rate DECIMAL
) AS $$
SELECT 
    m.movie_title,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    COALESCE(SUM(b.total_amount), 0) as total_revenue,
    ROUND(
        (COUNT(DISTINCT bs.seat_number)::DECIMAL / 
         (SELECT COUNT(*) FROM seat WHERE screen_id IN 
            (SELECT screen_id FROM showtime WHERE movie_title = m.movie_title))) * 100, 2
    ) as occupancy_rate
FROM movie m
LEFT JOIN showtime s ON m.movie_title = s.movie_title
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_date >= CURRENT_DATE - p_period_days
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
LEFT JOIN booking_seat bs ON b.booking_id = bs.booking_id
WHERE s.show_date >= CURRENT_DATE - p_period_days
GROUP BY m.movie_title
ORDER BY total_revenue DESC
LIMIT p_limit;
$$ LANGUAGE SQL;

-- Function: Get cinema performance
CREATE OR REPLACE FUNCTION get_cinema_performance(p_cinema_name VARCHAR, p_cinema_pincode VARCHAR)
RETURNS TABLE (
    cinema_name VARCHAR,
    total_shows INT,
    total_bookings BIGINT,
    total_revenue DECIMAL,
    avg_occupancy DECIMAL,
    top_movie VARCHAR
) AS $$
SELECT 
    c.cinema_name,
    COUNT(DISTINCT s.showtime_id) as total_shows,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    COALESCE(SUM(b.total_amount), 0) as total_revenue,
    ROUND(AVG(get_occupancy_rate(s.showtime_id)), 2) as avg_occupancy,
    (SELECT s2.movie_title FROM showtime s2 
     WHERE s2.screen_id IN (SELECT screen_id FROM screen WHERE cinema_name = c.cinema_name)
     GROUP BY s2.movie_title 
     ORDER BY COUNT(DISTINCT s2.showtime_id) DESC LIMIT 1) as top_movie
FROM cinema c
LEFT JOIN screen sc ON c.cinema_name = sc.cinema_name AND c.cinema_pincode = sc.cinema_pincode
LEFT JOIN showtime s ON sc.screen_id = s.screen_id
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
WHERE c.cinema_name = p_cinema_name
AND c.cinema_pincode = p_cinema_pincode
GROUP BY c.cinema_name, c.cinema_pincode;
$$ LANGUAGE SQL;

-- ============================================================================
-- 4. USER ANALYTICS & PREFERENCES
-- ============================================================================

-- Function: Update user booking statistics
CREATE OR REPLACE FUNCTION update_user_stats(p_user_email VARCHAR)
RETURNS void AS $$
BEGIN
    INSERT INTO user_booking_stats 
        (user_email, total_bookings, total_amount_spent, avg_booking_value, 
         favorite_genre, last_booking_date, member_since)
    SELECT 
        b.user_email,
        COUNT(DISTINCT b.booking_id),
        COALESCE(SUM(b.total_amount), 0),
        COALESCE(AVG(b.total_amount), 0),
        (SELECT m.genre FROM movie m 
         JOIN showtime s ON m.movie_title = s.movie_title
         JOIN booking b2 ON s.showtime_id = b2.showtime_id
         WHERE b2.user_email = b.user_email
         GROUP BY m.genre ORDER BY COUNT(*) DESC LIMIT 1),
        MAX(b.booking_date),
        MIN(u.created_at)::DATE
    FROM booking b
    JOIN users u ON b.user_email = u.user_email
    WHERE b.user_email = p_user_email
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
    ON CONFLICT (user_email) DO UPDATE SET
        total_bookings = EXCLUDED.total_bookings,
        total_amount_spent = EXCLUDED.total_amount_spent,
        avg_booking_value = EXCLUDED.avg_booking_value,
        last_booking_date = EXCLUDED.last_booking_date;
END;
$$ LANGUAGE plpgsql;

-- Function: Get user booking recommendations
CREATE OR REPLACE FUNCTION get_user_recommendations(p_user_email VARCHAR, p_limit INT DEFAULT 5)
RETURNS TABLE (
    showtime_id INT,
    movie_title VARCHAR,
    genre VARCHAR,
    show_date DATE,
    cinema_name VARCHAR,
    available_seats INT
) AS $$
WITH user_preferences AS (
    SELECT COALESCE(preferred_genre, (
        SELECT m.genre FROM movie m
        JOIN showtime s ON m.movie_title = s.movie_title
        JOIN booking b ON s.showtime_id = b.showtime_id
        WHERE b.user_email = p_user_email
        GROUP BY m.genre ORDER BY COUNT(*) DESC LIMIT 1
    )) as fav_genre
    FROM user_preferences
    WHERE user_email = p_user_email
)
SELECT 
    s.showtime_id,
    s.movie_title,
    m.genre,
    s.show_date,
    sc.cinema_name,
    COUNT(CASE WHEN ssa.is_booked = FALSE THEN 1 END) as available_seats
FROM showtime s
JOIN movie m ON s.movie_title = m.movie_title
JOIN screen sc ON s.screen_id = sc.screen_id
JOIN showtime_seat_availability ssa ON s.showtime_id = ssa.showtime_id
CROSS JOIN user_preferences up
WHERE s.show_date >= CURRENT_DATE
AND s.is_active = TRUE
AND m.genre = up.fav_genre
GROUP BY s.showtime_id, s.movie_title, m.genre, s.show_date, sc.cinema_name
HAVING COUNT(CASE WHEN ssa.is_booked = FALSE THEN 1 END) > 0
ORDER BY s.show_date
LIMIT p_limit;
$$ LANGUAGE SQL;

-- ============================================================================
-- 5. AUDIT & LOGGING TRIGGERS
-- ============================================================================

-- Trigger: Log booking changes
CREATE OR REPLACE FUNCTION log_booking_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log 
        (table_name, operation, record_id, old_values, new_values, changed_by)
    VALUES (
        'booking',
        TG_OP,
        NEW.booking_id::TEXT,
        to_jsonb(OLD),
        to_jsonb(NEW),
        COALESCE(NEW.user_email, OLD.user_email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER booking_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON booking
FOR EACH ROW EXECUTE FUNCTION log_booking_changes();

-- Trigger: Log payment changes
CREATE OR REPLACE FUNCTION log_payment_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log 
        (table_name, operation, record_id, old_values, new_values, changed_by)
    VALUES (
        'payment',
        TG_OP,
        NEW.transaction_id::TEXT,
        to_jsonb(OLD),
        to_jsonb(NEW),
        NEW.user_email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payment_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON payment
FOR EACH ROW EXECUTE FUNCTION log_payment_changes();

-- ============================================================================
-- 6. DATA REFRESH PROCEDURES
-- ============================================================================

-- Procedure: Refresh daily revenue summary
CREATE OR REPLACE PROCEDURE refresh_daily_revenue_summary(p_date DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM daily_revenue_summary WHERE summary_date = p_date;

    INSERT INTO daily_revenue_summary 
        (summary_date, total_bookings, total_revenue, total_refunds, net_revenue, avg_ticket_price, occupancy_rate)
    SELECT 
        p_date,
        COUNT(DISTINCT b.booking_id),
        COALESCE(SUM(CASE WHEN b.booking_status = 'CONFIRMED' THEN b.total_amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN pr.refund_status = 'PROCESSED' THEN pr.refund_amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN b.booking_status = 'CONFIRMED' THEN b.total_amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN pr.refund_status = 'PROCESSED' THEN pr.refund_amount ELSE 0 END), 0),
        COALESCE(AVG(b.total_amount), 0),
        ROUND(
            (COUNT(DISTINCT bs.seat_number)::DECIMAL / 
             (SELECT COUNT(*) FROM seat WHERE screen_id IN 
                (SELECT DISTINCT screen_id FROM showtime WHERE show_date = p_date))) * 100, 2
        )
    FROM booking b
    LEFT JOIN booking_seat bs ON b.booking_id = bs.booking_id
    LEFT JOIN showtime s ON b.showtime_id = s.showtime_id
    LEFT JOIN payment p ON b.booking_id = p.booking_id
    LEFT JOIN payment_refund pr ON p.transaction_id = pr.payment_id
    WHERE b.booking_date = p_date;

    COMMIT;
END;
$$;

-- Procedure: Refresh movie analytics
CREATE OR REPLACE PROCEDURE refresh_movie_analytics(p_date DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM movie_analytics WHERE analytics_date = p_date;

    INSERT INTO movie_analytics 
        (movie_title, analytics_date, total_shows, total_seats_available, 
         total_seats_booked, occupancy_percentage, revenue_generated, avg_revenue_per_show)
    SELECT 
        m.movie_title,
        p_date,
        COUNT(DISTINCT s.showtime_id),
        COUNT(DISTINCT CASE WHEN ssa.is_booked = FALSE THEN ssa.seat_id END),
        COUNT(DISTINCT CASE WHEN ssa.is_booked = TRUE THEN ssa.seat_id END),
        ROUND(
            (COUNT(DISTINCT CASE WHEN ssa.is_booked = TRUE THEN ssa.seat_id END)::DECIMAL / 
             COUNT(DISTINCT ssa.seat_id)) * 100, 2
        ),
        COALESCE(SUM(b.total_amount), 0),
        COALESCE(SUM(b.total_amount)::DECIMAL / NULLIF(COUNT(DISTINCT s.showtime_id), 0), 0)
    FROM movie m
    LEFT JOIN showtime s ON m.movie_title = s.movie_title AND s.show_date = p_date
    LEFT JOIN showtime_seat_availability ssa ON s.showtime_id = ssa.showtime_id
    LEFT JOIN booking b ON s.showtime_id = b.showtime_id AND b.booking_date = p_date
    GROUP BY m.movie_title;

    COMMIT;
END;
$$;

COMMIT;
