from pathlib import Path
import ast
import csv
import json
import sqlite3


ROOT = Path(__file__).resolve().parents[2]

DATABASE_PATH = (
    ROOT
    / "data"
    / "database"
    / "localization_operations.db"
)

DATA_PATH = ROOT / "data" / "generated"
CONFIG_PATH = ROOT / "config"


def load_json(filename: str) -> list[dict]:
    file_path = CONFIG_PATH / filename

    with open(file_path, "r", encoding="utf-8") as file:
        return json.load(file)


def load_csv(filename: str) -> list[dict]:
    file_path = DATA_PATH / filename

    with open(
        file_path,
        "r",
        encoding="utf-8",
        newline="",
    ) as file:
        return list(csv.DictReader(file))


def parse_list(value: str) -> list[str]:
    """
    Convert a string representation of a Python list into
    a real Python list.

    Example:
    "['en-GB', 'fr-FR']"
    becomes:
    ['en-GB', 'fr-FR']
    """
    parsed_value = ast.literal_eval(value)

    if not isinstance(parsed_value, list):
        raise ValueError(
            f"Expected a list but received: {value}"
        )

    return parsed_value


def parse_boolean(value: str) -> int:
    """
    Convert common boolean values into SQLite integers.

    True, true and 1 become 1.
    False, false and 0 become 0.
    """
    normalised_value = value.strip().lower()

    if normalised_value in {"true", "1"}:
        return 1

    if normalised_value in {"false", "0"}:
        return 0

    raise ValueError(
        f"Cannot convert value to boolean: {value}"
    )


