# Claude Code Instructions for mischooldata

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

------------------------------------------------------------------------

## Package Overview

mischooldata fetches and processes Michigan K-12 enrollment and
assessment data from the Center for Educational Performance and
Information (CEPI). Data is sourced from downloadable Excel files on the
MI School Data website.

## Assessment Data

### Assessment Systems

- **MEAP** (2007-2014): Michigan Educational Assessment Program
- **M-STEP** (2015-present): Michigan Student Test of Educational
  Progress
- **2020**: No data due to COVID-19 testing waiver

### Data Access Limitation

**Important:** Michigan’s M-STEP data (2015+) is served through the MI
School Data portal (mischooldata.org) which uses interactive reports.
The michigan.gov CDN blocks programmatic access to historical files.

For M-STEP data, users must: 1. Download data manually from
<https://www.mischooldata.org/> 2. Use
[`import_local_assessment()`](https://almartin82.github.io/mischooldata/reference/import_local_assessment.md)
to load the downloaded file

### Assessment Functions

- `fetch_assessment(year)` - Attempts to fetch assessment data
- `fetch_assessment_multi(years)` - Fetch multiple years
- [`get_available_assessment_years()`](https://almartin82.github.io/mischooldata/reference/get_available_assessment_years.md) -
  Check available years
- `import_local_assessment(filepath, year)` - Import manually downloaded
  file

### Assessment Proficiency Levels

- **M-STEP**: Not Proficient, Partially Proficient, Proficient, Advanced
- **MEAP (legacy)**: Level 1 (lowest) through Level 4 (highest)

### Assessment Subjects

- ELA (grades 3-8, 11)
- Math (grades 3-8, 11)
- Science (grades 5, 8, 11)
- Social Studies (grades 5, 8, 11)

## Data Sources

### Primary URL

Data files are hosted at:
<https://www.mischooldata.org/student-enrollment-counts-data-files/>

### URL Patterns by Era

- **2021-present**:
  `https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/[YEAR]/`
- **2018-2020**: `https://michigan.gov/documents/cepi/`
- **1996-2017**:
  `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/[YEAR]/`

### Note on Downloads

The michigan.gov server blocks requests without a browser-like
User-Agent header. All download functions include proper headers.

## Available Years

- **Min Year**: 1996 (1995-96 school year)
- **Max Year**: 2025 (2024-25 school year)

Year refers to the END of the school year (e.g., 2024 = 2023-24 school
year).

## Available Subgroups

### Demographics

- `white` - White
- `black` - Black/African American
- `hispanic` - Hispanic/Latino
- `asian` - Asian
- `native_american` - American Indian/Alaska Native
- `pacific_islander` - Hawaiian/Pacific Islander
- `multiracial` - Two or More Races

### Gender

- `male` - Male
- `female` - Female

### Enrollment

- `total_enrollment` - Total K-12 enrollment

### Grade Levels

- `K`, `01`, `02`, `03`, `04`, `05`, `06`, `07`, `08`, `09`, `10`, `11`,
  `12`
- `TOTAL` - All grades combined

## Michigan-Specific Notes

### District/Building Codes

- **District Code**: 5 digits (e.g., 82015 = Detroit Public Schools
  Community District)
- **Building Code**: 5 digits
- **ISD (Intermediate School District) Code**: 2-digit prefix of
  district code

### Key District IDs

- `82015` - Detroit Public Schools Community District (~48k students)
- `33020` - Grand Rapids Public Schools
- `17010` - Ann Arbor Public Schools
- `23010` - Flint Community Schools

### State Enrollment

Michigan has approximately 1.4 million K-12 students. This number has
been declining from ~1.6 million in 2010.

## CRITICAL REQUIREMENTS

### Data Fidelity

**The tidy=TRUE version MUST maintain fidelity to the raw, unprocessed
source file.**

When processing data: 1. Demographics (white, black, hispanic, asian,
native_american, pacific_islander, multiracial) MUST sum to
total_enrollment 2. Male + Female MUST equal total_enrollment 3.
Grade-level sums (K-12) should approximately equal total_enrollment 4.
State totals should be ~1.3-1.5 million (NOT zero, NOT billions)

### Sanity Checks

Before using data, always verify: 1. State total is between 1.3M and
1.5M students 2. Detroit enrollment is between 30k and 60k students 3.
There are 800-900 districts and 3000+ buildings 4. No negative values 5.
No Inf or NaN values

## File Format Changes by Year

### Modern Format (2016+)

- Excel files with 3 header rows to skip
- Column names: “District Code”, “District Name”, “tot_all”, etc.
- Separate sheets for Building/District/ISD/County/State
- Separate sheets for Fall/Spring collection

### Legacy Format (1996-2015)

- Excel files with no header rows to skip
- Column names: “DCODE”, “DNAME”, “tot_all”, etc.
- Similar sheet structure but different naming

### File Extension Note

- Most years: `.xlsx` format
- 2015 (2014-15): `.xlsb` format (may require special handling)

### GIT COMMIT POLICY

- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

------------------------------------------------------------------------

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally
BEFORE opening a PR:

### CI Checks That Must Pass

| Check        | Local Command                                                                  | What It Tests                                  |
|--------------|--------------------------------------------------------------------------------|------------------------------------------------|
| R-CMD-check  | `devtools::check()`                                                            | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pymischooldata.py -v`                                       | Python wrapper works correctly                 |
| pkgdown      | [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html) | Documentation and vignettes render             |

### Quick Commands

``` r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pymischooldata && pytest tests/test_pymischooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify: - \[ \] `devtools::check()` — 0 errors, 0
warnings - \[ \] `pytest tests/test_pymischooldata.py` — all tests
pass - \[ \]
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
— builds without errors - \[ \] Vignettes render (no `eval=FALSE` hacks)

------------------------------------------------------------------------

## Common Issues

### “State total is 0”

This was a bug in early package versions. The fix was to properly read
the State sheet from the Excel file, or create state aggregates by
summing district data.

### “Data has wrong column names”

Different file formats use different column naming conventions. The
`find_col()` helper function handles multiple name patterns.

### “Download failed with 403”

The michigan.gov server requires a browser-like User-Agent header. All
download functions now include:
`Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36`

------------------------------------------------------------------------

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE
network tests.

### Test Categories:

1.  URL Availability - HTTP 200 checks
2.  File Download - Verify actual file (not HTML error)
3.  File Parsing - readxl/readr succeeds
4.  Column Structure - Expected columns exist
5.  get_raw_enr() - Raw data function works
6.  Data Quality - No Inf/NaN, non-negative counts
7.  Aggregation - State total \> 0
8.  Output Fidelity - tidy=TRUE matches raw

### Running Tests:

``` r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework
documentation.

------------------------------------------------------------------------

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with
auto-merge:

``` bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

``` bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass: - R-CMD-check (0 errors, 0
warnings) - Python tests (if py{st}schooldata exists) - pkgdown build
(vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks
pass.

------------------------------------------------------------------------

## README Images from Vignettes (REQUIRED)

**NEVER use `man/figures/` or `generate_readme_figs.R` for README
images.**

README images MUST come from pkgdown-generated vignette output so they
auto-update on merge:

``` markdown
![Chart name](https://almartin82.github.io/{package}/articles/{vignette}_files/figure-html/{chunk-name}-1.png)
```

**Why:** Vignette figures regenerate automatically when pkgdown builds.
Manual `man/figures/` requires running a separate script and is easy to
forget, causing stale/broken images.
