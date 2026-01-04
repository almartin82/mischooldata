# Michigan School Data Expansion Research

**Last Updated:** 2026-01-04
**Theme Researched:** Graduation/Dropout Rates

## Data Sources Found

### Primary Source: MI School Data Graduation/Dropout Reports

Michigan provides cohort-based graduation and dropout rate data through CEPI (Center for Educational Performance and Information) at MI School Data.

**Main Download Page:** https://www.mischooldata.org/graddropout-rates-data-files/

### Available Data Files by Era

#### Era 1: Modern Excel Format (2019-2024)

| Year | URL | HTTP Status | Format | Notes |
|------|-----|-------------|--------|-------|
| 2024 | `https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/2023-24/2024-Graduation-and-Dropout-Report-with-Subgroups.xlsx` | 200 OK | XLSX (27MB) | Contains 2024 4-yr, 2023 5-yr, 2022 6-yr cohorts |
| 2023 | `https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/2022-23/2023-Graduation-and-Dropout-Report-with-Subgroups.xlsx` | 200 OK | XLSX (28MB) | Contains 2023 4-yr, 2022 5-yr, 2021 6-yr cohorts |
| 2022 | `https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/2021-22/2022-Graduation-and-Dropout-Report-with-Subgroups.xlsx` | 200 OK | XLSX (28MB) | Contains 2022 4-yr, 2021 5-yr, 2020 6-yr cohorts |
| 2021 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2020-21/2020-21_Graduation_Dropout.xlsx` | 200 OK | XLSX (27MB) | Different file naming pattern |
| 2020 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2019-20/2020_graduation_and_dropout_report_with_subgroups.xlsx` | 200 OK | XLSX (27MB) | |
| 2019 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2018-19/1819_Graduation_and_Dropout_Report_with_Subgroups.xlsx` | 200 OK | XLSX (27MB) | Different file naming pattern |

#### Era 2: ZIP-Packaged Excel/XLS Format (2012-2018)

| Year | URL | Format | Notes |
|------|-----|--------|-------|
| 2018 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2018-Graduation-and-Dropout-Report-with-Subgroups.zip` | ZIP | |
| 2017 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2016-17/1617_Graduation_and_Dropout_Report_with_Subgroups.zip` | ZIP | |
| 2016 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2015-16/2016_Graduation_and_Dropout_Report_with_Subgroups.zip` | ZIP | |
| 2015 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2013-15/15_Graduation_and_Dropout_Report_with_Subgroups.zip` | ZIP | |
| 2014 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2012-14/1214_Grad_Drop.zip` | ZIP | |
| 2013 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2011-13/1113_MI_GradDrop_Rate_with_subgroups.zip` | ZIP | |
| 2012 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2010-12/1012_MI_GradDrop_Rate_with_subgroups.zip` | ZIP | |
| 2011 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2009-11/0911_MI_GradDrop_Rate_with_subgroups.zip` | ZIP | |

#### Era 3: Legacy Cohort Data (2007-2010)

| Year | URL | Format |
|------|-----|--------|
| 2010 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2008-10/0810_MI_GradDrop_Rate_with_subgroups.zip` | ZIP |
| 2009 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2007-09/0709_MI_GradDrop_Rate_with_subgroups.zip` | ZIP |
| 2008 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2007-08/0708_MI_GradDrop_Rate.zip` | ZIP |
| 2007 | `https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2006-07/07_MI_GradDrop_wSubgrp.xls` | XLS |

#### Era 4: Pre-Cohort Historical Data (2000-2006) - DBF Format

Historical graduation/dropout data available in DBF (dBASE) format at district and building level.
These use a different calculation methodology (not cohort-based).

---

## Schema Analysis

### Sheet Structure (Modern Files 2019-2024)

Each Excel file contains multiple sheets:

1. `Table of Content` - Navigation
2. `Definitions` - Column definitions
3. `YYYY 4-Yr Grad Drop` - 4-year cohort graduation/dropout rates
4. `YYYY-1 5-Yr Grad Drop` - 5-year cohort rates
5. `YYYY-2 6-Yr Grad Drop` - 6-year cohort rates
6. `YYYY 4-Yr Subgroup` - 4-year rates by demographic subgroups
7. `YYYY-1 5-Yr Subgroup` - 5-year subgroup rates
8. `YYYY-2 6-Yr Subgroup` - 6-year subgroup rates
9. `YYYY 4-Yr Crosstab` - Cross-tabulated data
10. `YYYY-1 5-Yr Crosstab` - 5-year crosstab
11. `YYYY-2 6-Yr Crosstab` - 6-year crosstab

### Main Graduation/Dropout Sheet Columns

**Skip 2 rows** to get column headers.

