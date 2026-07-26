from pathlib import Path
import sqlite3


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATABASE_PATH = PROJECT_ROOT / "data" / "database" / "localization_operations.db"


def get_connection() -> sqlite3.Connection:
    """
    Create and return a connection to the localization operations database.

    Returns:
        sqlite3.Connection: An open SQLite database connection.

    Raises:
        FileNotFoundError: If the database file cannot be found.
    """
    if not DATABASE_PATH.exists():
        raise FileNotFoundError(
            f"Database file not found at: {DATABASE_PATH}"
        )

    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row

    return connection


def test_connection() -> None:
    """
    Test the database connection and print the available table names.
    """
    with get_connection() as connection:
        cursor = connection.execute(
            """
            SELECT name
            FROM sqlite_master
            WHERE type = 'table'
            ORDER BY name;
            """
        )

        tables = [row["name"] for row in cursor.fetchall()]

    print(f"Connected successfully to: {DATABASE_PATH}")
    print("Tables found:")

    for table in tables:
        print(f"- {table}")


if __name__ == "__main__":
    test_connection()