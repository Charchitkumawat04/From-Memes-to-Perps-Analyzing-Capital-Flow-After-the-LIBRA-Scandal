WITH json_data AS (
  SELECT
    JSON_PARSE(HTTP_GET('https://api.llama.fi/overview/derivatives')) AS parsed_data
), total_data_chart_breakdown AS (
  SELECT
    JSON_EXTRACT(parsed_data, '$.totalDataChartBreakdown') AS breakdown_array
  FROM json_data
), unnested_data AS (
  SELECT
    FROM_UNIXTIME(TRY_CAST(JSON_EXTRACT_SCALAR(item, '$[0]') AS BIGINT)) AS day,
    JSON_EXTRACT(item, '$[1]') AS product_volumes_json
  FROM total_data_chart_breakdown
  CROSS JOIN UNNEST(TRY_CAST(JSON_EXTRACT(breakdown_array, '$') AS ARRAY(JSON))) AS t(item)
), expanded_data AS (
  SELECT
    DATE_TRUNC('day', day) AS week_start_date,
    CASE WHEN key IN ('dYdX V3', 'dYdX V4') THEN 'dYdX (V3+V4)' ELSE key END AS product_name,
    TRY_CAST(value AS DOUBLE) AS volume
  FROM unnested_data
  CROSS JOIN UNNEST(TRY_CAST(product_volumes_json AS MAP(VARCHAR, DOUBLE))) AS t(key, value)
), aggregated_data AS (
  SELECT
    week_start_date,
    product_name,
    SUM(volume) AS volume
  FROM expanded_data
  GROUP BY
    week_start_date,
    product_name
), labeled_data AS (
  SELECT
    week_start_date,
    CASE WHEN volume >= 100000000 THEN product_name ELSE 'Other' END AS product_name,
    SUM(volume) AS volume
  FROM aggregated_data
  GROUP BY
    week_start_date,
    CASE WHEN volume >= 100000000 THEN product_name ELSE 'Other' END
), filtered_data AS (
  SELECT
    week_start_date AS week,
    product_name,
    volume
  FROM labeled_data
  WHERE
    product_name <> 'Other'
)
SELECT
  week,
  product_name,
  volume
FROM filtered_data
WHERE
  week BETWEEN CAST('2025-02-15' AS TIMESTAMP) AND CAST('2025-02-28' AS TIMESTAMP)
ORDER BY
  week,
  product_name
