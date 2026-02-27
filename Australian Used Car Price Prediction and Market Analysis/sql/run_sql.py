from pathlib import Path
import os
import duckdb

PROJECT_ROOT = Path(__file__).resolve().parents[1]  # project folder
os.chdir(PROJECT_ROOT)

DB_PATH = PROJECT_ROOT / "cars.db"
SQL_PATH = PROJECT_ROOT / "sql" / "merge_datasets.sql"

con = duckdb.connect(str(DB_PATH))
con.execute(SQL_PATH.read_text(encoding="utf-8"))
con.close()

print(f"Ran {SQL_PATH}. Database created/updated: {DB_PATH}")