| Column Name | Description |
|-------------|-------------|
| District / Building Name (Code) | Combined name with code in parentheses |
| Totals - First Time 9th Grade in Fall YYYY | Initial cohort count |
| Totals - (+)Transfers In | Students who transferred into the cohort |
| Totals - (-)Transfers Out & Exempt | Students who transferred out or are exempt |
| Totals - Cohort Size | Final cohort size |
| Cohort Status - Number of On Time Graduates | Graduates within 4/5/6 years |
| Cohort Status - Number of Dropouts | Students who dropped out |
| Cohort Status - Number of Continuing in School | Students still enrolled |
| Cohort Status - Number of Other Completers | GED, HSE, etc. |
| Rates - Graduation Rate | Graduation rate (decimal, e.g., 0.8283) |
| Rates - Dropout Rate | Dropout rate (decimal) |
| ISDCode | Intermediate School District code (2 digits) |
| DistrictCode | District code (5 digits, 00000 for state) |
| BuildingCode | Building code (5 digits, 00000 for state/district) |
| ISDName | ISD name |
| DistrictName | District name |
| BuildingName | Building name |

### Subgroup Sheet Columns

| Column Name | Description |
|-------------|-------------|
| District Name | District name |
| Building Name | Building name |
| Subgroup | Demographic subgroup |
| Cohort Size | Size of subgroup cohort |
| Number of On Time Graduates | Graduates count |
| Number of Dropouts | Dropout count |
| Number Continuing in School | Continuing count |
| Number of Other Completers | Other completers count |
| Graduation Rate | Rate (decimal) |
| Dropout Rate | Rate (decimal) |
| ISDCode | ISD code |
| District Code | District code |
| Building Code | Building code |
| ISDName | ISD name |

### Available Subgroups (2024)

| Subgroup Code | Description |
|---------------|-------------|
| All Students | Total cohort |
| Male | Male students |
| Female | Female students |
| AI/AN | American Indian/Alaska Native |
| Asian | Asian |
| Black | Black/African American |
| NH/PI | Native Hawaiian/Pacific Islander |
| White | White |
| Hispanic | Hispanic/Latino |
| Multiracial | Two or More Races |
| Econ. Dis. | Economically Disadvantaged |
| N_ED | Not Economically Disadvantaged |
| LEP | Limited English Proficient |
| N_LEP | Not LEP |
| Migrant | Migrant students |
| Homeless | Homeless students |
| Stu. w/Dis | Students with Disabilities |
| N_SpecialEd | Not Special Education |
| EMC | Early Middle College |
| Foster | Foster care |
| Military | Military connected |

### Schema Changes Noted

| Era | Changes |
|-----|---------|
| 2019-2024 | Consistent schema, XLSX format |
| 2012-2018 | ZIP packaged, XLS/XLSX inside |
| 2007-2011 | Older XLS format, slightly different column names |
| Pre-2007 | DBF format, different methodology (not cohort-based) |

### ID System

- **ISD Code**: 2 digits (Intermediate School District)
- **District Code**: 5 digits, preserves leading zeros
- **Building Code**: 5 digits, preserves leading zeros
- **State-level**: DistrictCode = 00000, BuildingCode = 00000

### Known Data Issues

1. **Suppression markers**: `< 10` for small counts (privacy protection)
2. **Rates as decimals**: 0.8283 not 82.83%
3. **Multi-row headers**: Skip 2 rows for actual column names
4. **Newlines in column names**: `\r\n` embedded in column headers
5. **Different file naming patterns by year**: No consistent URL pattern

---

## Time Series Heuristics

### State-Level Benchmarks (2024 Data)

| Metric | Value | Expected Range |
|--------|-------|----------------|
| Total Cohort Size | 115,097 | 100,000-130,000 |
| On-Time Graduates | 95,334 | 80,000-100,000 |
| 4-Year Graduation Rate | 82.83% | 78-88% |
| Dropout Rate | 7.68% | 5-12% |
| Continuing in School | 9,431 | 5,000-15,000 |
| Other Completers | 1,211 | 500-2,000 |

### Validation Rules

```r
# State cohort should be 100K-130K students
expect_gt(state_cohort, 100000)
expect_lt(state_cohort, 130000)

# Graduation rate should be 75-90%
expect_gt(grad_rate, 0.75)
expect_lt(grad_rate, 0.90)

# Dropout rate should be 3-15%
expect_gt(dropout_rate, 0.03)
expect_lt(dropout_rate, 0.15)

# Year-over-year graduation rate change < 5 percentage points
expect_lt(abs(current_rate - previous_rate), 0.05)

# Major districts (Detroit) should exist in all years
expect_true("82015" %in% data$district_code)
```

### Key District Validation Points

| District | Code | Expected Cohort | Notes |
|----------|------|-----------------|-------|
| Detroit Public Schools | 82015 | 2,000-5,000 | Largest urban district |
| Grand Rapids Public | 33020 | 800-1,500 | Second largest |
| Ann Arbor Public | 17010 | 400-700 | Major university town |

---

## Recommended Implementation

### Priority: MEDIUM
### Complexity: MEDIUM
### Estimated Files to Modify: 5-6

### Implementation Steps

