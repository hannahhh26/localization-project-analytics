-- ============================================================
-- SECTION 1 - DATABASE EXPLORATION
-- ============================================================

-- Query 1: Preview project records
-- name: preview_projects

SELECT *
FROM projects
LIMIT 10;

-- Query 2: Total number of projects
-- name: total_project_count

SELECT
    COUNT(*) AS total_projects
FROM projects;

-- Query 3: Projects by status
-- name: projects_by_status

SELECT
    status,
    COUNT(*) AS project_count
FROM projects
GROUP BY status
ORDER BY project_count DESC;

-- Query 4: Project status percentages
-- name: project_status_summary

SELECT
    status,
    COUNT(*) AS project_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM projects),
        2
    ) AS percentage
FROM projects
GROUP BY status
ORDER BY project_count DESC;

-- ============================================================
-- SECTION 2 - PROJECT PERFORMANCE
-- ============================================================

-- Query 5: Average project word count
-- name: average_project_word_count

SELECT
    ROUND(AVG(word_count), 0) AS average_word_count
FROM projects;

-- Query 6: Minimum, average and maximum project size
-- name: project_size_summary

SELECT
    MIN(word_count) AS smallest_project,
    ROUND(AVG(word_count), 0) AS average_project,
    MAX(word_count) AS largest_project
FROM projects;

-- name: average_word_count_by_project_type

SELECT
    pt.project_type_name AS project_type,
    ROUND(AVG(p.word_count), 0) AS average_word_count
FROM projects p
JOIN project_types pt
    ON p.project_type_id = pt.project_type_id
GROUP BY pt.project_type_name
ORDER BY average_word_count DESC;

-- name: average_target_locales_by_project_type

SELECT
    pt.project_type_name AS project_type,
    ROUND(AVG(locale_count), 1) AS average_target_locales
FROM (
    SELECT
        p.project_id,
        p.project_type_id,
        COUNT(pl.locale_id) AS locale_count
    FROM projects p
    JOIN project_locales pl
        ON p.project_id = pl.project_id
    GROUP BY
        p.project_id,
        p.project_type_id
) t
JOIN project_types pt
    ON t.project_type_id = pt.project_type_id
GROUP BY pt.project_type_name
ORDER BY average_target_locales DESC;

-- Query 7: Average project turnaround time
-- name: average_project_turnaround

SELECT
    ROUND(
        AVG(
            julianday(due_date) -
            julianday(start_date)
        ),
        1
    ) AS average_turnaround_days
FROM projects;

-- Query 8: Average turnaround by project type
-- name: average_turnaround_by_project_type

SELECT
    pt.project_type_name AS project_type,
    ROUND(
        AVG(
            julianday(p.due_date) -
            julianday(p.start_date)
        ),
        1
    ) AS average_turnaround_days
FROM projects AS p
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
GROUP BY pt.project_type_name
ORDER BY average_turnaround_days DESC;

-- Average turnaround by client
-- name: average_turnaround_by_client

SELECT
    c.client_name AS client,
    COUNT(p.project_id) AS project_count,
    ROUND(
        AVG(
            julianday(p.due_date) -
            julianday(p.start_date)
        ),
        1
    ) AS average_turnaround_days
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
GROUP BY
    c.client_id,
    c.client_name
ORDER BY
    average_turnaround_days DESC;

-- Query 9: Number of projects by project type
-- name: projects_by_project_type

SELECT
    pt.project_type_name AS project_type,
    COUNT(*) AS project_count
FROM projects AS p
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
GROUP BY pt.project_type_name
ORDER BY project_count DESC;

-- Query 10: Number of projects by client
-- name: projects_by_client

SELECT
    c.client_name,
    COUNT(*) AS project_count
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
GROUP BY c.client_name
ORDER BY project_count DESC;

-- Query 11: Average project size by client
-- name: average_project_size_by_client