def import_data() -> None:
    connection = sqlite3.connect(DATABASE_PATH)
    connection.execute("PRAGMA foreign_keys = ON")

    cursor = connection.cursor()

    try:
        # --------------------------------------------------
        # 1. Industries
        # --------------------------------------------------
        industries = load_json("industries.json")

        cursor.executemany(
            """
            INSERT INTO industries (
                industry_id,
                industry_name
            )
            VALUES (?, ?)
            """,
            [
                (
                    int(industry["id"]),
                    industry["name"],
                )
                for industry in industries
            ],
        )

        # --------------------------------------------------
        # 2. Project types
        # --------------------------------------------------
        project_types = load_json(
            "project_types.json"
        )

        cursor.executemany(
            """
            INSERT INTO project_types (
                project_type_id,
                project_type_name
            )
            VALUES (?, ?)
            """,
            [
                (
                    int(project_type["id"]),
                    project_type["name"],
                )
                for project_type in project_types
            ],
        )

        # --------------------------------------------------
        # 3. Locales
        # --------------------------------------------------
        locales = load_csv("locales.csv")

        cursor.executemany(
            """
            INSERT INTO locales (
                locale_id,
                locale_code,
                language,
                region
            )
            VALUES (?, ?, ?, ?)
            """,
            [
                (
                    int(locale["id"]),
                    locale["locale"],
                    locale["language"],
                    locale["region"],
                )
                for locale in locales
            ],
        )

        # Lookup dictionaries convert names and locale codes
        # from the CSV files into database IDs.
        industry_ids = {
            industry["name"]: int(industry["id"])
            for industry in industries
        }

        project_type_ids = {
            project_type["name"]:
                int(project_type["id"])
            for project_type in project_types
        }

        locale_ids = {
            locale["locale"]: int(locale["id"])
            for locale in locales
        }

        # --------------------------------------------------
        # 4. Clients
        # --------------------------------------------------
        clients = load_csv("clients.csv")

        cursor.executemany(
            """
            INSERT INTO clients (
                client_id,
                client_name,
                industry_id,
                annual_project_target
            )
            VALUES (?, ?, ?, ?)
            """,
            [
                (
                    int(client["id"]),
                    client["name"],
                    industry_ids[
                        client["industry"]
                    ],
                    int(
                        client[
                            "annual_project_target"
                        ]
                    ),
                )
                for client in clients
            ],
        )

        # --------------------------------------------------
        # 5. Client locales
        # --------------------------------------------------
        client_locale_rows = []

        for client in clients:
            client_id = int(client["id"])
            locale_codes = parse_list(
                client["locales"]
            )

            for locale_code in locale_codes:
                client_locale_rows.append(
                    (
                        client_id,
                        locale_ids[locale_code],
                    )
                )

        cursor.executemany(
            """
            INSERT INTO client_locales (
                client_id,
                locale_id
            )
            VALUES (?, ?)
            """,
            client_locale_rows,
        )

        # --------------------------------------------------
        # 6. Client project types
        # --------------------------------------------------
        client_project_type_rows = []

        for client in clients:
            client_id = int(client["id"])

            project_type_names = parse_list(
                client["project_types"]
            )

            for project_type_name in (
                project_type_names
            ):
                client_project_type_rows.append(
                    (
                        client_id,
                        project_type_ids[
                            project_type_name
                        ],
                    )
                )

        cursor.executemany(
            """
            INSERT INTO client_project_types (
                client_id,
                project_type_id
            )
            VALUES (?, ?)
            """,
            client_project_type_rows,
        )

        # --------------------------------------------------
        # 7. Translators
        # --------------------------------------------------
        translators = load_csv(
            "translators.csv"
        )

        cursor.executemany(
            """
            INSERT INTO translators (
                translator_id,
                translator_name,
                email,
                country,
                years_experience
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            [
                (
                    int(
                        translator[
                            "translator_id"
                        ]
                    ),
                    translator["name"],
                    translator["email"],
                    translator["country"],
                    int(
                        translator[
                            "years_experience"
                        ]
                    ),
                )
                for translator in translators
            ],
        )

        # --------------------------------------------------
        # 8. Translator locales
        # --------------------------------------------------
        translator_locales = load_csv(
            "translator_locales.csv"
        )

        cursor.executemany(
            """
            INSERT INTO translator_locales (
                translator_id,
                locale_id,
                is_primary
            )
            VALUES (?, ?, ?)
            """,
            [
                (
                    int(row["translator_id"]),
                    locale_ids[row["locale"]],
                    parse_boolean(
                        row["is_primary"]
                    ),
                )
                for row in translator_locales
            ],
        )

        # --------------------------------------------------
        # 9. Translator specialisations
        # --------------------------------------------------
        translator_specialisations = load_csv(
            "translator_specialisations.csv"
        )

        cursor.executemany(
            """
            INSERT INTO translator_specialisations (
                translator_id,
                industry_id
            )
            VALUES (?, ?)
            """,
            [
                (
                    int(row["translator_id"]),
                    industry_ids[
                        row["industry"]
                    ],
                )
                for row
                in translator_specialisations
            ],
        )

        # --------------------------------------------------
        # 10. Projects
        # --------------------------------------------------
        projects = load_csv("projects.csv")

        cursor.executemany(
            """
            INSERT INTO projects (
                project_id,
                client_id,
                project_type_id,
                source_locale_id,
                word_count,
                start_date,
                due_date,
                status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    int(project["project_id"]),
                    int(project["client_id"]),
                    project_type_ids[
                        project["project_type"]
                    ],
                    locale_ids[
                        project["source_locale"]
                    ],
                    int(project["word_count"]),
                    project["start_date"],
                    project["due_date"],
                    project["status"],
                )
                for project in projects
            ],
        )

        # --------------------------------------------------
        # 11. Project locales
        # --------------------------------------------------
        project_locales = load_csv(
            "project_locales.csv"
        )

        cursor.executemany(
            """
            INSERT INTO project_locales (
                project_id,
                locale_id
            )
            VALUES (?, ?)
            """,
            [
                (
                    int(row["project_id"]),
                    locale_ids[
                        row["target_locale"]
                    ],
                )
                for row in project_locales
            ],
        )

        # --------------------------------------------------
        # 12. Project assignments
        # --------------------------------------------------
        project_assignments = load_csv(
            "project_assignments.csv"
        )

        cursor.executemany(
            """
            INSERT INTO project_assignments (
                project_id,
                locale_id,
                translator_id,
                role
            )
            VALUES (?, ?, ?, ?)
            """,
            [
                (
                    int(row["project_id"]),
                    locale_ids[
                        row["target_locale"]
                    ],
                    int(row["translator_id"]),
                    row["role"],
                )
                for row in project_assignments
            ],
        )

        # --------------------------------------------------
        # 13. QA results
        # --------------------------------------------------
        qa_results = load_csv(
            "qa_results.csv"
        )

        cursor.executemany(
            """
            INSERT INTO qa_results (
                project_id,
                locale_id,
                qa_score,
                issues_found,
                critical_errors,
                major_errors,
                minor_errors,
                review_time_hours,
                passed
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    int(row["project_id"]),
                    locale_ids[
                        row["target_locale"]
                    ],
                    float(row["qa_score"]),
                    int(row["issues_found"]),
                    int(
                        row["critical_errors"]
                    ),
                    int(row["major_errors"]),
                    int(row["minor_errors"]),
                    float(
                        row[
                            "review_time_hours"
                        ]
                    ),
                    parse_boolean(
                        row["passed"]
                    ),
                )
                for row in qa_results
            ],
        )

        connection.commit()

        print(
            "Data imported successfully."
        )

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()


if __name__ == "__main__":
    import_data()