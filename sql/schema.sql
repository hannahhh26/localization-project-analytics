DROP TABLE IF EXISTS qa_results;
DROP TABLE IF EXISTS project_assignments;
DROP TABLE IF EXISTS project_locales;
DROP TABLE IF EXISTS translator_specialisations;
DROP TABLE IF EXISTS translator_locales;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS translators;
DROP TABLE IF EXISTS client_project_types;
DROP TABLE IF EXISTS client_locales;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS project_types;
DROP TABLE IF EXISTS locales;
DROP TABLE IF EXISTS industries;

PRAGMA foreign_keys = ON;

CREATE TABLE industries (
    industry_id INTEGER PRIMARY KEY,
    industry_name TEXT NOT NULL UNIQUE
);

CREATE TABLE project_types (
    project_type_id INTEGER PRIMARY KEY,
    project_type_name TEXT NOT NULL UNIQUE
);

CREATE TABLE locales (
    locale_id INTEGER PRIMARY KEY,
    locale_code TEXT NOT NULL UNIQUE,
    language TEXT NOT NULL,
    region TEXT NOT NULL
);

CREATE TABLE clients (
    client_id INTEGER PRIMARY KEY,
    client_name TEXT NOT NULL UNIQUE,
    industry_id INTEGER NOT NULL,
    annual_project_target INTEGER NOT NULL
     CHECK (annual_project_target >= 0),
    FOREIGN KEY (industry_id)
        REFERENCES industries(industry_id)
);

CREATE TABLE client_locales (
    client_id INTEGER NOT NULL,
    locale_id INTEGER NOT NULL,

    PRIMARY KEY (client_id, locale_id),

    FOREIGN KEY (client_id)
        REFERENCES clients(client_id),

    FOREIGN KEY (locale_id)
        REFERENCES locales(locale_id)
);


CREATE TABLE client_project_types (
    client_id INTEGER NOT NULL,
    project_type_id INTEGER NOT NULL,

    PRIMARY KEY (client_id, project_type_id),

    FOREIGN KEY (client_id)
        REFERENCES clients(client_id),

    FOREIGN KEY (project_type_id)
        REFERENCES project_types(project_type_id)
);

CREATE TABLE translators (
    translator_id INTEGER PRIMARY KEY,
    translator_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    country TEXT NOT NULL,
    years_experience INT NOT NULL
    CHECK (years_experience >= 0)
);

CREATE TABLE projects (
    project_id INTEGER PRIMARY KEY,
    client_id INTEGER NOT NULL,
    project_type_id INTEGER NOT NULL,
    source_locale_id INTEGER NOT NULL,
    word_count INTEGER NOT NULL
        CHECK (word_count >= 0),
    start_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    status TEXT NOT NULL
        CHECK (
            status IN (
                'Cancelled',
                'Completed',
                'In Translation',
                'QA'
            )
        ),

    FOREIGN KEY (client_id)
        REFERENCES clients(client_id),

    FOREIGN KEY (project_type_id)
        REFERENCES project_types(project_type_id),

    FOREIGN KEY (source_locale_id)
        REFERENCES locales(locale_id),

    CHECK (due_date >= start_date)
);

CREATE TABLE translator_locales (
    translator_id INTEGER NOT NULL,
    locale_id INTEGER NOT NULL,
    is_primary INTEGER NOT NULL
        CHECK (is_primary IN (0, 1)),

    PRIMARY KEY (translator_id, locale_id),

    FOREIGN KEY (translator_id)
        REFERENCES translators(translator_id),

    FOREIGN KEY (locale_id)
        REFERENCES locales(locale_id)
);

CREATE TABLE translator_specialisations (
    translator_id INTEGER NOT NULL,
    industry_id INTEGER NOT NULL,
    PRIMARY KEY (translator_id, industry_id),

    FOREIGN KEY (translator_id)
        REFERENCES translators(translator_id),

    FOREIGN KEY (industry_id)
        REFERENCES industries(industry_id)
);

CREATE TABLE project_locales (
    project_id INTEGER NOT NULL,
    locale_id INTEGER NOT NULL,
    PRIMARY KEY (project_id, locale_id),

    FOREIGN KEY (project_id)
        REFERENCES projects(project_id),

    FOREIGN KEY (locale_id)
        REFERENCES locales(locale_id)
);

CREATE TABLE project_assignments (
    project_id INTEGER NOT NULL,
    locale_id INTEGER NOT NULL,
    translator_id INTEGER NOT NULL,
    role TEXT NOT NULL
        CHECK (
            role IN (
                'Translator',
                'Reviewer'
            )
        ),

    PRIMARY KEY (
        project_id,
        locale_id,
        translator_id,
        role
    ),

    FOREIGN KEY (project_id, locale_id)
        REFERENCES project_locales(project_id, locale_id),

    FOREIGN KEY (translator_id)
        REFERENCES translators(translator_id)
);

CREATE TABLE qa_results (
    project_id INTEGER NOT NULL,
    locale_id INTEGER NOT NULL,
    qa_score REAL NOT NULL
        CHECK (qa_score >= 0 AND qa_score <= 100),
    issues_found INTEGER NOT NULL
        CHECK (issues_found >= 0),
    critical_errors INTEGER NOT NULL
        CHECK (critical_errors >= 0),
    major_errors INTEGER NOT NULL
        CHECK (major_errors >= 0),
    minor_errors INTEGER NOT NULL
        CHECK (minor_errors >= 0),
    review_time_hours REAL NOT NULL
        CHECK (review_time_hours >= 0),
    passed INTEGER NOT NULL
        CHECK (passed IN (0, 1)),

    PRIMARY KEY (project_id, locale_id),

    FOREIGN KEY (project_id, locale_id)
        REFERENCES project_locales(project_id, locale_id)
);

CREATE INDEX idx_clients_industry
ON clients(industry_id);

CREATE INDEX idx_projects_client
ON projects(client_id);

CREATE INDEX idx_projects_project_type
ON projects(project_type_id);

CREATE INDEX idx_projects_source_locale
ON projects(source_locale_id);

CREATE INDEX idx_project_assignments_translator
ON project_assignments(translator_id);

CREATE INDEX idx_project_assignments_project
ON project_assignments(project_id);

CREATE INDEX idx_qa_results_project
ON qa_results(project_id);