SELECT
    c.client_name,
    ROUND(
        AVG(p.word_count),
        0
    ) AS average_word_count
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
GROUP BY c.client_name
ORDER BY average_word_count DESC;

-- Query 12: Top 10 largest projects
-- name: largest_projects

SELECT
    project_id,
    word_count,
    due_date,
    status
FROM projects
ORDER BY word_count DESC
LIMIT 10;

-- Query 13: Projects with the shortest turnaround time
-- name: shortest_turnaround_projects

SELECT
    p.project_id,
    pt.project_type_name AS project_type,
    julianday(p.due_date) -
    julianday(p.start_date) AS turnaround_days
FROM projects AS p
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
ORDER BY turnaround_days ASC
LIMIT 10;

-- Query 14: Shortest turnaround time by project type
-- name: shortest_turnaround_by_project_type

SELECT
    pt.project_type_name AS project_type,
    ROUND(
        MIN(
            julianday(p.due_date) -
            julianday(p.start_date)
        ),
        1
    ) AS shortest_turnaround_days
FROM projects AS p
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
GROUP BY pt.project_type_name
ORDER BY shortest_turnaround_days DESC;

-- Query 15: Active projects that are overdue
-- name: active_overdue_projects

SELECT
    p.project_id,
    pt.project_type_name AS project_type,
    p.start_date,
    p.due_date,
    p.status,
    CAST(
        julianday('now') - julianday(p.due_date)
        AS INTEGER
    ) AS days_overdue
FROM projects AS p
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
WHERE p.due_date < date('now')
    AND p.status IN ('In Translation', 'QA')
ORDER BY days_overdue DESC;

-- Query 16: Count active overdue projects
-- name: active_overdue_project_count

SELECT
    COUNT(*) AS overdue_project_count
FROM projects
WHERE due_date < date('now')
    AND status IN ('In Translation', 'QA');

-- Query 17: Active overdue projects by project type
-- name: overdue_rate_by_project_type
SELECT
    pt.project_type_name AS project_type,
    COUNT(*) AS active_project_count,
    SUM(
        CASE
            WHEN DATE(p.due_date) < DATE('now') THEN 1
            ELSE 0
        END
    ) AS overdue_project_count,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(p.due_date) < DATE('now') THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        1
    ) AS overdue_rate
FROM projects AS p
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
WHERE p.status IN ('In Translation', 'QA')
GROUP BY pt.project_type_name
ORDER BY
    overdue_rate DESC,
    overdue_project_count DESC;

-- Query 18: Project types with above-average overdue project counts
-- name: above_average_overdue_project_types

WITH overdue_by_type AS (
    SELECT
        pt.project_type_name AS project_type,
        COUNT(*) AS overdue_project_count
    FROM projects AS p
    JOIN project_types AS pt
        ON p.project_type_id = pt.project_type_id
    WHERE p.due_date < date('now')
        AND p.status IN ('In Translation', 'QA')
    GROUP BY pt.project_type_name
)
SELECT
    project_type,
    overdue_project_count
FROM overdue_by_type
WHERE overdue_project_count > (
    SELECT AVG(overdue_project_count)
    FROM overdue_by_type
)
ORDER BY overdue_project_count DESC;

-- Query 19: Active overdue projects by client
-- name: overdue_projects_by_client

SELECT
    c.client_name,
    COUNT(*) AS overdue_project_count
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
WHERE p.due_date < date('now')
    AND p.status IN ('In Translation', 'QA')
GROUP BY c.client_name
ORDER BY overdue_project_count DESC;

-- Query 20: Active overdue rate by client
-- name: overdue_rate_by_client

SELECT
    c.client_name AS client,
    COUNT(*) AS active_project_count,
    SUM(
        CASE
            WHEN DATE(p.due_date) < DATE('now') THEN 1
            ELSE 0
        END
    ) AS overdue_project_count,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(p.due_date) < DATE('now') THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        1
    ) AS overdue_rate
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
WHERE p.status IN ('In Translation', 'QA')
GROUP BY c.client_name
ORDER BY
    overdue_rate DESC,
    overdue_project_count DESC;

