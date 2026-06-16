-- ============================================================================
-- CINEMAVERSE: SQL INTERVIEW CHEAT SHEET & QUICK REFERENCE
-- Purpose: Common queries, patterns, and solutions for interviews
-- ============================================================================

SET search_path TO cinema_ticket_booking;

-- ============================================================================
-- SECTION 1: BASIC QUERIES (Foundation Level)
-- ============================================================================

-- 1.1: Get all movies with their details
-- CONCEPT: Simple SELECT with WHERE, ORDER BY
SELECT 
    movie_title,
    genre,
    duration,
    release_date,
    price,
    CASE 
        WHEN price <= 250 THEN 'Budget'
        WHEN price <= 300 THEN 'Standard'
        ELSE 'Premium'
    END as price_category
FROM movie
ORDER BY price DESC;

-- 1.2: Find all active cinemas in a specific city
-- CONCEPT: JOIN, WHERE, GROUP BY
SELECT 
    c.cinema_name,
    c.cinema_area,
    COUNT(DISTINCT s.screen_id) as active_screens,
    COUNT(DISTINCT st.showtime_id) as active_shows
FROM cinema c
LEFT JOIN screen s ON c.cinema_name = s.cinema_name 
    AND c.cinema_pincode = s.cinema_pincode
LEFT JOIN showtime st ON s.screen_id = st.screen_id
    AND st.show_date >= CURRENT_DATE
WHERE c.cinema_city = 'Mumbai'
AND c.cinema_city IS NOT NULL
GROUP BY c.cinema_name, c.cinema_area
HAVING COUNT(DISTINCT st.showtime_id) > 0;

-- 1.3: User booking history
-- CONCEPT: JOIN multiple tables, Date operations
SELECT 
    b.booking_id,
    u.name,
    m.movie_title,
    c.cinema_name,
    b.booking_date,
    b.total_amount,
    b.booking_status,
    DATE_PART('day', b.booking_date - u.created_at) as days_member
FROM booking b
JOIN users u ON b.user_email = u.user_email
JOIN showtime s ON b.showtime_id = s.showtime_id
JOIN movie m ON s.movie_title = m.movie_title
JOIN screen sc ON s.screen_id = sc.screen_id
JOIN cinema c ON sc.cinema_name = c.cinema_name
WHERE u.user_email = 'john.doe@email.com'
ORDER BY b.booking_date DESC;

-- ============================================================================
-- SECTION 2: INTERMEDIATE QUERIES (Mid-Level)
-- ============================================================================

-- 2.1: Customer segmentation using CASE
-- CONCEPT: CASE, Aggregation, Ranking
SELECT 
    u.user_email,
    u.name,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    ROUND(SUM(b.total_amount)::NUMERIC, 2) as lifetime_spent,
    ROUND(AVG(b.total_amount)::NUMERIC, 2) as avg_booking_value,
    MAX(b.booking_date) as last_booking,
    CASE 
        WHEN SUM(b.total_amount) >= 10000 THEN 'VIP'
        WHEN SUM(b.total_amount) >= 5000 THEN 'PREMIUM'
        WHEN SUM(b.total_amount) >= 1000 THEN 'REGULAR'
        ELSE 'NEW'
    END as customer_tier,
    CASE 
        WHEN MAX(b.booking_date) >= CURRENT_DATE - INTERVAL '30 days' THEN 'ACTIVE'
        WHEN MAX(b.booking_date) >= CURRENT_DATE - INTERVAL '90 days' THEN 'AT_RISK'
        ELSE 'INACTIVE'
    END as engagement_status
FROM users u
LEFT JOIN booking b ON u.user_email = b.user_email
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY u.user_email, u.name
HAVING COUNT(DISTINCT b.booking_id) > 0
ORDER BY lifetime_spent DESC;

-- 2.2: Movie performance with aggregates
-- CONCEPT: GROUP BY, HAVING, AGGREGATE functions
SELECT 
    m.movie_title,
    m.genre,
    COUNT(DISTINCT s.showtime_id) as total_shows,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    ROUND(SUM(b.total_amount)::NUMERIC, 2) as revenue,
    ROUND(AVG(b.total_amount)::NUMERIC, 2) as avg_booking_value,
    ROUND(COUNT(DISTINCT b.booking_id)::NUMERIC / 
          NULLIF(COUNT(DISTINCT s.showtime_id), 0), 2) as bookings_per_show,
    ROUND(SUM(b.total_amount)::NUMERIC / 
          NULLIF(COUNT(DISTINCT s.showtime_id), 0), 2) as revenue_per_show
