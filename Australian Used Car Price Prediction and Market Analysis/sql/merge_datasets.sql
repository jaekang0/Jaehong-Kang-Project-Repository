-- Setup
PRAGMA threads=4;

-- Load raw CSVs
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