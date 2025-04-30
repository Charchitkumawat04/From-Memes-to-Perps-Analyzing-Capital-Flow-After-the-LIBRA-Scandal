WITH new_tokens_solana AS (
  SELECT
    tx_id
  FROM tokens_solana.transfers
  WHERE
    outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
  GROUP BY
    1
), sol_price AS (
  SELECT
    minute,
    price
  FROM prices.usd
  WHERE
    contract_address IS NULL AND symbol = 'SOL'
), fees AS (
  SELECT
    a.tx_id,
    a.block_time,
    a.address AS tx_signer,
    'Sell' AS action_type,
    balance_change / 1e9 AS total_sol,
    balance_change / 1e9 * price AS total_usd_sol
  FROM solana.account_activity AS a
  LEFT JOIN new_tokens_solana AS n
    ON n.tx_id = a.tx_id
  LEFT JOIN sol_price
    ON DATE_TRUNC('minute', a.block_time) = minute
  WHERE
    DATE(a.block_time) >= DATE(TRY_CAST('2025-02-15' AS TIMESTAMP))
    AND DATE(a.block_time) <= DATE(TRY_CAST('2025-02-28' AS TIMESTAMP))
    AND balance_change > 0
    AND a.token_mint_address IS NULL
    AND a.address = 'CebN5WGQ4jvEPvsVU4EoHEpgzq1VV7AbicfhtW4xC9iM'
)
SELECT
  DATE_TRUNC('day', block_time) AS date_time,
  SUM(total_sol) AS total_sol_revenue,
  SUM(total_usd_sol) AS total_sol_revenue_usd,
  SUM(SUM(total_sol)) OVER (ORDER BY DATE_TRUNC('day', block_time)) AS cumulative_volume_sol,
  SUM(SUM(total_usd_sol)) OVER (ORDER BY DATE_TRUNC('day', block_time)) AS cumulative_volume_usd
FROM fees
WHERE
  DATE_TRUNC('day', block_time) >= TRY_CAST('2025-02-15' AS TIMESTAMP)
  AND DATE_TRUNC('day', block_time) <= TRY_CAST('2025-02-28' AS TIMESTAMP)
GROUP BY
  DATE_TRUNC('day', block_time)
ORDER BY
  DATE_TRUNC('day', block_time) DESC
