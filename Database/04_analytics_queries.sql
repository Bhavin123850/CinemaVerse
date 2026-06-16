-- ============================================================================
-- CINEMAVERSE: ADVANCED ANALYTICS QUERIES
-- Purpose: Complex business intelligence and reporting queries
-- ============================================================================

SET search_path TO cinema_ticket_booking;

-- ============================================================================
-- 1. REVENUE & FINANCIAL ANALYTICS
-- ============================================================================

-- Query: Daily revenue trend with comparison to previous period
CREATE OR REPLACE VIEW revenue_daily_trend AS
WITH daily_revenue AS (
    SELECT 
        DATE(b.booking_date) as revenue_date,
        COUNT(DISTINCT b.booking_id) as total_bookings,
        SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') as gross_revenue,
        SUM(pr.refund_amount) FILTER (WHERE pr.refund_status = 'PROCESSED') as refunds,
        SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') - 
            COALESCE(SUM(pr.refund_amount) FILTER (WHERE pr.refund_status = 'PROCESSED'), 0) as net_revenue
    FROM booking b
    LEFT JOIN payment p ON b.booking_id = p.booking_id
    LEFT JOIN payment_refund pr ON p.transaction_id = pr.payment_id
    GROUP BY DATE(b.booking_date)
)
SELECT 
    revenue_date,
    total_bookings,
    gross_revenue,
    refunds,
    net_revenue,
    LAG(net_revenue) OVER (ORDER BY revenue_date) as previous_day_revenue,
    ROUND(((net_revenue - LAG(net_revenue) OVER (ORDER BY revenue_date)) / 
            LAG(net_revenue) OVER (ORDER BY revenue_date) * 100), 2) as revenue_growth_pct
FROM daily_revenue
ORDER BY revenue_date DESC;

