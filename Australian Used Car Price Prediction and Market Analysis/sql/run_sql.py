from pathlib import Path
import duckdb

DB_PATH = Path("cars.db")
SQL_PATH = Path("merge_datasets.sql")

con = duckdb.connect(str(DB_PATH))
con.execute(SQL_PATH.read_text(encoding="utf-8"))
con.close()

print(f"Ran {SQL_PATH} and wrote results into {DB_PATH}")