# Fetch Michigan assessment data

Downloads and returns assessment data from the Michigan Department of
Education. Includes M-STEP (2015-present) and MEAP (2007-2014).

## Usage

``` r
fetch_assessment(end_year, level = "all", tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid range: 2007-2025 (no 2020).

- level:

  Level of data to fetch: "all" (default), "state", "district", "school"

- tidy:

  If TRUE (default), returns data in long (tidy) format with
  proficiency_level column. If FALSE, returns wide format.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with assessment data

## Details

**Important Note:** Michigan serves M-STEP data through an interactive
portal without direct download URLs. This function attempts to access
available historical data, but may not be able to retrieve M-STEP data
for all years. For M-STEP data, consider using
[`import_local_assessment()`](https://almartin82.github.io/mischooldata/reference/import_local_assessment.md)
with manually downloaded files from https://www.mischooldata.org/

Assessment systems:

- **M-STEP** (2015-present): Michigan Student Test of Educational
  Progress

  - Proficiency levels: Not Proficient, Partially Proficient,
    Proficient, Advanced

  - Grades 3-8 and 11 tested in ELA, Math

  - Grades 5, 8, 11 tested in Science and Social Studies

- **MEAP** (2007-2014): Michigan Educational Assessment Program

  - Legacy assessment, data availability may be limited

- **2020**: No data (COVID-19 testing waiver)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 M-STEP assessment data
assess_2024 <- fetch_assessment(2024)

# Get wide format
assess_wide <- fetch_assessment(2024, tidy = FALSE)

# Force fresh download
assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
} # }
```
