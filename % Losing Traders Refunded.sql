SELECT
   SUM(realised_pnl_usd) as total_drawdown,
   100 * CAST(COUNT(CASE WHEN cumulative_pnl_usd >= -110_000_000 THEN trader_id END) AS DOUBLE) / CAST(COUNT(*) AS DOUBLE) as pct_users_refunded
FROM query_4736476