-- Query: Revenue by cinema location
CREATE OR REPLACE VIEW revenue_by_cinema AS
SELECT 
    c.cinema_name,
    c.cinema_city,
    c.cinema_pincode,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') as gross_revenue,
    ROUND(AVG(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED'), 2) as avg_booking_value,
    COUNT(DISTINCT DATE(b.booking_date)) as active_days,
    ROUND(
        SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') / 
        NULLIF(COUNT(DISTINCT DATE(b.booking_date)), 0), 2
    ) as revenue_per_active_day
FROM cinema c
LEFT JOIN screen sc ON c.cinema_name = sc.cinema_name AND c.cinema_pincode = sc.cinema_pincode
LEFT JOIN showtime s ON sc.screen_id = s.screen_id
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_date >= CURRENT_DATE - 30
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY c.cinema_name, c.cinema_city, c.cinema_pincode
ORDER BY gross_revenue DESC NULLS LAST;

-- Query: Revenue by payment method
CREATE OR REPLACE VIEW revenue_by_payment_method AS
SELECT 
    p.payment_method,
    COUNT(DISTINCT p.transaction_id) as total_transactions,
    SUM(p.amount) FILTER (WHERE p.payment_status = 'SUCCESS') as successful_amount,
    COUNT(DISTINCT p.transaction_id) FILTER (WHERE p.payment_status = 'FAILED') as failed_transactions,
    ROUND(
        COUNT(DISTINCT CASE WHEN p.payment_status = 'SUCCESS' THEN p.transaction_id END)::DECIMAL / 
        COUNT(DISTINCT p.transaction_id) * 100, 2
    ) as success_rate_pct
FROM payment p
WHERE p.payment_date >= CURRENT_DATE - 30
GROUP BY p.payment_method
ORDER BY successful_amount DESC NULLS LAST;

-- ============================================================================
-- 2. OCCUPANCY & SEAT ANALYTICS
-- ============================================================================

-- Query: Occupancy rate by show time
CREATE OR REPLACE VIEW occupancy_by_showtime AS
SELECT 
    s.showtime_id,
    s.movie_title,
    s.show_date,
    s.start_time,
    sc.cinema_name,
    sc.cinema_city,
    COUNT(DISTINCT ssa.seat_id) as total_seats,
    COUNT(DISTINCT CASE WHEN ssa.is_booked = TRUE THEN ssa.seat_id END) as booked_seats,
    COUNT(DISTINCT CASE WHEN ssa.is_booked = FALSE THEN ssa.seat_id END) as available_seats,
    ROUND(
        COUNT(DISTINCT CASE WHEN ssa.is_booked = TRUE THEN ssa.seat_id END)::DECIMAL / 
        COUNT(DISTINCT ssa.seat_id) * 100, 2
    ) as occupancy_percentage
FROM showtime s
JOIN screen sc ON s.screen_id = sc.screen_id
LEFT JOIN showtime_seat_availability ssa ON s.showtime_id = ssa.showtime_id
WHERE s.show_date >= CURRENT_DATE
AND s.is_active = TRUE
GROUP BY s.showtime_id, s.movie_title, s.show_date, s.start_time, sc.cinema_name, sc.cinema_city
ORDER BY occupancy_percentage DESC;

-- Query: Seat type preference analysis
CREATE OR REPLACE VIEW seat_preference_analysis AS
WITH seat_bookings AS (
    SELECT 
        st.seat_type,
        COUNT(DISTINCT bs.booking_id) as bookings,
        SUM(bs.price_per_seat) as revenue,
        COUNT(DISTINCT bs.booking_id)::DECIMAL / 
            (SELECT COUNT(DISTINCT booking_id) FROM booking_seat) * 100 as booking_percentage
    FROM booking_seat bs
    JOIN seat s ON bs.seat_number = s.seat_id
    JOIN seat_type st ON s.seat_type = st.seat_type
    GROUP BY st.seat_type
)
SELECT 
    seat_type,
    bookings,
    revenue,
    ROUND(booking_percentage, 2) as booking_percentage,
    ROUND(revenue::DECIMAL / bookings, 2) as avg_revenue_per_seat
FROM seat_bookings
ORDER BY revenue DESC;

-- ============================================================================
-- 3. MOVIE PERFORMANCE ANALYTICS
-- ============================================================================

-- Query: Movie performance scorecard
CREATE OR REPLACE VIEW movie_performance_scorecard AS
SELECT 
    m.movie_title,
    m.genre,
    m.release_date,
    COUNT(DISTINCT s.showtime_id) as total_shows,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    ROUND(AVG(get_occupancy_rate(s.showtime_id)), 2) as avg_occupancy_pct,
    SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') as gross_revenue,
    ROUND(
        SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED')::DECIMAL / 
        NULLIF(COUNT(DISTINCT s.showtime_id), 0), 2
    ) as revenue_per_show,
    DATE_PART('day', CURRENT_DATE - m.release_date)::INT as days_in_circulation,
    CASE 
        WHEN AVG(get_occupancy_rate(s.showtime_id)) >= 80 THEN 'BLOCKBUSTER'
        WHEN AVG(get_occupancy_rate(s.showtime_id)) >= 60 THEN 'HIT'
        WHEN AVG(get_occupancy_rate(s.showtime_id)) >= 40 THEN 'AVERAGE'
        ELSE 'FLOP'
    END as movie_status
FROM movie m
LEFT JOIN showtime s ON m.movie_title = s.movie_title
    AND s.show_date >= CURRENT_DATE - 60
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY m.movie_title, m.genre, m.release_date
ORDER BY total_revenue DESC NULLS LAST;

-- Query: Genre performance comparison
CREATE OR REPLACE VIEW genre_performance_comparison AS
SELECT 
    m.genre,
    COUNT(DISTINCT m.movie_title) as total_movies,
    COUNT(DISTINCT s.showtime_id) as total_shows,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    ROUND(AVG(get_occupancy_rate(s.showtime_id)), 2) as avg_occupancy_pct,
    SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') as total_revenue,
    ROUND(
        SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED')::DECIMAL / 
        NULLIF(COUNT(DISTINCT b.booking_id), 0), 2
    ) as avg_booking_value
FROM movie m
LEFT JOIN showtime s ON m.movie_title = s.movie_title
    AND s.show_date >= CURRENT_DATE - 60
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY m.genre
ORDER BY total_revenue DESC NULLS LAST;

-- ============================================================================
-- 4. CUSTOMER ANALYTICS
-- ============================================================================

-- Query: Customer segmentation by value
CREATE OR REPLACE VIEW customer_value_segmentation AS
WITH customer_metrics AS (
    SELECT 
        u.user_email,
        u.name,
        COUNT(DISTINCT b.booking_id) as lifetime_bookings,
        SUM(b.total_amount) as lifetime_spent,
        MAX(b.booking_date) as last_booking_date,
        MIN(u.created_at)::DATE as member_since,
        DATE_PART('day', CURRENT_DATE - MAX(b.booking_date))::INT as days_since_last_booking
    FROM users u
    LEFT JOIN booking b ON u.user_email = b.user_email
        AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
    GROUP BY u.user_email, u.name
)
SELECT 
    user_email,
    name,
    lifetime_bookings,
    ROUND(lifetime_spent::NUMERIC, 2) as lifetime_spent,
    last_booking_date,
    member_since,
    days_since_last_booking,
    CASE 
        WHEN lifetime_spent >= 10000 THEN 'VIP'
        WHEN lifetime_spent >= 5000 THEN 'PREMIUM'
        WHEN lifetime_spent >= 1000 THEN 'REGULAR'
        ELSE 'NEW'
    END as customer_segment,
    CASE 
        WHEN days_since_last_booking IS NULL THEN 'INACTIVE'
        WHEN days_since_last_booking <= 30 THEN 'ACTIVE'
        WHEN days_since_last_booking <= 90 THEN 'AT_RISK'
        ELSE 'CHURNED'
    END as engagement_status
FROM customer_metrics
ORDER BY lifetime_spent DESC NULLS LAST;

-- Query: Customer lifetime value by genre preference
CREATE OR REPLACE VIEW clv_by_genre_preference AS
SELECT 
    COALESCE(m.genre, 'UNKNOWN') as genre_preference,
    COUNT(DISTINCT b.user_email) as unique_customers,
    SUM(b.total_amount) as total_revenue,
    ROUND(AVG(b.total_amount), 2) as avg_booking_value,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    ROUND(COUNT(DISTINCT b.booking_id)::DECIMAL / COUNT(DISTINCT b.user_email), 2) as avg_bookings_per_customer
FROM booking b
JOIN showtime s ON b.showtime_id = s.showtime_id
LEFT JOIN movie m ON s.movie_title = m.movie_title
WHERE b.booking_status IN ('CONFIRMED', 'REFUNDED')
AND b.booking_date >= CURRENT_DATE - 90
GROUP BY m.genre
ORDER BY total_revenue DESC NULLS LAST;

-- ============================================================================
-- 5. REFUND & CHURN ANALYSIS
-- ============================================================================

-- Query: Refund analysis
CREATE OR REPLACE VIEW refund_analysis AS
SELECT 
    COUNT(DISTINCT pr.refund_id) as total_refunds,
    SUM(pr.refund_amount) as total_refund_amount,
    ROUND(
        COUNT(DISTINCT pr.refund_id)::DECIMAL / 
        (SELECT COUNT(DISTINCT booking_id) FROM booking WHERE booking_status IN ('CONFIRMED', 'REFUNDED')) * 100, 2
    ) as refund_rate_pct,
    pr.refund_reason,
    COUNT(DISTINCT pr.refund_id) as refund_count_by_reason,
    ROUND(SUM(pr.refund_amount), 2) as amount_by_reason
FROM payment_refund pr
WHERE pr.refund_status = 'PROCESSED'
AND pr.refund_date >= CURRENT_DATE - 30
GROUP BY pr.refund_reason
ORDER BY amount_by_reason DESC NULLS LAST;

-- Query: Cancellation patterns
CREATE OR REPLACE VIEW cancellation_patterns AS
SELECT 
    DATE_TRUNC('day', cr.requested_at)::DATE as cancellation_date,
    cr.cancellation_reason,
    COUNT(DISTINCT cr.cancellation_id) as cancellation_count,
    AVG(EXTRACT(DAY FROM (s.show_date - cr.requested_at))) as avg_days_before_show,
    ROUND(AVG(cr.refund_amount), 2) as avg_refund_amount,
    ROUND(
        COUNT(CASE WHEN cr.cancellation_status = 'APPROVED' THEN 1 END)::DECIMAL / 
        COUNT(DISTINCT cr.cancellation_id) * 100, 2
    ) as approval_rate_pct
FROM cancellation_request cr
JOIN booking b ON cr.booking_id = b.booking_id
JOIN showtime s ON b.showtime_id = s.showtime_id
WHERE cr.requested_at >= CURRENT_DATE - 30
GROUP BY DATE_TRUNC('day', cr.requested_at), cr.cancellation_reason
ORDER BY cancellation_date DESC, cancellation_count DESC;

-- ============================================================================
-- 6. OPERATIONAL EFFICIENCY METRICS
-- ============================================================================

-- Query: Show utilization efficiency
CREATE OR REPLACE VIEW show_utilization_efficiency AS
SELECT 
    s.show_date,
    sc.cinema_name,
    COUNT(DISTINCT s.showtime_id) as shows_per_day,
    COUNT(DISTINCT CASE WHEN get_occupancy_rate(s.showtime_id) >= 80 THEN s.showtime_id END) as high_occupancy_shows,
    ROUND(AVG(get_occupancy_rate(s.showtime_id)), 2) as avg_occupancy_pct,
    SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED') as total_revenue,
    ROUND(
        SUM(b.total_amount) FILTER (WHERE b.booking_status = 'CONFIRMED')::DECIMAL / 
        NULLIF(COUNT(DISTINCT s.showtime_id), 0), 2
    ) as revenue_per_show
FROM showtime s
JOIN screen sc ON s.screen_id = sc.screen_id
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
WHERE s.show_date >= CURRENT_DATE - 30
GROUP BY s.show_date, sc.cinema_name
ORDER BY s.show_date DESC, total_revenue DESC NULLS LAST;

-- Query: Peak booking hours/times
CREATE OR REPLACE VIEW peak_booking_analysis AS
SELECT 
    DATE_TRUNC('hour', b.booking_date)::TIMESTAMP as booking_hour,
    COUNT(DISTINCT b.booking_id) as bookings,
    SUM(b.total_amount) as revenue,
    ROUND(AVG(b.total_amount), 2) as avg_booking_value,
    ROUND(
        COUNT(DISTINCT b.booking_id)::DECIMAL / 
        (SELECT COUNT(DISTINCT booking_id) FROM booking 
         WHERE booking_date >= CURRENT_DATE - 7) * 100, 2
    ) as pct_of_weekly_bookings
FROM booking b
WHERE b.booking_date >= CURRENT_DATE - 7
GROUP BY DATE_TRUNC('hour', b.booking_date)
ORDER BY bookings DESC;

-- ============================================================================
-- 7. MARKETING & PROMOTION EFFECTIVENESS
-- ============================================================================

-- Query: Promo code effectiveness
CREATE OR REPLACE VIEW promo_code_effectiveness AS
SELECT 
    pc.promo_code,
    COUNT(DISTINCT b.booking_id) as bookings_with_promo,
    SUM(pc.discount_value * COUNT(DISTINCT b.booking_id)) as total_discount_given,
    SUM(b.total_amount) as total_booking_value_with_discount,
    ROUND(
        SUM(b.total_amount)::DECIMAL / 
        NULLIF(COUNT(DISTINCT b.booking_id), 0), 2
    ) as avg_booking_value_with_promo,
    ROUND((pc.current_uses::DECIMAL / NULLIF(pc.max_uses, 0)) * 100, 2) as utilization_rate_pct
FROM promo_code pc
LEFT JOIN booking b ON b.booking_date BETWEEN pc.valid_from AND pc.valid_to
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
WHERE pc.is_active = TRUE
GROUP BY pc.promo_code, pc.discount_value, pc.current_uses, pc.max_uses
ORDER BY bookings_with_promo DESC NULLS LAST;

-- Query: Pricing tier impact on bookings
CREATE OR REPLACE VIEW pricing_tier_impact AS
SELECT 
    pt.tier_name,
    COUNT(DISTINCT b.booking_id) as bookings,
    ROUND(
        COUNT(DISTINCT b.booking_id)::DECIMAL / 
        (SELECT COUNT(DISTINCT booking_id) FROM booking) * 100, 2
    ) as booking_share_pct,
    SUM(b.total_amount) as revenue,
    ROUND(AVG(b.total_amount), 2) as avg_booking_value
FROM pricing_tier pt
LEFT JOIN booking b ON pt.discount_percentage > 0
    AND b.booking_date >= pt.created_at
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY pt.tier_name
ORDER BY revenue DESC NULLS LAST;

-- ============================================================================
-- 8. COMPLIANCE & AUDIT VIEWS
-- ============================================================================

-- Query: User activity audit trail
CREATE OR REPLACE VIEW user_activity_audit_trail AS
SELECT 
    ual.user_email,
    ual.activity_type,
    COUNT(DISTINCT ual.activity_id) as activity_count,
    MAX(ual.activity_timestamp) as last_activity,
    COUNT(CASE WHEN ual.status = 'SUCCESS' THEN 1 END) as successful_activities,
    COUNT(CASE WHEN ual.status = 'FAILED' THEN 1 END) as failed_activities,
    STRING_AGG(DISTINCT ual.ip_address::TEXT, ', ') as ip_addresses_used
FROM user_activity_log ual
WHERE ual.activity_timestamp >= CURRENT_DATE - 30
GROUP BY ual.user_email, ual.activity_type
ORDER BY ual.user_email, last_activity DESC;

-- Query: Data modification audit
CREATE OR REPLACE VIEW data_modification_audit AS
SELECT 
    al.table_name,
    al.operation,
    COUNT(DISTINCT al.audit_id) as modification_count,
    COUNT(DISTINCT al.changed_by) as users_involved,
    MAX(al.changed_at) as last_modification,
    STRING_AGG(DISTINCT al.changed_by, ', ') as modifying_users
FROM audit_log al
WHERE al.changed_at >= CURRENT_DATE - 30
GROUP BY al.table_name, al.operation
ORDER BY modification_count DESC;

COMMIT;