FROM movie m
LEFT JOIN showtime s ON m.movie_title = s.movie_title
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY m.movie_title, m.genre
HAVING COUNT(DISTINCT s.showtime_id) > 0
ORDER BY revenue DESC;

-- 2.3: Cinema performance by location
-- CONCEPT: Multiple JOINs, GROUP BY multiple columns
SELECT 
    c.cinema_city,
    c.cinema_name,
    COUNT(DISTINCT sc.screen_id) as total_screens,
    COUNT(DISTINCT s.showtime_id) as total_shows,
    COUNT(DISTINCT b.booking_id) as total_bookings,
    ROUND(SUM(b.total_amount)::NUMERIC, 2) as total_revenue,
    ROUND(AVG(b.total_amount)::NUMERIC, 2) as avg_booking_value,
    ROUND(100.0 * COUNT(DISTINCT b.booking_id) / 
          NULLIF(SUM(seat.capacity), 0), 2) as utilization_rate
FROM cinema c
LEFT JOIN screen sc ON c.cinema_name = sc.cinema_name 
    AND c.cinema_pincode = sc.cinema_pincode
LEFT JOIN seat ON sc.screen_id = seat.screen_id
LEFT JOIN showtime s ON sc.screen_id = s.screen_id
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
    AND b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY c.cinema_city, c.cinema_name, c.cinema_pincode
ORDER BY total_revenue DESC;

-- ============================================================================
-- SECTION 3: ADVANCED QUERIES (Expert Level)
-- ============================================================================

-- 3.1: Window Functions - Revenue trending
-- CONCEPT: ROW_NUMBER, LAG, LEAD, RANK, Dense_RANK
SELECT 
    b.booking_date,
    SUM(b.total_amount) as daily_revenue,
    LAG(SUM(b.total_amount)) OVER (ORDER BY b.booking_date) as prev_day_revenue,
    LEAD(SUM(b.total_amount)) OVER (ORDER BY b.booking_date) as next_day_revenue,
    ROUND(((SUM(b.total_amount) - LAG(SUM(b.total_amount)) 
            OVER (ORDER BY b.booking_date)) / 
            LAG(SUM(b.total_amount)) OVER (ORDER BY b.booking_date) * 100)::NUMERIC, 2) as growth_pct,
    ROW_NUMBER() OVER (ORDER BY SUM(b.total_amount) DESC) as revenue_rank,
    ROUND(
        AVG(SUM(b.total_amount)) OVER (
            ORDER BY b.booking_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) as moving_avg_7day
FROM booking b
WHERE b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY b.booking_date
ORDER BY b.booking_date DESC;

-- 3.2: Top customers using PARTITION BY
-- CONCEPT: Window functions with PARTITION BY, DENSE_RANK
SELECT 
    u.name,
    u.user_email,
    b.booking_date,
    b.total_amount,
    SUM(b.total_amount) OVER (PARTITION BY u.user_email ORDER BY b.booking_date) 
        as running_total,
    DENSE_RANK() OVER (PARTITION BY DATE_TRUNC('month', b.booking_date) 
                       ORDER BY b.total_amount DESC) as monthly_rank,
    ROW_NUMBER() OVER (PARTITION BY u.user_email ORDER BY b.booking_date DESC) 
        as recency_rank
FROM booking b
JOIN users u ON b.user_email = u.user_email
WHERE b.booking_status IN ('CONFIRMED', 'REFUNDED')
ORDER BY u.user_email, b.booking_date;

-- 3.3: Common Table Expression (CTE) - Complex analysis
-- CONCEPT: WITH clause, Multiple CTEs, Recursion-ready
WITH monthly_bookings AS (
    SELECT 
        DATE_TRUNC('month', b.booking_date)::DATE as month,
        COUNT(DISTINCT b.booking_id) as bookings,
        SUM(b.total_amount) as revenue,
        COUNT(DISTINCT b.user_email) as unique_users
    FROM booking b
    WHERE b.booking_status IN ('CONFIRMED', 'REFUNDED')
    GROUP BY DATE_TRUNC('month', b.booking_date)
),
monthly_growth AS (
    SELECT 
        month,
        bookings,
        revenue,
        unique_users,
        LAG(revenue) OVER (ORDER BY month) as prev_revenue,
        ROUND(((revenue - LAG(revenue) OVER (ORDER BY month)) / 
               LAG(revenue) OVER (ORDER BY month) * 100)::NUMERIC, 2) as growth_pct,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) as revenue_rank
    FROM monthly_bookings
)
SELECT * FROM monthly_growth
ORDER BY month DESC;

