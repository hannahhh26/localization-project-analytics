from pathlib import Path
from typing import Any, Mapping, Sequence
import re

import pandas as pd

from src.analytics.database import get_connection


PROJECT_ROOT = Path(__file__).resolve().parents[2]
QUERIES_PATH = PROJECT_ROOT / "sql" / "queries.sql"

QUERY_MARKER_PATTERN = re.compile(
    r"^\s*--\s*name:\s*([A-Za-z0-9_]+)\s*$",
    re.MULTILINE,
)


def load_queries() -> dict[str, str]:
    """
    Load all named SQL queries from sql/queries.sql.

    Queries must begin with a marker in this format:

        -- name: query_name

    Returns:
        A dictionary mapping each query name to its SQL statement.

    Raises:
        FileNotFoundError: If sql/queries.sql cannot be found.
        ValueError: If no named queries are found or a query name is duplicated.
    """
    if not QUERIES_PATH.exists():
        raise FileNotFoundError(
            f"SQL queries file not found at: {QUERIES_PATH}"
        )

    sql_content = QUERIES_PATH.read_text(encoding="utf-8")
    matches = list(QUERY_MARKER_PATTERN.finditer(sql_content))

    if not matches:
        raise ValueError(
            "No named SQL queries were found in "
            f"{QUERIES_PATH}. "
            "Add markers using the format '-- name: query_name'."
        )

    queries: dict[str, str] = {}

    for index, match in enumerate(matches):
        query_name = match.group(1)

        query_start = match.end()
        query_end = (
            matches[index + 1].start()
            if index + 1 < len(matches)
            else len(sql_content)
        )

        query_sql = sql_content[query_start:query_end].strip()

        if query_name in queries:
            raise ValueError(
                f"Duplicate SQL query name found: '{query_name}'"
            )

        if not query_sql:
            raise ValueError(
                f"SQL query '{query_name}' does not contain any SQL."
            )

        queries[query_name] = query_sql

    return queries


def get_query(query_name: str) -> str:
    """
    Retrieve one named SQL query.

    Args:
        query_name: The name declared after a '-- name:' marker.

    Returns:
        The corresponding SQL statement.

    Raises:
        KeyError: If the requested query does not exist.
    """
    queries = load_queries()

    if query_name not in queries:
        available_queries = ", ".join(sorted(queries))

        raise KeyError(
            f"SQL query '{query_name}' was not found. "
            f"Available queries: {available_queries}"
        )

    return queries[query_name]


def run_query(
    query_name: str,
    params: Mapping[str, Any] | Sequence[Any] | None = None,
) -> pd.DataFrame:
    """
    Execute a named SQL query and return its results as a DataFrame.

    Args:
        query_name: The name declared after a '-- name:' marker.
        params: Optional parameters passed safely to the SQL query.

    Returns:
        A pandas DataFrame containing the query results.
    """
    query = get_query(query_name)

    with get_connection() as connection:
        dataframe = pd.read_sql_query(
            sql=query,
            con=connection,
            params=params,
        )

    return dataframe


def list_queries() -> list[str]:
    """
    Return the names of all available SQL queries.
    """
    return sorted(load_queries())


if __name__ == "__main__":
    available_queries = list_queries()

    print(f"SQL file: {QUERIES_PATH}")
    print("Available named queries:")

    for name in available_queries:
        print(f"- {name}")