-- ============================================================
-- SECTION 3 - CLIENT INSIGHTS
-- ============================================================

-- Query 21: Total word volume by client
-- name: client_word_volume

SELECT
    c.client_name,
    COUNT(*) AS project_count,
    SUM(p.word_count) AS total_word_count,
    ROUND(AVG(p.word_count), 0) AS average_project_size
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
GROUP BY c.client_name
ORDER BY total_word_count DESC;

-- Query 22: Percentage of total word volume by client
-- name: client_share_of_word_volume

SELECT
    c.client_name,
    SUM(p.word_count) AS total_word_count,
    ROUND(
        SUM(p.word_count) * 100.0 /
        (SELECT SUM(word_count) FROM projects),
        2
    ) AS percentage_of_total_words
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
GROUP BY c.client_name
ORDER BY percentage_of_total_words DESC;

-- Query 23: Project type breakdown by client
-- name: client_project_type_breakdown

SELECT
    c.client_name,
    pt.project_type_name AS project_type,
    COUNT(*) AS project_count
FROM projects AS p
JOIN clients AS c
    ON p.client_id = c.client_id
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
GROUP BY
    c.client_name,
    pt.project_type_name
ORDER BY
    c.client_name,
    project_count DESC;

-- Query 24: Most common project type for each client
-- name: most_common_project_type_by_client

WITH client_project_types AS (
    SELECT
        c.client_name,
        pt.project_type_name AS project_type,
        COUNT(*) AS project_count
    FROM projects AS p
    JOIN clients AS c
        ON p.client_id = c.client_id
    JOIN project_types AS pt
        ON p.project_type_id = pt.project_type_id
    GROUP BY
        c.client_name,
        pt.project_type_name
),
ranked_project_types AS (
    SELECT
        client_name,
        project_type,
        project_count,
        ROW_NUMBER() OVER (
            PARTITION BY client_name
            ORDER BY project_count DESC
        ) AS project_type_rank
    FROM client_project_types
)
SELECT
    client_name,
    project_type AS most_common_project_type,
    project_count
FROM ranked_project_types
WHERE project_type_rank = 1
ORDER BY project_count DESC;

-- ============================================================
-- SECTION 4 - TRANSLATOR INSIGHTS
-- ============================================================

-- Query 25: Projects completed by each translator
-- name: completed_projects_by_translator

SELECT
    t.translator_name,
    COUNT(*) AS projects_completed
FROM project_assignments AS pa
JOIN translators AS t
    ON pa.translator_id = t.translator_id
JOIN projects AS p
    ON pa.project_id = p.project_id
WHERE
    pa.role = 'Translator'
    AND p.status = 'Completed'
GROUP BY
    t.translator_id,
    t.translator_name
ORDER BY projects_completed DESC;

-- Query 26: Total words translated by each translator
-- name: translator_word_volume

SELECT
    t.translator_name,
    SUM(p.word_count) AS total_words_translated
FROM project_assignments AS pa
JOIN translators AS t
    ON pa.translator_id = t.translator_id
JOIN projects AS p
    ON pa.project_id = p.project_id
WHERE
    pa.role = 'Translator'
    AND p.status = 'Completed'
GROUP BY
    t.translator_id,
    t.translator_name
ORDER BY total_words_translated DESC;

-- Query 27: Average project size per translator
-- name: average_project_size_by_translator

SELECT
    t.translator_name,
    ROUND(
        AVG(p.word_count),
        0
    ) AS average_project_size
FROM project_assignments AS pa
JOIN translators AS t
    ON pa.translator_id = t.translator_id
JOIN projects AS p
    ON pa.project_id = p.project_id
WHERE
    pa.role = 'Translator'
    AND p.status = 'Completed'
GROUP BY
    t.translator_id,
    t.translator_name
ORDER BY average_project_size DESC;