-- 3.4: Complex JOIN with subqueries
-- CONCEPT: Nested SELECT, Correlated subqueries, UNION
SELECT 
    'HIGH_VALUE_CUSTOMER' as customer_type,
    u.user_email,
    u.name,
    (SELECT COUNT(*) FROM booking WHERE user_email = u.user_email) as total_bookings,
    (SELECT SUM(total_amount) FROM booking WHERE user_email = u.user_email 
     AND booking_status IN ('CONFIRMED', 'REFUNDED')) as lifetime_value,
    (SELECT MAX(booking_date) FROM booking WHERE user_email = u.user_email) as last_booking
FROM users u
WHERE (SELECT SUM(total_amount) FROM booking 
       WHERE user_email = u.user_email 
       AND booking_status IN ('CONFIRMED', 'REFUNDED')) >= 5000

UNION ALL

SELECT 
    'NEW_CUSTOMER' as customer_type,
    u.user_email,
    u.name,
    (SELECT COUNT(*) FROM booking WHERE user_email = u.user_email) as total_bookings,
    (SELECT SUM(total_amount) FROM booking WHERE user_email = u.user_email 
     AND booking_status IN ('CONFIRMED', 'REFUNDED')) as lifetime_value,
    (SELECT MAX(booking_date) FROM booking WHERE user_email = u.user_email) as last_booking
FROM users u
WHERE DATE_PART('day', CURRENT_DATE - u.created_at) <= 30;

-- ============================================================================
-- SECTION 4: OPTIMIZATION TECHNIQUES
-- ============================================================================

-- 4.1: Using EXPLAIN to analyze query performance
-- CONCEPT: Query optimization, Index usage
EXPLAIN ANALYZE
SELECT 
    b.booking_id,
    b.user_email,
    SUM(bs.price_per_seat) as total_price
FROM booking b
JOIN booking_seat bs ON b.booking_id = bs.booking_id
WHERE b.booking_date >= CURRENT_DATE - INTERVAL '30 days'
AND b.booking_status = 'CONFIRMED'
GROUP BY b.booking_id, b.user_email;

-- 4.2: Index recommendations
-- See existing indexes:
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'cinema_ticket_booking'
ORDER BY tablename, indexname;

-- 4.3: View query execution statistics
-- CONCEPT: Performance monitoring
SELECT 
    query,
    calls,
    total_time,
    ROUND((total_time / calls)::NUMERIC, 2) as avg_time_ms
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_time DESC
LIMIT 10;

-- ============================================================================
-- SECTION 5: DATA MANIPULATION PATTERNS
-- ============================================================================

-- 5.1: Bulk update with conditions
-- CONCEPT: UPDATE with JOIN, CASE statements
UPDATE booking_seat bs
SET price_per_seat = CASE 
    WHEN bs.seat_type = 'PREMIUM' THEN bs.price_per_seat * 1.2
    WHEN bs.seat_type = 'COUPLE' THEN bs.price_per_seat * 1.15
    ELSE bs.price_per_seat
END
FROM booking b
WHERE bs.booking_id = b.booking_id
AND b.booking_date >= CURRENT_DATE - INTERVAL '7 days';

-- 5.2: Insert with subquery
-- CONCEPT: INSERT INTO ... SELECT
INSERT INTO booking_seat (booking_id, seat_number, seat_type, price_per_seat)
SELECT 
    100000 as booking_id,
    s.seat_id,
    s.seat_type,
    m.price
FROM seat s
CROSS JOIN (SELECT price FROM movie LIMIT 1) m
WHERE s.screen_id = 1
AND s.seat_id NOT IN (SELECT seat_number FROM booking_seat WHERE booking_id = 100000);

-- 5.3: Delete with conditions
-- CONCEPT: DELETE cascade, Soft deletes
UPDATE booking
SET is_deleted = TRUE
WHERE booking_date < CURRENT_DATE - INTERVAL '2 years'
AND booking_status = 'CANCELLED';

-- ============================================================================
-- SECTION 6: AGGREGATION PATTERNS
-- ============================================================================