1. **Create URL mapping function** (`R/get_raw_graduation.R`)
   - Handle 4 different URL/file naming patterns by era
   - Handle ZIP file extraction for 2012-2018
   - Support years 2007-2024

2. **Create raw data download function** (`R/get_raw_graduation.R`)
   - `get_raw_grad(end_year, cohort_type = c("4yr", "5yr", "6yr"))`
   - Download and parse Excel sheets
   - Handle multi-row headers (skip 2 rows)
   - Clean column names (remove `\r\n`)

3. **Create processing function** (`R/process_graduation.R`)
   - `process_grad(raw_data, end_year)`
   - Standardize column names across years
   - Handle suppression markers (`< 10` -> NA)
   - Convert rates to consistent format
   - Separate state/district/building levels

4. **Create tidy function** (`R/tidy_graduation.R`)
   - `tidy_grad(processed_data)`
   - Long format with subgroup column
   - Add aggregation flags (is_state, is_district, is_building)

5. **Create main fetch function** (`R/fetch_graduation.R`)
   - `fetch_grad(end_year, cohort_type = "4yr", tidy = TRUE, use_cache = TRUE)`
   - `fetch_grad_multi(end_years, ...)`

6. **Update NAMESPACE and documentation**

### Proposed Function Signatures

```r
# Main user-facing function
fetch_grad(end_year, cohort_type = "4yr", subgroups = FALSE, tidy = TRUE, use_cache = TRUE)

# Multi-year fetch
fetch_grad_multi(end_years, cohort_type = "4yr", subgroups = FALSE, tidy = TRUE, use_cache = TRUE)

# Internal functions
get_grad_url(end_year)
get_raw_grad(end_year, cohort_type)
process_grad(raw_data, end_year)
process_grad_subgroups(raw_data, end_year)
tidy_grad(processed_data)
```

---

## Test Requirements

### Raw Data Fidelity Tests Needed

```r
test_that("2024 state graduation rate matches raw Excel", {
  skip_if_offline()
  data <- fetch_grad(2024, tidy = FALSE)
  state <- data[data$district_code == "00000", ]
  # Raw Excel value: 0.8283
  expect_equal(state$graduation_rate, 0.8283, tolerance = 0.0001)
})

test_that("2024 state cohort size matches raw Excel", {
  skip_if_offline()
  data <- fetch_grad(2024, tidy = FALSE)
  state <- data[data$district_code == "00000", ]
  # Raw Excel value: 115097
  expect_equal(state$cohort_size, 115097)
})

test_that("2019 state graduation rate matches raw Excel", {
  skip_if_offline()
  data <- fetch_grad(2019, tidy = FALSE)
  state <- data[data$district_code == "00000", ]
  # Need to verify from 2019 file
})
```

### Data Quality Checks

```r
test_that("No negative graduation rates", {
  data <- fetch_grad(2024)
  expect_true(all(data$graduation_rate >= 0, na.rm = TRUE))
})

test_that("Graduation rate <= 1.0", {
  data <- fetch_grad(2024)
  expect_true(all(data$graduation_rate <= 1.0, na.rm = TRUE))
})

test_that("State total exists for all years", {
  for (year in 2019:2024) {
    data <- fetch_grad(year, tidy = FALSE)
    expect_true(any(data$district_code == "00000"))
  }
})

test_that("Subgroups sum approximately to total", {
  data <- fetch_grad(2024, subgroups = TRUE, tidy = TRUE)
  state <- data[data$is_state & data$subgroup %in% c("Male", "Female"), ]
  total <- data[data$is_state & data$subgroup == "All Students", ]
  # Male + Female should approximately equal All Students
  gender_sum <- sum(state$cohort_size)
  expect_equal(gender_sum, total$cohort_size[[1]], tolerance = 100)
})
```

### LIVE Pipeline Tests

1. URL Availability - All era URLs return 200
2. File Download - Files download completely (not HTML error pages)
3. File Parsing - readxl can read sheets
4. Column Structure - Expected columns exist
5. Year Filtering - Each cohort year extracts correctly
6. Aggregation - State = sum of districts
7. Data Quality - No Inf/NaN, rates in 0-1 range
8. Output Fidelity - tidy=TRUE matches raw

---

## Notes

### CRITICAL: Package Status

**The mischooldata package is currently FAILING R-CMD-check.** Before implementing graduation data, the existing issues must be fixed first.

### Access Method

- Direct HTTPS download
- Requires browser User-Agent header (same as enrollment)
- ZIP files for 2012-2018 era need extraction

### Update Frequency

- Annual release (typically spring following school year end)
- 4-year, 5-year, and 6-year cohort rates released together

### Documentation References

- [Understanding Michigan's Cohort Graduation and Dropout Rates](https://www.michigan.gov/-/media/Project/Websites/cepi/MSDS/Understanding-Michigans-Cohort-GradDrop-Rates.pdf)
- [FAQs of Michigan's Cohort Graduation and Dropout Rates](https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MSDS/FAQs-of-Michigans-Cohort-Graduation-and-Dropout-Rates.pdf)
