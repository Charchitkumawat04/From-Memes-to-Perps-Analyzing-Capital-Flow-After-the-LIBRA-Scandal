WITH json_data AS (
  SELECT
    JSON_PARSE(HTTP_GET('https://api.llama.fi/summary/fees/Hyperliquid')) AS parsed_data
), fees_data_chart AS (
  SELECT
    JSON_EXTRACT(parsed_data, '$.totalDataChartBreakdown') AS breakdown_array
  FROM json_data
), unnested_data AS (
  SELECT
    FROM_UNIXTIME(TRY_CAST(JSON_EXTRACT_SCALAR(item, '$[0]') AS BIGINT)) AS day,
    JSON_EXTRACT(item, '$[1].hyperliquid["Hyperliquid Spot Orderbook"]') AS daily_fees
  FROM fees_data_chart
  CROSS JOIN UNNEST(TRY_CAST(JSON_EXTRACT(breakdown_array, '$') AS ARRAY(JSON))) AS t(item)
), final_data AS (
  SELECT
    day,
    TRY_CAST(daily_fees AS DOUBLE) AS fees,
    LAG(TRY_CAST(daily_fees AS DOUBLE)) OVER (ORDER BY day) AS prev_day_fees,
    AVG(TRY_CAST(daily_fees AS DOUBLE)) OVER (ORDER BY day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS seven_day_ma
  FROM unnested_data
)
SELECT
  day,
  fees AS revenue,
  ROUND(seven_day_ma, 2) * 365 AS annualized_revenue
FROM final_data
WHERE
  day >= TRY_CAST('2025-02-15' AS DATE) AND day <= CAST('2025-02-28' AS TIMESTAMP)
ORDER BY
  day DESC
