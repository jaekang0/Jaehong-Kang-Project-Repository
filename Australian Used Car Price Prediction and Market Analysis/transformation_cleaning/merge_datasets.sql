-- Setup
PRAGMA threads=4;

-- Load raw CSVs

DROP TABLE IF EXISTS raw_1;
DROP TABLE IF EXISTS raw_2;
DROP TABLE IF EXISTS raw_3;
DROP TABLE IF EXISTS raw_4;
DROP TABLE IF EXISTS raw_5;

CREATE OR REPLACE TABLE raw_1 AS
SELECT * FROM read_csv_auto('data/raw/AUSTRALIAN CAR PIRCE.csv', HEADER=true);

CREATE OR REPLACE TABLE raw_2 AS
SELECT * FROM read_csv_auto('data/raw/Australian Vehicle Prices.csv', HEADER=true);

CREATE OR REPLACE TABLE raw_3 AS
SELECT * FROM read_csv_auto('data/raw/cars_info.csv', HEADER=true);

CREATE OR REPLACE TABLE raw_4 AS
SELECT * FROM read_csv_auto('data/raw/cars.csv', HEADER=true);

CREATE OR REPLACE TABLE raw_5 AS
SELECT * FROM read_csv_auto('data/raw/cleaneddata.csv', HEADER=true);

-- Describe
DESCRIBE raw_1;
DESCRIBE raw_2;
DESCRIBE raw_3;
DESCRIBE raw_4;
DESCRIBE raw_5;

-- 0) Standardise each dataset into one schema

DROP TABLE IF EXISTS std_1;
DROP TABLE IF EXISTS std_3;
DROP TABLE IF EXISTS std_5;

-- raw_1 -> std_1
CREATE TABLE std_1 AS
SELECT
  'raw_1' AS source,
  NULL::BIGINT AS listing_id,
  NULL::VARCHAR AS title,

  lower(trim(Marks)) AS make,
  lower(trim(Model)) AS model,

  try_cast(Year AS INTEGER) AS year,

  -- Mileage is VARCHAR like "89,811"
  try_cast(regexp_replace(Mileage, '[^0-9]', '', 'g') AS BIGINT) AS kms,

  try_cast("Price($)" AS DOUBLE) AS price,

  "Body Type" AS body_type,
  Transmission AS transmission,
  "Fuel Type" AS fuel_type,

  -- Engine Size like "2.0L"
  try_cast(regexp_replace("Engine Size", '[^0-9.]', '', 'g') AS DOUBLE) AS engine_l,

  NULL::VARCHAR AS drive_type,

  City AS location,
  NULL::VARCHAR AS state,

  "Car Type" AS used_or_new,   -- Used/Demo
  NULL::VARCHAR AS status,

  NULL::VARCHAR AS variant,
  NULL::VARCHAR AS series,
  NULL::BIGINT   AS cc,
  NULL::VARCHAR AS color,
  NULL::BIGINT AS seats
FROM raw_1;


-- raw_3 -> std_3
-- raw_3 has numeric Price/Kilometers already
CREATE TABLE std_3 AS
SELECT
  'raw_3' AS source,
  ID AS listing_id,
  Name AS title,

  lower(trim(Brand)) AS make,
  lower(trim(Model)) AS model,

  try_cast(Year AS INTEGER) AS year,
  try_cast(Kilometers AS BIGINT) AS kms,
  try_cast(Price AS DOUBLE) AS price,

  Type AS body_type,
  Gearbox AS transmission,
  Fuel AS fuel_type,

  -- CC is cubic centimeters, convert to liters as cc/1000
  try_cast(CC AS BIGINT) / 1000.0 AS engine_l,

  NULL::VARCHAR AS drive_type,

  NULL::VARCHAR AS location,
  NULL::VARCHAR AS state,

  Status AS used_or_new,
  Status AS status,

  Variant AS variant,
  Series AS series,
  CC AS cc,
  Color AS color,
  "Seating Capacity" AS seats
