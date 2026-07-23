import pandas as pd
import random

random.seed(42)

from src.generate_data import *


def test_clients_have_unique_ids():
    clients = generate_clients()

    assert clients["id"].is_unique


def test_translators_have_unique_ids():
    translators = generate_translators()

    assert translators["translator_id"].is_unique


def test_projects_have_valid_clients():

    clients = generate_clients()
    projects = generate_projects()

    assert set(
        projects["client_id"]
    ).issubset(
        set(clients["id"])
    )


def test_projects_have_valid_source_locale():

    projects = generate_projects()

    assert (
        projects["source_locale"]
        == "en-US"
    ).all()


def test_project_locales_match_client_requirements():

    clients = generate_clients()
    projects = generate_projects()
    project_locales = generate_project_locales(projects)

    client_lookup = {
        client["id"]: client["locales"]
        for client in load_json("clients.json")
    }

    merged = project_locales.merge(
        projects,
        on="project_id"
    )

    for _, row in merged.iterrows():

        assert row["target_locale"] in (
            client_lookup[row["client_id"]]
        )


def test_translator_locales_are_valid():

    translators = generate_translators()
    translator_locales = generate_translator_locales(
        translators
    )

    locales = pd.DataFrame(
        load_json("locales.json")
    )

    assert set(
        translator_locales["locale"]
    ).issubset(
        set(locales["locale"])
    )


def test_translator_assignments_are_valid():

    translators = generate_translators()

    translator_locales = generate_translator_locales(
        translators
    )

    projects = generate_projects()

    project_locales = generate_project_locales(
        projects
    )

    assignments = generate_project_assignments(
        project_locales,
        projects,
        translator_locales
    )

    valid_pairs = set(
        zip(
            translator_locales["translator_id"],
            translator_locales["locale"]
        )
    )

    for _, row in assignments.iterrows():

        assert (
            row["translator_id"],
            row["target_locale"]
        ) in valid_pairs


def test_projects_with_qa_generate_results():

    projects = generate_projects()

    project_locales = generate_project_locales(
        projects
    )

    qa_results = generate_qa_results(
        projects,
        project_locales
    )

    project_types = load_json(
        "project_types.json"
    )

    qa_required_types = {
        project_type["name"]
        for project_type in project_types
        if project_type["qa_required"]
    }

    qa_required_projects = set(
        projects[
            projects["project_type"].isin(
                qa_required_types
            )
        ]["project_id"]
    )

    assert set(
        qa_results["project_id"]
    ).issubset(
        qa_required_projects
    )

def test_qa_scores_are_valid():

    projects = generate_projects()

    project_locales = generate_project_locales(
        projects
    )

    qa_results = generate_qa_results(
        projects,
        project_locales
    )

    assert (
        qa_results["qa_score"]
        .between(0, 100)
        .all()
    )


def test_no_empty_generated_tables():

    clients = generate_clients()
    translators = generate_translators()
    projects = generate_projects()

    assert len(clients) > 0
    assert len(translators) > 0
    assert len(projects) > 0