-- Query 28: Most experienced translators
-- name: most_experienced_translators

SELECT
    translator_name,
    years_experience
FROM translators
ORDER BY years_experience DESC;

-- Query 29: Average QA score by translator
-- name: translator_qa_performance

SELECT
    t.translator_name,
    ROUND(
        AVG(q.qa_score),
        2
    ) AS average_qa_score,
    COUNT(*) AS reviews
FROM qa_results AS q
JOIN project_assignments AS pa
    ON q.project_id = pa.project_id
    AND q.locale_id = pa.locale_id
JOIN translators AS t
    ON pa.translator_id = t.translator_id
WHERE pa.role = 'Translator'
GROUP BY
    t.translator_id,
    t.translator_name
ORDER BY average_qa_score DESC;

-- Query 30: Highest average QA score, minimum 10 reviews
-- name: highest_translator_qa_scores

SELECT
    t.translator_name,
    ROUND(
        AVG(q.qa_score),
        2
    ) AS average_qa_score,
    COUNT(*) AS reviews
FROM qa_results AS q
JOIN project_assignments AS pa
    ON q.project_id = pa.project_id
    AND q.locale_id = pa.locale_id
JOIN translators AS t
    ON pa.translator_id = t.translator_id
WHERE pa.role = 'Translator'
GROUP BY
    t.translator_id,
    t.translator_name
HAVING COUNT(*) >= 10
ORDER BY average_qa_score DESC;

-- Query 31: Translators with no project assignments
-- name: unassigned_translators

SELECT
    t.translator_id,
    t.translator_name,
    t.country,
    t.years_experience
FROM translators AS t
LEFT JOIN project_assignments AS pa
    ON t.translator_id = pa.translator_id
WHERE pa.translator_id IS NULL
ORDER BY
    t.years_experience DESC,
    t.translator_name;

-- Query 32: Translator coverage by locale
-- name: translator_coverage_by_locale

SELECT
    l.locale_code,
    l.language,
    l.region,
    COUNT(tl.translator_id) AS translator_count
FROM locales AS l
LEFT JOIN translator_locales AS tl
    ON l.locale_id = tl.locale_id
GROUP BY
    l.locale_id,
    l.locale_code,
    l.language,
    l.region
ORDER BY translator_count DESC;

-- Query 33: Five locales with the most translators
-- name: locales_with_most_translators

SELECT
    l.locale_code,
    l.language,
    l.region,
    COUNT(tl.translator_id) AS translator_count
FROM locales AS l
LEFT JOIN translator_locales AS tl
    ON l.locale_id = tl.locale_id
GROUP BY
    l.locale_id,
    l.locale_code,
    l.language,
    l.region
ORDER BY translator_count DESC
LIMIT 5;

-- Query 34: Five locales with the fewest translators
-- name: locales_with_fewest_translators

SELECT
    l.locale_code,
    l.language,
    l.region,
    COUNT(tl.translator_id) AS translator_count
FROM locales AS l
LEFT JOIN translator_locales AS tl
    ON l.locale_id = tl.locale_id
GROUP BY
    l.locale_id,
    l.locale_code,
    l.language,
    l.region
ORDER BY translator_count ASC
LIMIT 5;

-- Query 35: Project demand by target locale
-- name: project_demand_by_locale

SELECT
    l.locale_code,
    l.language,
    l.region,
    COUNT(*) AS project_count
FROM project_locales AS pl
JOIN locales AS l
    ON pl.locale_id = l.locale_id
GROUP BY
    l.locale_id,
    l.locale_code,
    l.language,
    l.region
    
-- Query 36: Total word volume by target locale
-- name: word_volume_by_locale

SELECT
    l.locale_code,
    l.language,
    l.region,
    COUNT(*) AS project_count,
    SUM(p.word_count) AS total_word_volume
FROM project_locales AS pl
JOIN locales AS l
    ON pl.locale_id = l.locale_id
JOIN projects AS p
    ON pl.project_id = p.project_id
