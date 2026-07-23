import json
from datetime import timedelta
from pathlib import Path
import pandas as pd
from faker import Faker
import random

# Use a seed for reproducibility
fake = Faker()
Faker.seed(42)

# Project paths
PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = PROJECT_ROOT / "config"
OUTPUT_PATH = PROJECT_ROOT / "data" / "generated"


def load_json(filename):
    """
    Load a JSON configuration file.
    """

    with open(CONFIG_PATH / filename, "r", encoding="utf-8") as file:
        return json.load(file)


def generate_clients():
    """
    Generate client dataframe from config.
    """

    clients = load_json("clients.json")

    return pd.DataFrame(clients)


def generate_locales():
    """
    Generate locale dataframe from config.
    """

    locales = load_json("locales.json")

    return pd.DataFrame(locales)

def generate_translators(number_of_translators=500):

    translators = []

    for i in range(number_of_translators):

        translators.append({
            "translator_id": i + 1,
            "name": fake.name(),
            "email": fake.email(),
            "country": fake.country(),
            "years_experience": random.randint(1, 30)
        })

    return pd.DataFrame(translators)

def generate_translator_locales(translators):
    """
    Assign translators to one primary locale and occasionally
    an additional locale variant of the same language.
    """

    locales = load_json("locales.json")

    translator_locales = []

    for translator_id in translators["translator_id"]:

        # Assign primary locale
        primary_locale = random.choice(locales)

        translator_locales.append(
            {
                "translator_id": translator_id,
                "locale": primary_locale["locale"],
                "is_primary": True
            }
        )

        # Find other locales of the same language
        variants = [
            locale
            for locale in locales
            if (
                locale["language"] == primary_locale["language"]
                and locale["locale"] != primary_locale["locale"]
            )
        ]

        # 20% chance of having another locale variant
        if variants and random.random() < 0.2:

            variant = random.choice(variants)

            translator_locales.append(
                {
                    "translator_id": translator_id,
                    "locale": variant["locale"],
                    "is_primary": False
                }
            )

    return pd.DataFrame(translator_locales)

def generate_translator_specialisations(translators):
    """
    Assign translators to one or more industries.
    """

    industries = load_json("industries.json")

    specialisations = []

    for translator_id in translators["translator_id"]:

        number_of_specialisations = random.randint(1, 3)

        selected_industries = random.sample(
            industries,
            number_of_specialisations
        )

        for industry in selected_industries:
            specialisations.append(
                {
                    "translator_id": translator_id,
                    "industry": industry["name"]
                }
            )

    return pd.DataFrame(specialisations)

def generate_projects(number_of_projects=2500):
    """
    Generate localization projects.
    """

    clients = load_json("clients.json")
    project_types = load_json("project_types.json")

    projects = []

    for project_id in range(1, number_of_projects + 1):

        client = random.choice(clients)
        project_type = random.choice(project_types)

        word_count = random.randint(
            project_type["word_count"]["min"],
            project_type["word_count"]["max"]
        )

        duration_days = random.randint(
            project_type["typical_duration_days"]["min"],
            project_type["typical_duration_days"]["max"]
        )

        start_date = fake.date_between(
            start_date="-1y",
            end_date="today"
        )

        due_date = start_date + timedelta(days=duration_days)

        projects.append(
            {
                "project_id": project_id,
                "client_id": client["id"],
                "project_type": project_type["name"],
                "source_locale": "en-US",
                "word_count": word_count,
                "start_date": start_date,
                "due_date": due_date,
                # Make completed more likely than other statues
                "status": random.choice(
                    [
                        "Completed",
                        "Completed",
                        "Completed",
                        "In Translation",
                        "QA",
                        "Cancelled"
                    ]
                )
            }
        )

    return pd.DataFrame(projects)

def generate_project_locales(projects):
    """
    Assign target locales to projects based on client requirements.
    """

    clients = load_json("clients.json")

    project_locales = []

    # Create quick lookup dictionary
    clients_lookup = {
        client["id"]: client
        for client in clients
    }

    for _, project in projects.iterrows():

        client = clients_lookup[project["client_id"]]

        available_locales = client["locales"]

        # Decide how many locales this project needs
        chance = random.random()

        if chance < 0.5:
            number_of_locales = min(
                random.randint(1, 3),
                len(available_locales)
            )

        elif chance < 0.85:
            number_of_locales = min(
                random.randint(4, 6),
                len(available_locales)
            )

        else:
            number_of_locales = len(available_locales)

        selected_locales = random.sample(
            available_locales,
            number_of_locales
        )

        for locale in selected_locales:
            project_locales.append(
                {
                    "project_id": project["project_id"],
                    "target_locale": locale
                }
            )

    return pd.DataFrame(project_locales)

