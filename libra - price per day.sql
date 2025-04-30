WITH libra_trades AS (
  SELECT
    'BUY' AS act_type,
    tx_id,
    block_month,
    block_time,
    token_pair,
    token_bought_symbol,
    token_bought_amount,
    token_sold_symbol,
    token_sold_amount,
    amount_usd,
    trader_id AS trader
  FROM meteora_v2_solana.trades
  WHERE
    block_time > TRY_CAST('2025-02-13 16:19' AS TIMESTAMP)
    AND block_time < TRY_CAST('2025-03-01 16:19' AS TIMESTAMP)
    AND token_bought_mint_address = 'Bo9jh3wsmcC2AjakLWzNmKJ3SgtZmXEcSaW7L2FAvUsU'
  UNION
  SELECT
    'SELL' AS act_type,
    tx_id,
    block_month,
    block_time,
    token_pair,
    token_bought_symbol,
    token_bought_amount,
    token_sold_symbol,
    token_sold_amount,
    amount_usd,
    trader_id AS trader
  FROM meteora_v2_solana.trades
  WHERE
    block_time > TRY_CAST('2025-02-13 16:19' AS TIMESTAMP)
    AND block_time < TRY_CAST('2025-03-01 16:19' AS TIMESTAMP)
    AND token_sold_mint_address = 'Bo9jh3wsmcC2AjakLWzNmKJ3SgtZmXEcSaW7L2FAvUsU'
)
SELECT
  CASE
    WHEN act_type = 'BUY'
    THEN amount_usd / token_bought_amount
    WHEN act_type = 'SELL'
    THEN amount_usd / token_sold_amount
  END AS price,
  block_time
FROM libra_trades
WHERE block_time > TRY_CAST('2025-02-13 16:19' AS TIMESTAMP)
      AND 
      block_time < TRY_CAST('2025-03-01 16:19' AS TIMESTAMP)
ORDER BY
  block_time
