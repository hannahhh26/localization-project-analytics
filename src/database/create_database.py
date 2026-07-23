from pathlib import Path
import sqlite3


ROOT = Path(__file__).resolve().parents[2]

DATABASE_PATH = ROOT / "data" / "database" / "localization_operations.db"
SCHEMA_PATH = ROOT / "sql" / "schema.sql"


def create_database():

    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(DATABASE_PATH)

    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        conn.executescript(f.read())

    conn.commit()
    conn.close()


if __name__ == "__main__":
    create_database()