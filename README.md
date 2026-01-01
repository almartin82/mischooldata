# mischooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/mischooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/mischooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/mischooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/mischooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/mischooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/mischooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/mischooldata/)** | **[Getting Started](https://almartin82.github.io/mischooldata/articles/quickstart.html)**

Fetch and analyze Michigan school enrollment data from the Center for Educational Performance and Information (CEPI) in R or Python.

## What can you find with mischooldata?

**30 years of enrollment data (1996-2025).** 1.4 million students. 880+ districts. Here are ten stories hiding in the numbers:

---

### 1. Detroit's collapse is staggering

Detroit Public Schools Community District has lost over 100,000 students since 2000, now serving under 50,000.

```r
library(mischooldata)
library(dplyr)

enr <- fetch_enr_multi(c(2000, 2005, 2010, 2015, 2020, 2025))

enr %>%
  filter(is_district, district_id == "82015",
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, district_name, n_students)
```

![Detroit decline](man/figures/detroit-decline.png)

---

### 2. Charter schools now serve 150,000+ students

Michigan has one of the largest charter sectors in the country, heavily concentrated in Detroit and urban areas.

```r
enr_2025 <- fetch_enr(2025)

# Charter enrollment statewide
enr_2025 %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  summarize(
    total_charter = sum(n_students, na.rm = TRUE),
    n_schools = n()
  )
```

![Charter growth](man/figures/charter-growth.png)

---

### 3. Grand Rapids is more diverse than you think

Michigan's second-largest city has become majority-minority, with Hispanic enrollment growing fastest.

```r
enr %>%
  filter(is_district, grepl("Grand Rapids", district_name),
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, subgroup, pct)
```

![Grand Rapids diversity](man/figures/gr-diversity.png)

---

### 4. The Upper Peninsula is emptying out

UP districts have lost 25-40% of students since 2000 as the region's population ages.

```r
up_districts <- c("Marquette", "Houghton", "Iron Mountain", "Menominee")

enr %>%
  filter(is_district, grepl(paste(up_districts, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(district_name) %>%
  mutate(index = n_students / first(n_students) * 100) %>%
  select(end_year, district_name, index)
```

![UP decline](man/figures/up-decline.png)

---

### 5. Kindergarten dropped 7% during COVID

Michigan lost nearly 10,000 kindergartners in 2021 and hasn't fully recovered.

```r
enr <- fetch_enr_multi(2018:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  select(end_year, grade_level, n_students)
```

![COVID kindergarten](man/figures/covid-k.png)

---

### 6. Ann Arbor: island of stability

While Detroit hemorrhages students, Ann Arbor maintains around 17,000 and high diversity.

```r
enr %>%
  filter(is_district, grepl("Ann Arbor", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

![Ann Arbor stability](man/figures/aa-stable.png)

---

### 7. Economic disadvantage varies wildly

Some districts have 90%+ economically disadvantaged students while wealthy suburbs hover around 10%.

```r
enr_2025 %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

![Economic divide](man/figures/econ-divide.png)

---

### 8. English learners concentrated in the southwest

Districts in the southwest corner (Holland, Grand Rapids, Kalamazoo) have the highest EL populations.

```r
enr_2025 %>%
  filter(is_district, subgroup == "lep", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

![EL concentration](man/figures/el-concentration.png)

---

### 9. Flint's water crisis visible in enrollment

Flint Community Schools lost over 40% of students during and after the water crisis.

```r
enr %>%
  filter(is_district, grepl("Flint Community", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

![Flint decline](man/figures/flint-crisis.png)

---

### 10. Suburban Detroit is holding

Oakland County districts like Troy, Rochester, and Novi maintain enrollment while the city collapses.

```r
oakland <- c("Troy", "Rochester", "Novi", "Farmington")

enr %>%
  filter(is_district, grepl(paste(oakland, collapse = "|"), district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, district_name, n_students)
```

![Oakland suburbs](man/figures/oakland-suburbs.png)

---

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