GROUP BY
    l.locale_id,
    l.locale_code,
    l.language,
    l.region
ORDER BY total_word_volume DESC;

-- Query 37: Translator supply compared with project demand
-- name: locale_supply_and_demand

WITH translator_supply AS (
    SELECT
        l.locale_id,
        COUNT(tl.translator_id) AS translator_count
    FROM locales AS l
    LEFT JOIN translator_locales AS tl
        ON l.locale_id = tl.locale_id
    GROUP BY l.locale_id
),
locale_demand AS (
    SELECT
        pl.locale_id,
        COUNT(*) AS project_count,
        SUM(p.word_count) AS total_word_volume
    FROM project_locales AS pl
    JOIN projects AS p
        ON pl.project_id = p.project_id
    GROUP BY pl.locale_id
)
SELECT
    l.locale_code,
    l.language,
    l.region,
    ts.translator_count,
    COALESCE(ld.project_count, 0) AS project_count,
    COALESCE(ld.total_word_volume, 0) AS total_word_volume,
    ROUND(
        COALESCE(ld.project_count, 0) * 1.0 /
        NULLIF(ts.translator_count, 0),
        2
    ) AS projects_per_translator
FROM locales AS l
LEFT JOIN translator_supply AS ts
    ON l.locale_id = ts.locale_id
LEFT JOIN locale_demand AS ld
    ON l.locale_id = ld.locale_id
ORDER BY projects_per_translator DESC;

-- Query 38: Locales with high project demand per translator
-- name: high_demand_low_supply_locales

WITH translator_supply AS (
    SELECT
        l.locale_id,
        COUNT(tl.translator_id) AS translator_count
    FROM locales AS l
    LEFT JOIN translator_locales AS tl
        ON l.locale_id = tl.locale_id
    GROUP BY l.locale_id
),
locale_demand AS (
    SELECT
        pl.locale_id,
        COUNT(*) AS project_count,
        SUM(p.word_count) AS total_word_volume
    FROM project_locales AS pl
    JOIN projects AS p
        ON pl.project_id = p.project_id
    GROUP BY pl.locale_id
)
SELECT
    l.locale_code,
    l.language,
    l.region,
    ts.translator_count,
    COALESCE(ld.project_count, 0) AS project_count,
    COALESCE(ld.total_word_volume, 0) AS total_word_volume,
    ROUND(
        COALESCE(ld.project_count, 0) * 1.0 /
        NULLIF(ts.translator_count, 0),
        2
    ) AS projects_per_translator
FROM locales AS l
LEFT JOIN translator_supply AS ts
    ON l.locale_id = ts.locale_id
LEFT JOIN locale_demand AS ld
    ON l.locale_id = ld.locale_id
WHERE
    COALESCE(ld.project_count, 0) > 0
    AND ts.translator_count < 20
ORDER BY
    projects_per_translator DESC,
    total_word_volume DESC;

-- ============================================================
-- SECTION 5 - QA INSIGHTS
-- ============================================================

-- name: average_qa_review_time_by_project_type

SELECT
    pt.project_type_name AS project_type,
    ROUND(AVG(q.review_time_hours),2) AS average_review_time_hours
FROM qa_results q
JOIN projects p
    ON q.project_id = p.project_id
JOIN project_types pt
    ON p.project_type_id = pt.project_type_id
GROUP BY pt.project_type_name
ORDER BY average_review_time_hours DESC;

-- Query 39: QA performance by project type
-- name: qa_performance_by_project_type

SELECT
    pt.project_type_name,
    COUNT(*) AS qa_reviews,
    ROUND(AVG(q.qa_score), 2) AS average_qa_score,
    SUM(
        CASE
            WHEN q.passed = 1 THEN 1
            ELSE 0
        END
    ) AS passed_reviews,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN q.passed = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS pass_rate_percentage
FROM qa_results AS q
JOIN projects AS p
    ON q.project_id = p.project_id
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
GROUP BY
    pt.project_type_id,
    pt.project_type_name