-- 6.1: Multi-level aggregation
-- CONCEPT: GROUP BY with multiple levels
SELECT 
    EXTRACT(YEAR FROM b.booking_date) as year,
    EXTRACT(MONTH FROM b.booking_date) as month,
    EXTRACT(DAY FROM b.booking_date) as day,
    COUNT(*) as bookings,
    SUM(b.total_amount) as revenue
FROM booking b
WHERE b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY 
    EXTRACT(YEAR FROM b.booking_date),
    EXTRACT(MONTH FROM b.booking_date),
    EXTRACT(DAY FROM b.booking_date)
ORDER BY year DESC, month DESC, day DESC;

-- 6.2: Pivot table using CASE
-- CONCEPT: Conditional aggregation
SELECT 
    EXTRACT(MONTH FROM b.booking_date)::INT as month,
    COUNT(CASE WHEN p.payment_method = 'CREDIT_CARD' THEN 1 END) as credit_card,
    COUNT(CASE WHEN p.payment_method = 'DEBIT_CARD' THEN 1 END) as debit_card,
    COUNT(CASE WHEN p.payment_method = 'UPI' THEN 1 END) as upi,
    COUNT(CASE WHEN p.payment_method = 'NET_BANKING' THEN 1 END) as net_banking,
    COUNT(*) as total
FROM booking b
JOIN payment p ON b.booking_id = p.booking_id
WHERE b.booking_status IN ('CONFIRMED', 'REFUNDED')
GROUP BY EXTRACT(MONTH FROM b.booking_date)
ORDER BY month DESC;

