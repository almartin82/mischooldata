# mischooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/mischooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/mischooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/mischooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/mischooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/mischooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/mischooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/mischooldata/)** | **[Getting Started](https://almartin82.github.io/mischooldata/articles/quickstart.html)** | **[Enrollment Trends](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html)**

Fetch and analyze Michigan school enrollment data from the Center for Educational Performance and Information (CEPI) in R or Python.

## What can you find with mischooldata?

**30 years of enrollment data (1996-2025).** 1.4 million students. 880+ districts. Here are ten stories hiding in the numbers - see the [Enrollment Trends](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html) vignette for interactive visualizations:

1. [Detroit's collapse is staggering](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#detroits-collapse-is-staggering) - Lost over 100,000 students since 2000
2. [Statewide enrollment has been declining](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#statewide-enrollment-has-been-declining) - Total K-12 enrollment trending downward
3. [Grand Rapids is more diverse than you think](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#grand-rapids-is-more-diverse-than-you-think) - Majority-minority with growing Hispanic enrollment
4. [The Upper Peninsula is emptying out](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#the-upper-peninsula-is-emptying-out) - Lost 25-40% of students since 2000
5. [COVID hit kindergarten hard](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#covid-hit-kindergarten-hard) - Lost nearly 10,000 kindergartners in 2021
6. [Ann Arbor: island of stability](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#ann-arbor-island-of-stability) - Maintains ~17,000 students while Detroit collapses
7. [Hispanic enrollment growing fastest](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#hispanic-enrollment-growing-fastest) - Fastest-growing demographic statewide
8. [Largest districts by enrollment](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#largest-districts-by-enrollment) - Top 10 districts by total enrollment
9. [Flint's water crisis visible in enrollment](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#flints-water-crisis-visible-in-enrollment) - Lost over 40% of students
10. [Oakland County suburbs holding](https://almartin82.github.io/mischooldata/articles/enrollment-trends.html#oakland-county-suburbs-holding) - Troy, Rochester, Novi stable

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/mischooldata")
```

## Quick start

### R

```r
library(mischooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Largest districts
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(15)

# Detroit demographics
enr_2025 %>%
  filter(district_id == "82015", grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

```python
import pymischooldata as mi

# Check available years
years = mi.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2025 = mi.fetch_enr(2025)

# Fetch multiple years
enr_multi = mi.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# State totals
state_total = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
]

# Largest districts
largest = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
].nlargest(15, 'n_students')
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2021-2025** | CEPI Modern | Current format with standardized columns |
| **2013-2020** | CEPI Transitional | Fall/Spring separation |
| **1996-2012** | CEPI Legacy | Combined files with older format |

Data is sourced from the Michigan Center for Educational Performance and Information:
- https://www.mischooldata.org/
- https://www.michigan.gov/cepi

### What's included

- **Levels:** State, District (880+), Building (school)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Special populations:** Economically disadvantaged, English learners, Special education
- **Grade levels:** PK through 12

### Michigan-specific notes

- **District Code:** 5 digits (e.g., 82015 = Detroit Public Schools)
- **Building Code:** 5 digits
- **ISD (Intermediate School District) Code:** 2 digits
- Michigan has a large **charter school sector** (~300 charter schools)
- **Schools of Choice** allow inter-district enrollment
- Detroit has multiple authorizers for charter schools

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