ORDER BY pass_rate_percentage ASC;

-- Query 40: QA pass rate by client
-- name: qa_failure_rate_by_client

SELECT
    c.client_name,
    COUNT(*) AS qa_reviews,
    ROUND(AVG(q.qa_score), 2) AS average_qa_score,
    SUM(
        CASE
            WHEN q.passed = 0 THEN 1
            ELSE 0
        END
    ) AS failed_reviews,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN q.passed = 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS failure_rate_percentage
FROM qa_results AS q
JOIN projects AS p
    ON q.project_id = p.project_id
JOIN clients AS c
    ON p.client_id = c.client_id
GROUP BY
    c.client_id,
    c.client_name
ORDER BY
    failure_rate_percentage DESC,
    qa_reviews DESC;

-- Query 41: QA issue severity breakdown
-- name: qa_issue_severity

SELECT
    SUM(critical_errors) AS total_critical_errors,
    SUM(major_errors) AS total_major_errors,
    SUM(minor_errors) AS total_minor_errors,
    SUM(issues_found) AS total_issues,
    ROUND(
        100.0 * SUM(critical_errors) /
        NULLIF(SUM(issues_found), 0),
        2
    ) AS critical_error_percentage,
    ROUND(
        100.0 * SUM(major_errors) /
        NULLIF(SUM(issues_found), 0),
        2
    ) AS major_error_percentage,
    ROUND(
        100.0 * SUM(minor_errors) /
        NULLIF(SUM(issues_found), 0),
        2
    ) AS minor_error_percentage
FROM qa_results;

-- Query 42: Detailed failed QA results
-- name: failed_qa_results

SELECT
    q.project_id,
    c.client_name,
    pt.project_type_name,
    l.locale_code,
    q.qa_score,
    q.issues_found,
    q.critical_errors,
    q.major_errors,
    q.minor_errors,
    q.review_time_hours
FROM qa_results AS q
JOIN projects AS p
    ON q.project_id = p.project_id
JOIN clients AS c
    ON p.client_id = c.client_id
JOIN project_types AS pt
    ON p.project_type_id = pt.project_type_id
JOIN locales AS l
    ON q.locale_id = l.locale_id
WHERE q.passed = 0
ORDER BY
    q.critical_errors DESC,
    q.major_errors DESC,
    q.qa_score ASC;

-- Query 43: Lowest average QA score by translator (Min 10 reviewed assignments)
-- name: lowest_translator_qa_scores

SELECT
    t.translator_name,
    COUNT(*) AS reviewed_assignments,
    ROUND(AVG(q.qa_score), 2) AS average_qa_score,
    SUM(
        CASE
            WHEN q.passed = 0 THEN 1
            ELSE 0
        END
    ) AS failed_reviews
FROM qa_results AS q
JOIN project_assignments AS pa
    ON q.project_id = pa.project_id
    AND q.locale_id = pa.locale_id
JOIN translators AS t
    ON pa.translator_id = t.translator_id
WHERE pa.role = 'Translator'
GROUP BY
    t.translator_id,
    t.translator_name
HAVING COUNT(*) >= 10
ORDER BY average_qa_score ASC;

-- Query 44: QA failure rate by translator
-- name: translator_qa_failure_rates

SELECT
    t.translator_name,
    COUNT(*) AS reviewed_assignments,
    SUM(
        CASE
            WHEN q.passed = 0 THEN 1
            ELSE 0
        END
    ) AS failed_reviews,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN q.passed = 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS failure_rate_percentage
FROM qa_results AS q
JOIN project_assignments AS pa
    ON q.project_id = pa.project_id
    AND q.locale_id = pa.locale_id
JOIN translators AS t
    ON pa.translator_id = t.translator_id
WHERE pa.role = 'Translator'
GROUP BY
    t.translator_id,
    t.translator_name