-- 6.3: Running totals and cumulative sums
-- CONCEPT: SUM with OVER clause
SELECT 
    b.booking_date,
    b.total_amount,
    SUM(b.total_amount) OVER (ORDER BY b.booking_date) as cumulative_revenue,
    SUM(b.total_amount) OVER (
        ORDER BY b.booking_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as running_total
FROM booking b
WHERE b.booking_status = 'CONFIRMED'
ORDER BY b.booking_date;

-- ============================================================================
-- SECTION 7: STRING & DATE OPERATIONS
-- ============================================================================

-- 7.1: String operations
-- CONCEPT: CONCAT, SUBSTR, UPPER, LOWER, LIKE
SELECT 
    CONCAT(u.name, ' (', u.user_email, ')') as user_info,
    UPPER(m.genre) as genre,
    LOWER(c.cinema_city) as city,
    SUBSTR(u.phone_number, 1, 5) as phone_prefix
FROM users u
JOIN booking b ON u.user_email = b.user_email
JOIN showtime s ON b.showtime_id = s.showtime_id
JOIN movie m ON s.movie_title = m.movie_title
JOIN screen sc ON s.screen_id = sc.screen_id
JOIN cinema c ON sc.cinema_name = c.cinema_name
WHERE u.name LIKE '%John%' OR u.name ILIKE '%john%'
LIMIT 10;

-- 7.2: Date operations
-- CONCEPT: DATE_PART, DATE_TRUNC, INTERVAL
SELECT 
    b.booking_id,
    b.booking_date,
    s.show_date,
    AGE(s.show_date, b.booking_date) as days_in_advance,
    CASE 
        WHEN s.show_date - b.booking_date > INTERVAL '7 days' THEN 'Early'
        WHEN s.show_date - b.booking_date > INTERVAL '2 days' THEN 'Standard'
        ELSE 'Last Minute'
    END as booking_type,
    EXTRACT(DOW FROM s.show_date) as day_of_week,
    TO_CHAR(s.show_date, 'Day, Mon DD, YYYY') as formatted_date
FROM booking b
JOIN showtime s ON b.showtime_id = s.showtime_id;

-- ============================================================================
-- SECTION 8: NULL HANDLING
-- ============================================================================

-- 8.1: Dealing with NULLs
-- CONCEPT: COALESCE, NULLIF, IS NULL
SELECT 
    u.user_email,
    u.name,
    COALESCE(u.phone_number, 'N/A') as phone,
    COUNT(COALESCE(b.booking_id, 0)) as booking_count,
    COALESCE(SUM(b.total_amount), 0) as total_spent
FROM users u
LEFT JOIN booking b ON u.user_email = b.user_email
GROUP BY u.user_email, u.name
ORDER BY total_spent DESC NULLS LAST;

-- 8.2: NULLIF pattern
-- CONCEPT: Prevent division by zero
SELECT 
    m.movie_title,
    COUNT(DISTINCT s.showtime_id) as shows,
    COUNT(DISTINCT b.booking_id) as bookings,
    ROUND(COUNT(DISTINCT b.booking_id)::NUMERIC / 
          NULLIF(COUNT(DISTINCT s.showtime_id), 0), 2) as bookings_per_show
FROM movie m
LEFT JOIN showtime s ON m.movie_title = s.movie_title
LEFT JOIN booking b ON s.showtime_id = b.showtime_id
GROUP BY m.movie_title;

-- ============================================================================
-- SECTION 9: COMMON INTERVIEW MISTAKES & CORRECTIONS
-- ============================================================================

/*
MISTAKE 1: Incorrect GROUP BY
❌ BAD:
    SELECT u.name, COUNT(*) FROM users u 
    JOIN booking b ON u.user_email = b.user_email
    GROUP BY u.user_email;
    -- ERROR: u.name not in GROUP BY

✅ GOOD:
    SELECT u.name, COUNT(*) FROM users u 
    JOIN booking b ON u.user_email = b.user_email
    GROUP BY u.user_email, u.name;

MISTAKE 2: N+1 Problem
❌ BAD: Loop through bookings and query for each
✅ GOOD: Use JOIN or WINDOW functions in one query

MISTAKE 3: Wrong JOIN type
❌ BAD: 
    SELECT * FROM booking b 
    INNER JOIN users u ON b.user_email = u.user_email;
    -- Loses users with no bookings

✅ GOOD:
    SELECT * FROM users u 
    LEFT JOIN booking b ON b.user_email = u.user_email;

MISTAKE 4: Missing aggregate function
❌ BAD:
    SELECT user_email, total_amount 
    FROM booking 
    GROUP BY user_email;
    -- ERROR: total_amount must be aggregated

✅ GOOD:
    SELECT user_email, SUM(total_amount) 
    FROM booking 
    GROUP BY user_email;

MISTAKE 5: Inefficient subqueries
❌ BAD:
    SELECT * FROM users u 
    WHERE (SELECT COUNT(*) FROM booking 
           WHERE user_email = u.user_email) > 5;

✅ GOOD:
    SELECT u.* FROM users u 
    JOIN booking b ON u.user_email = b.user_email 
    GROUP BY u.user_email 
    HAVING COUNT(*) > 5;
*/

-- ============================================================================
-- SECTION 10: TRANSACTION EXAMPLES
-- ============================================================================

-- 10.1: Transaction with error handling
-- CONCEPT: BEGIN, COMMIT, ROLLBACK
/*
BEGIN;

    SAVEPOINT before_booking;
    
    INSERT INTO booking (user_email, showtime_id, booking_status, total_amount)
    VALUES ('user@email.com', 1, 'CONFIRMED', 500);
    
    UPDATE showtime_seat_availability
    SET is_booked = TRUE
    WHERE showtime_id = 1 AND seat_id = 1;
    
    INSERT INTO payment (amount, booking_id, user_email, payment_status)
    VALUES (500, 100000, 'user@email.com', 'SUCCESS');

COMMIT;

-- If error occurs, rollback to savepoint:
-- ROLLBACK TO SAVEPOINT before_booking;
*/

-- ============================================================================
-- INTERVIEW TIPS & TRICKS
-- ============================================================================

/*
1. EXPLAIN YOUR QUERIES
   "This query uses a LEFT JOIN to keep all users even if they have 
    no bookings. Then we GROUP BY to get counts."

2. THINK OUT LOUD
   "Let me break this down: First I need to get user bookings, 
    then calculate the total, then rank them..."

3. OPTIMIZE AS YOU GO
   "Instead of a subquery for each row, I'll use a window function 
    which is more efficient."

4. CONSIDER EDGE CASES
   "What if a user has no bookings? I should use COALESCE 
    to return 0 instead of NULL."

5. WRITE READABLE QUERIES
   Use aliases, proper formatting, comments
   Make it easy to understand at a glance

6. TEST YOUR LOGIC
   Always verify results make sense
   Check edge cases (empty results, NULLs, etc.)

7. KNOW YOUR INDEXES
   Be ready to discuss which columns should be indexed
   Explain why certain queries are slow

8. PRACTICE WINDOW FUNCTIONS
   ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, SUM OVER
   These are common in intermediate/advanced interviews
*/

COMMIT;