FROM raw_3;


-- raw_5 -> std_5
CREATE TABLE std_5 AS
SELECT
  'raw_5' AS source,
  NULL::BIGINT AS listing_id,
  Title AS title,

  lower(trim(Brand)) AS make,
  lower(trim(Model)) AS model,

  try_cast(Year AS INTEGER) AS year,

  try_cast(regexp_replace(Kilometres, '[^0-9]', '', 'g') AS BIGINT) AS kms,

  -- Price is VARCHAR in raw_5, strip $ and commas etc.
  try_cast(regexp_replace(Price, '[^0-9.]', '', 'g') AS DOUBLE) AS price,

  BodyType AS body_type,
  Transmission AS transmission,
  FuelType AS fuel_type,

  try_cast(Engine AS DOUBLE) AS engine_l,

  DriveType AS drive_type,

  Location AS location,
  States AS state,

  UsedOrNew AS used_or_new,
  NULL::VARCHAR AS status,

  NULL::VARCHAR AS variant,
  NULL::VARCHAR AS series,
  try_cast(regexp_replace(CylindersinEngine, '[^0-9]', '', 'g') AS BIGINT) AS cc, -- not really cc; keep numeric if present
  NULL::VARCHAR AS color,
  NULL::BIGINT AS seats
FROM raw_5;


-- 1) Merge (stack)

DROP TABLE IF EXISTS cars_all;

CREATE TABLE cars_all AS
SELECT * FROM std_1
UNION ALL
SELECT * FROM std_3
UNION ALL
SELECT * FROM std_5;


-- 2) Quick checks (run after merge)

-- Row counts by source
SELECT source, COUNT(*) AS rows
FROM cars_all
GROUP BY source
ORDER BY rows DESC;

-- Basic sanity ranges
SELECT
  MIN(year) AS min_year, MAX(year) AS max_year,
  MIN(kms) AS min_kms,   MAX(kms) AS max_kms,
  MIN(price) AS min_price, MAX(price) AS max_price
FROM cars_all;

-- Nulls in key fields
SELECT
  source,
  SUM(make IS NULL OR make='') AS null_make,
  SUM(model IS NULL OR model='') AS null_model,
  SUM(year IS NULL) AS null_year,
  SUM(kms IS NULL) AS null_kms,
  SUM(price IS NULL) AS null_price
FROM cars_all
GROUP BY source
ORDER BY source;


-- 3) Clean + dedupe

DROP TABLE IF EXISTS cars_clean;

CREATE TABLE cars_clean AS
WITH filtered AS (
  SELECT *
  FROM cars_all
  WHERE make IS NOT NULL AND make <> ''
    AND model IS NOT NULL AND model <> ''
    AND year IS NOT NULL AND year BETWEEN 1980 AND EXTRACT(YEAR FROM CURRENT_DATE) + 1
    AND kms IS NOT NULL AND kms BETWEEN 0 AND 1000000
    AND price IS NOT NULL AND price BETWEEN 200 AND 500000
),
deduped AS (
  SELECT
    *,
    row_number() OVER (
      PARTITION BY
        -- if listing_id exists, it should uniquely identify the row:
        COALESCE(CAST(listing_id AS VARCHAR), ''),
        make, model, year, round(kms), round(price)
      ORDER BY source
    ) AS rn
  FROM filtered
)
SELECT
  source, listing_id, title,
  make, model, year, kms, price,
  body_type, transmission, fuel_type,
  engine_l, drive_type,
  location, state,
  used_or_new, status,
  variant, series, cc, color, seats
FROM deduped
WHERE rn = 1;

-- Check final row count
SELECT COUNT(*) AS cleaned_rows FROM cars_clean;


-- 4) Export for modelling

COPY cars_clean TO 'data/processed/cars_merged.parquet' (FORMAT PARQUET);