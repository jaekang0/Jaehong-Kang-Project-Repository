import duckdb
from pathlib import Path
import os

PROJECT_ROOT = Path(__file__).resolve().parents[1]
os.chdir(PROJECT_ROOT)
DB_PATH = PROJECT_ROOT / "cars.db"

con = duckdb.connect(str(DB_PATH))

'''
print("TABLES:", con.sql("SHOW TABLES").fetchall())

tables = ["raw_1", "raw_2", "raw_3", "raw_4", "raw_5"]

# Row counts
for t in tables:
    n = con.sql(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
    print(f"{t}: {n} rows")

# Peek raw_1
print("\nraw_1 sample:")
try:
    # if you have pandas+numpy this prints nicely; otherwise use fetchall
    print(con.sql("SELECT * FROM raw_1 LIMIT 5").df())
except Exception:
    print(con.sql("SELECT * FROM raw_1 LIMIT 5").fetchall())

# Describe columns for each table
for t in tables:
    print(f"\nColumns in {t}:")
    print(con.sql(f"DESCRIBE {t}").fetchall())
'''

print(con.sql("SELECT source, COUNT(*) FROM cars_all GROUP BY source").fetchall())
print(con.sql("SELECT * FROM cars_clean LIMIT 10").fetchall())

con.close()