def generate_project_assignments(project_locales, projects, translator_locales):
    """
    Assign translators and reviewers to project locales.
    """

    project_types = load_json("project_types.json")

    project_type_lookup = {
        project_type["name"]: project_type
        for project_type in project_types
    }

    assignments = []

    for _, project_locale in project_locales.iterrows():

        project = projects[
            projects["project_id"] == project_locale["project_id"]
        ].iloc[0]

        project_type = project_type_lookup[
            project["project_type"]
        ]

        eligible_translators = translator_locales[
            translator_locales["locale"]
            == project_locale["target_locale"]
        ]["translator_id"].tolist()

        if not eligible_translators:
            continue

        # Assign translator
        translator_id = random.choice(
            eligible_translators
        )

        assignments.append(
            {
                "project_id": project_locale["project_id"],
                "target_locale": project_locale["target_locale"],
                "translator_id": translator_id,
                "role": "Translator"
            }
        )

        # Only assign reviewer if QA is required
        if project_type["qa_required"]:

            possible_reviewers = [
                translator
                for translator in eligible_translators
                if translator != translator_id
            ]

            if possible_reviewers:

                reviewer_id = random.choice(
                    possible_reviewers
                )

                assignments.append(
                    {
                        "project_id": project_locale["project_id"],
                        "target_locale": project_locale["target_locale"],
                        "translator_id": reviewer_id,
                        "role": "Reviewer"
                    }
                )

    return pd.DataFrame(assignments)

def generate_qa_results(projects, project_locales):
    """
    Generate QA results for projects that require QA.
    """

    project_types = load_json("project_types.json")

    project_type_lookup = {
        project_type["name"]: project_type
        for project_type in project_types
    }

    qa_results = []

    for _, project_locale in project_locales.iterrows():

        project = projects[
            projects["project_id"] == project_locale["project_id"]
        ].iloc[0]

        project_type = project_type_lookup[
            project["project_type"]
        ]

        # Skip projects without QA
        if not project_type["qa_required"]:
            continue

        # Generate quality metrics
        critical_errors = random.choices(
            [0, 1, 2],
            weights=[0.9, 0.09, 0.01]
        )[0]

        major_errors = random.randint(0, 5)

        minor_errors = random.randint(0, 15)

        issues_found = (
            critical_errors
            + major_errors
            + minor_errors
        )

        # Start with a high score and reduce based on issues
        qa_score = max(
            70,
            round(
                100 - (
                    critical_errors * 10
                    + major_errors * 2
                    + minor_errors * 0.5
                ),
                2
            )
        )

        review_time_hours = round(
            random.uniform(1, 8),
            2
        )

        qa_results.append(
            {
                "project_id": project_locale["project_id"],
                "target_locale": project_locale["target_locale"],
                "qa_score": qa_score,
                "issues_found": issues_found,
                "critical_errors": critical_errors,
                "major_errors": major_errors,
                "minor_errors": minor_errors,
                "review_time_hours": review_time_hours,
                "passed": qa_score >= 95
            }
        )

    return pd.DataFrame(qa_results)


def generate_all_data():

    clients = generate_clients()
    locales = generate_locales()
    translators = generate_translators()
    translator_locales = generate_translator_locales(translators)
    translator_specialisations = generate_translator_specialisations(
        translators
    )
    projects = generate_projects()
    project_locales = generate_project_locales(projects)
    project_assignments = generate_project_assignments(project_locales, projects, translator_locales)
    qa_results = generate_qa_results(projects, project_locales)

    OUTPUT_PATH.mkdir(parents=True, exist_ok=True)

    clients.to_csv(OUTPUT_PATH / "clients.csv", index=False)

    locales.to_csv(OUTPUT_PATH / "locales.csv", index=False)

    translators.to_csv(OUTPUT_PATH / "translators.csv", index=False)

    translator_locales.to_csv(OUTPUT_PATH / "translator_locales.csv", index=False)

    translator_specialisations.to_csv(OUTPUT_PATH / "translator_specialisations.csv", index=False)

    projects.to_csv(OUTPUT_PATH / "projects.csv", index=False)

    project_locales.to_csv(OUTPUT_PATH / "project_locales.csv", index=False)

    project_assignments.to_csv(OUTPUT_PATH / "project_assignments.csv", index=False)

    qa_results.to_csv(OUTPUT_PATH / "qa_results.csv", index=False)

if __name__ == "__main__":
    generate_all_data()