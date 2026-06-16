-- ============================================================================
-- CINEMAVERSE: DATABASE DOCUMENTATION & BEST PRACTICES
-- ============================================================================

/*
╔════════════════════════════════════════════════════════════════════════════╗
║                       CINEMAVERSE DATABASE GUIDE                           ║
║              Advanced Enterprise-Grade Cinema Booking System                ║
╚════════════════════════════════════════════════════════════════════════════╝

PROJECT OVERVIEW
================
CinemaVerse is a production-ready PostgreSQL database system for managing
cinema hall ticket bookings. It demonstrates advanced database concepts
including:
  • Complex data modeling and normalization (BCNF)
  • Advanced querying with window functions and CTEs
  • Stored procedures and functions for business logic
  • Triggers and audit trails for data integrity
  • Performance optimization with strategic indexing
  • Analytics and reporting capabilities
  • Security and access control

LEARNING OBJECTIVES FOR PLACEMENTS
===================================
This project showcases proficiency in:

1. DATABASE DESIGN & NORMALIZATION
   - Entity Relationship Diagrams (ERD)
   - Boyce-Codd Normal Form (BCNF) normalization
   - Proper constraint management (PK, FK, CHECK, UNIQUE)
   - Audit and versioning patterns

2. ADVANCED SQL CONCEPTS
   - Window functions (ROW_NUMBER, RANK, LAG, LEAD)
   - Common Table Expressions (CTEs) and Recursive queries
   - Aggregate functions and GROUP BY operations
   - JSON operations and data structures
   - Full-text search capabilities

3. STORED PROCEDURES & FUNCTIONS
   - PL/pgSQL programming
   - Transaction management
   - Error handling and validation
   - Performance optimization techniques

4. TRIGGERS & AUTOMATION
   - Data integrity enforcement
   - Audit trail logging
   - Cascading updates and deletes
   - Time-based automation

5. ANALYTICS & REPORTING
   - Materialized views for performance
   - Complex reporting queries
   - Business intelligence patterns
   - KPI calculation and tracking

6. SECURITY & COMPLIANCE
   - Role-based access control (RBAC)
   - User activity logging
   - Data audit trails
   - Compliance tracking

═══════════════════════════════════════════════════════════════════════════════

SCHEMA OVERVIEW
===============

Core Tables:
  • users (User registration and authentication)
  • admin (Cinema admin management)
  • movie (Movie catalog)
  • cinema (Cinema hall information)
  • screen (Screen details)
  • seat (Seat definitions)
  • showtime (Show scheduling)
  • booking (Ticket reservations)
  • booking_seat (Seat-level booking details)
  • payment (Payment processing)
  • payment_refund (Refund tracking)

Feature Tables:
  • seat_type (Seat categories)
  • showtime_seat_availability (Real-time seat status)
  • movie_pricing (Dynamic pricing rules)
  • pricing_tier (Customer tier discounts)
  • promo_code (Promotional codes)
  • refund_policy (Cancellation policies)
  • cancellation_request (Refund requests)
  • booking_status_history (Booking lifecycle)

Analytics Tables:
  • daily_revenue_summary (Daily financial metrics)
  • movie_analytics (Movie performance data)
  • cinema_analytics (Cinema-wise metrics)
  • user_booking_stats (Customer behavior)

Audit & Logging:
  • audit_log (Complete change history)
  • user_activity_log (User action tracking)

═══════════════════════════════════════════════════════════════════════════════

KEY FEATURES & DEMONSTRATIONS
==============================

1. REAL-TIME SEAT MANAGEMENT
   ─────────────────────────
   Feature: Dynamic seat availability tracking
   SQL Pattern: 
   
   SELECT * FROM get_available_seats(showtime_id);
   
   Demonstrates:
   • JOIN operations
   • Filtering with WHERE clauses
   • Function-based queries

2. BUSINESS LOGIC IN DATABASE
   ──────────────────────────
   Feature: Booking creation with automatic refund calculation
   SQL Pattern:
   
   SELECT * FROM create_booking(
       'user@email.com',
       showtime_id,
       ARRAY[1, 2, 3],  -- seat IDs
       'PROMO_CODE'
   );
   
   Demonstrates:
   • Procedural logic using PL/pgSQL
   • Transaction management
   • Constraint validation
   • Error handling

3. ADVANCED ANALYTICS
   ─────────────────
   Feature: Multi-dimensional reporting and KPI tracking
   SQL Pattern:
   
   SELECT * FROM revenue_daily_trend
   ORDER BY revenue_date DESC;
   
   Demonstrates:
   • Window functions (LAG, LEAD)
   • Complex aggregations
   • CTE usage
   • Performance optimization

4. AUDIT TRAIL & COMPLIANCE
   ────────────────────────
   Feature: Complete history of all data changes
   SQL Pattern:
   
   SELECT * FROM audit_log
   WHERE table_name = 'booking'
   AND changed_at >= CURRENT_DATE - INTERVAL '30 days'
   ORDER BY changed_at DESC;
   
   Demonstrates:
   • JSONB storage for versioning
   • Trigger-based automation
   • Time-series data querying

5. DYNAMIC PRICING
   ──────────────
   Feature: Price adjustments based on timing and demand
   Demonstrates:
   • Multi-table relationships
   • Temporal data handling
   • Complex business rules

═══════════════════════════════════════════════════════════════════════════════

SAMPLE INTERVIEW QUESTIONS & ANSWERS
=====================================

Q1: "Explain your database design approach"
────────────────────────────────────────
A: I followed BCNF normalization with separate tables for:
   • Entity separation (Users, Movies, Cinemas)
   • Relationship tables (Bookings, Payments)
   • Type definitions (Seat types, Pricing tiers)
   • Time-series data (Analytics, Activity logs)
   
   This eliminates anomalies and maintains data integrity.

Q2: "How do you handle high-volume concurrent bookings?"
──────────────────────────────────────────────────────
A: Key optimizations:
   • Strategic indexes on frequently queried columns
   • Seat availability partitioning per showtime
   • Transaction isolation for concurrent access
   • Connection pooling in application layer
   • Read replicas for analytics queries
   
   Example query optimization:
   CREATE INDEX idx_seat_availability_showtime 
   ON showtime_seat_availability(showtime_id) 
   WHERE is_booked = FALSE;

Q3: "How do you ensure data accuracy for bookings?"
──────────────────────────────────────────────────
A: Multiple layers:
   1. Database constraints (CHECK, UNIQUE, FOREIGN KEY)
   2. Transaction management with ACID properties
   3. Trigger-based validation
   4. Audit logging for compliance
   
   Example:
   ALTER TABLE booking_seat ADD CONSTRAINT valid_booking
   CHECK (price_per_seat > 0);

Q4: "How do you track and analyze revenue?"
──────────────────────────────────────────
A: Comprehensive analytics using:
   • Materialized views for performance
   • Daily summary tables updated via procedures
   • Window functions for trend analysis
   • Multi-dimensional reporting
   
   Example query calculates revenue trends:
   SELECT revenue_date, net_revenue,
          LAG(net_revenue) OVER (ORDER BY revenue_date)
   FROM revenue_daily_trend;

Q5: "How do you handle cancellations and refunds?"
─────────────────────────────────────────────────
A: Three-step process:
   1. Calculate eligible refund using policy rules
   2. Record refund request with approval workflow
   3. Track refund status and update payment record
   
   Demonstrates understanding of:
   • Business process automation
   • Status tracking and workflows
   • Financial reconciliation

═══════════════════════════════════════════════════════════════════════════════

QUICK REFERENCE: COMMONLY USED QUERIES
======================================

1. Get available seats for a showtime:
   SELECT * FROM get_available_seats(showtime_id);

2. Calculate seat occupancy:
   SELECT get_occupancy_rate(showtime_id);

3. Get top performing movies (last 30 days):
   SELECT * FROM get_top_movies(10, 30);

4. Generate revenue report:
   SELECT * FROM calculate_revenue(start_date, end_date);

5. Get cinema performance metrics:
   SELECT * FROM get_cinema_performance(cinema_name, pincode);

6. User booking recommendations:
   SELECT * FROM get_user_recommendations(user_email, 5);

7. View daily revenue trends:
   SELECT * FROM revenue_daily_trend LIMIT 30;

8. Customer segmentation analysis:
   SELECT * FROM customer_value_segmentation
   ORDER BY lifetime_spent DESC;

9. Movie performance scorecard:
   SELECT * FROM movie_performance_scorecard
   ORDER BY gross_revenue DESC;

10. Refund analysis:
    SELECT * FROM refund_analysis;

═══════════════════════════════════════════════════════════════════════════════

EXECUTION ORDER FOR SETUP
==========================

1. Run: 01_tables.sql
   → Creates core schema and base tables

2. Run: 02_advanced_schema.sql
   → Adds audit, analytics, and feature tables

3. Run: 03_procedures_functions.sql
   → Creates business logic functions and procedures

4. Run: 04_analytics_queries.sql
   → Creates reporting views

5. Run: 05_sample_data.sql
   → Populates test data

═══════════════════════════════════════════════════════════════════════════════

PERFORMANCE TUNING TIPS
=======================

1. Index Strategy:
   ────────────────
   ✓ Index columns used in WHERE clauses
   ✓ Index foreign key columns
   ✓ Use partial indexes for filtered queries
   ✓ Monitor query plans with EXPLAIN
   
   Example:
   EXPLAIN ANALYZE
   SELECT * FROM booking 
   WHERE booking_date >= CURRENT_DATE - 30;

2. Query Optimization:
   ──────────────────
   ✓ Use CTEs for complex logic
   ✓ Prefer window functions over self-joins
   ✓ Aggregate at database level, not application
   ✓ Use LIMIT for large result sets
   
   Good: Window function approach
   SELECT user_email, total_bookings,
          ROW_NUMBER() OVER (ORDER BY total_bookings DESC)
   FROM user_booking_stats;
   
   Bad: Application-level ranking

3. Materialized Views:
   ───────────────────
   ✓ Pre-calculate expensive aggregations
   ✓ Refresh on schedule or event-based
   ✓ Use for reporting dashboards
   
   Example:
   REFRESH MATERIALIZED VIEW daily_revenue_summary;

4. Connection Management:
   ──────────────────────
   ✓ Use connection pooling (HikariCP, pgBouncer)
   ✓ Set appropriate pool size
   ✓ Monitor connection usage

═══════════════════════════════════════════════════════════════════════════════

SECURITY BEST PRACTICES IMPLEMENTED
====================================

1. Input Validation:
   ✓ Email format CHECK constraint
   ✓ Phone number format validation
   ✓ Password complexity requirements
   ✓ Amount and price non-negativity checks

2. Access Control:
   ✓ Role-based user types (ADMIN, USER, SUPPORT_STAFF)
   ✓ Role mapping for fine-grained access
   ✓ Table-level permissions (future implementation)

3. Audit Trail:
   ✓ Complete change history in audit_log
   ✓ User activity tracking
   ✓ Timestamp tracking on all operations
   ✓ IP address logging

4. Data Protection:
   ✓ Password stored (should be hashed in application)
   ✓ Sensitive data in separate tables
   ✓ Refund status tracking
   ✓ Payment gateway transaction IDs

═══════════════════════════════════════════════════════════════════════════════

INTERVIEW TOPICS TO MASTER
===========================

□ Explain the schema design (draw ERD on whiteboard)
□ Walk through booking creation flow
□ Discuss refund policy implementation
□ Explain analytics query optimization
□ Describe audit trail implementation
□ Discuss concurrent booking handling
□ Explain window functions in revenue trending
□ Describe index strategy and why certain indexes
□ Discuss ACID properties and transactions
□ Explain triggers and their business purpose
□ Discuss JSON usage in audit logs
□ Explain role-based access control design

═══════════════════════════════════════════════════════════════════════════════

ADVANCED TOPICS FOR DISCUSSION
==============================

1. SCALABILITY
   • Horizontal scaling strategy
   • Sharding by cinema or date
   • Read replicas for reporting
   • Time-series data handling

2. DATA WAREHOUSE
   • ETL from transactional to analytical database
   • Fact and dimension tables
   • Star schema implementation
   • Incremental loading strategies

3. REAL-TIME FEATURES
   • WebSocket integration for live availability
   • Cache invalidation strategies
   • Event streaming (Kafka)
   • Change Data Capture (CDC)

4. ML INTEGRATION
   • Customer segmentation
   • Recommendation engines
   • Demand forecasting
   • Price optimization

═══════════════════════════════════════════════════════════════════════════════

TROUBLESHOOTING COMMON ISSUES
=============================

Issue: "Deadlock in booking transactions"
Solution: Implement pessimistic locking on seat availability
Code: SELECT * FROM seat FOR UPDATE;

Issue: "Slow analytics queries"
Solution: Use materialized views with scheduled refresh
Code: REFRESH MATERIALIZED VIEW CONCURRENTLY daily_revenue;

Issue: "Inconsistent refund amounts"
Solution: Enforce refund calculations at database level
Code: Use procedures instead of application logic

Issue: "Audit log growing too large"
Solution: Archive old records to separate table
Code: Partitioning by date on audit_log

═══════════════════════════════════════════════════════════════════════════════

FUTURE ENHANCEMENTS
====================

1. Implement Row-Level Security (RLS)
   - Users see only their own bookings
   - Admins see only their cinema data

2. Add temporal tables
   - Track all historical changes
   - Time-travel queries

3. Implement full-text search
   - Movie search
   - Activity log search

4. Add machine learning models
   - Price optimization
   - Demand forecasting
   - Customer churn prediction

5. Implement CDC (Change Data Capture)
   - Real-time data sync
   - Event-driven architecture

6. Add GraphQL API layer
   - Complex query optimization
   - Client-specific data fetching

═══════════════════════════════════════════════════════════════════════════════

KEY METRICS TO TRACK
====================

Financial Metrics:
  • Gross Revenue
  • Net Revenue (after refunds)
  • Revenue per Show
  • Average Booking Value
  • Refund Rate %

Operational Metrics:
  • Occupancy Rate %
  • Bookings per Day
  • Cancellation Rate %
  • Payment Success Rate %

Customer Metrics:
  • Customer Lifetime Value (CLV)
  • Customer Acquisition Cost (CAC)
  • Repeat Booking Rate
  • Average Booking Value
  • Customer Segmentation

Marketing Metrics:
  • Promo Code Utilization
  • Discount Impact on Revenue
  • Customer Tier Distribution
  • Genre Preference by Customer

═══════════════════════════════════════════════════════════════════════════════

RECOMMENDED RESOURCES FOR FURTHER LEARNING
==========================================

1. Advanced SQL:
   • "Advanced SQL Window Functions" - Mode Analytics
   • PostgreSQL Official Documentation
   • "SQL Performance Explained" - Markus Winand

2. Database Design:
   • "Database Design Manual" - Lightstone & Teorey
   • "Relational Database Design Clearly Explained"

3. PostgreSQL Specific:
   • "PostgreSQL 14 Internal" - Suzuki
   • PostgreSQL Performance Blog

4. Data Warehousing:
   • "The Data Warehouse Toolkit" - Ralph Kimball
   • "Fundamentals of Data Engineering"

═══════════════════════════════════════════════════════════════════════════════

DEPLOYMENT CHECKLIST
====================

Before going to production:

□ Run VACUUM and ANALYZE on all tables
□ Check for missing indexes using pg_stat_statements
□ Set up automated backups
□ Configure WAL archiving
□ Set up replication
□ Configure monitoring and alerting
□ Implement connection pooling
□ Set up log rotation
□ Document all procedures
□ Create runbooks for common operations
□ Set up disaster recovery plan
□ Test failover procedures
□ Review security policies
□ Set up audit log retention policy

═══════════════════════════════════════════════════════════════════════════════

For any questions or improvements, refer to the inline comments in each SQL file.

Happy learning and good luck with your placements! 🎬🚀
*/

-- ============================================================================
-- QUICK START COMMANDS
-- ============================================================================

-- View total revenue trend
-- SELECT * FROM revenue_daily_trend LIMIT 30;

-- Get top movies this month
-- SELECT * FROM movie_performance_scorecard 
-- WHERE days_in_circulation <= 30
-- ORDER BY gross_revenue DESC;

-- Find VIP customers
-- SELECT * FROM customer_value_segmentation
-- WHERE customer_segment = 'VIP'
-- ORDER BY lifetime_spent DESC;

-- Check system health
-- SELECT COUNT(*) as total_bookings,
--        ROUND(AVG(total_amount), 2) as avg_booking_value,
--        SUM(total_amount) as total_revenue
-- FROM booking WHERE booking_status IN ('CONFIRMED', 'REFUNDED');