HAVING COUNT(*) >= 10
ORDER BY
    failure_rate_percentage DESC,
    reviewed_assignments DESC;

-- Query 45: High-volume, high-quality translators
-- name: high_volume_high_quality_translators

SELECT
    t.translator_name,
    COUNT(*) AS reviewed_assignments,
    SUM(p.word_count) AS total_words_translated,
    ROUND(AVG(q.qa_score), 2) AS average_qa_score,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN q.passed = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS pass_rate_percentage
FROM qa_results AS q
JOIN project_assignments AS pa
    ON q.project_id = pa.project_id
    AND q.locale_id = pa.locale_id
JOIN translators AS t
    ON pa.translator_id = t.translator_id
JOIN projects AS p
    ON q.project_id = p.project_id
WHERE
    pa.role = 'Translator'
    AND p.status = 'Completed'
GROUP BY
    t.translator_id,
    t.translator_name
HAVING COUNT(*) >= 10
ORDER BY
    pass_rate_percentage DESC,
    total_words_translated DESC;

-- Query 46: Top three translators per language
-- name: top_translators_by_language
-- Based on average QA score, with at least 5 reviewed assignments
-- in that language

WITH translator_language_performance AS (
    SELECT
        l.language,
        t.translator_id,
        t.translator_name,
        COUNT(*) AS reviewed_assignments,
        SUM(p.word_count) AS total_words_translated,
        ROUND(AVG(q.qa_score), 2) AS average_qa_score,
        ROUND(
            100.0 * SUM(
                CASE
                    WHEN q.passed = 1 THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS pass_rate_percentage
    FROM qa_results AS q
    JOIN project_assignments AS pa
        ON q.project_id = pa.project_id
        AND q.locale_id = pa.locale_id
    JOIN translators AS t
        ON pa.translator_id = t.translator_id
    JOIN locales AS l
        ON q.locale_id = l.locale_id
    JOIN projects AS p
        ON q.project_id = p.project_id
    WHERE pa.role = 'Translator'
    GROUP BY
        l.language,
        t.translator_id,
        t.translator_name
    HAVING COUNT(*) >= 5
),

ranked_translators AS (
    SELECT
        language,
        translator_id,
        translator_name,
        reviewed_assignments,
        total_words_translated,
        average_qa_score,
        pass_rate_percentage,

        ROW_NUMBER() OVER (
            PARTITION BY language
            ORDER BY
                average_qa_score DESC,
                pass_rate_percentage DESC,
                total_words_translated DESC,
                translator_name ASC
        ) AS language_rank

    FROM translator_language_performance
)

SELECT
    language,
    language_rank,
    translator_name,
    reviewed_assignments,
    total_words_translated,
    average_qa_score,
    pass_rate_percentage
FROM ranked_translators
WHERE language_rank <= 3
ORDER BY
    language,
    language_rank;

-- Query 47: Monthly project volume trends
-- name: monthly_project_volume

SELECT
    STRFTIME('%Y-%m', start_date) AS project_month,
    COUNT(*) AS project_count,
    SUM(word_count) AS total_word_volume,
    ROUND(AVG(word_count), 2) AS average_project_size
FROM projects
GROUP BY STRFTIME('%Y-%m', start_date)
ORDER BY project_month;

-- Query 48: Monthly project trends by status
-- name: monthly_project_status_trends

SELECT
    STRFTIME('%Y-%m', start_date) AS project_month,
    status,
    COUNT(*) AS project_count,
    SUM(word_count) AS total_word_volume
FROM projects
GROUP BY
    STRFTIME('%Y-%m', start_date),
    status
ORDER BY
    project_month,
    project_count DESC;

-- ============================================================
-- EXECUTIVE SUMMARY
-- ============================================================

-- Query 49: Overall QA performance
-- name: overall_qa_summary

SELECT
    COUNT(*) AS qa_reviews,
    ROUND(AVG(qa_score), 2) AS average_qa_score,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN passed = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS qa_pass_rate
FROM qa_results;