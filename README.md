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

**30 years of enrollment data (1996-2025).** 1.4 million students. 880+ districts. Here are fifteen stories hiding in the numbers:

### 1. Detroit's collapse is staggering

Detroit Public Schools Community District has lost over 100,000 students since 2000, now serving under 50,000. This represents one of the most dramatic urban enrollment declines in American education history.

![Detroit decline](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/detroit-decline-1.png)

```r
library(mischooldata)
library(dplyr)

fetch_enr_multi(2000:2025) %>%
  filter(district_id == "82015", subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 2. Statewide enrollment has been declining

Michigan has lost hundreds of thousands of students since 2000, reflecting demographic shifts and economic changes. The state peaked at around 1.7 million K-12 students and now serves approximately 1.4 million.

![State decline](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/state-decline-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 3. Grand Rapids is more diverse than you think

Michigan's second-largest city has become majority-minority, with Hispanic enrollment growing fastest. Grand Rapids Public Schools now reflects a highly diverse student population.

![Grand Rapids diversity](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/gr-diversity-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(grepl("Grand Rapids", district_name), grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))
```

### 4. The Upper Peninsula is emptying out

UP districts have lost 25-40% of students since 2000 as the region's population ages and young families move south. This rural decline mirrors national patterns but is particularly acute in Michigan's northern reaches.

![UP decline](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/up-decline-1.png)

```r
fetch_enr_multi(2000:2025) %>%
  filter(grepl("Marquette|Houghton|Iron Mountain|Menominee", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 5. COVID hit kindergarten hard

Michigan lost nearly 10,000 kindergartners in 2021 and hasn't fully recovered. The pandemic disrupted the transition to formal schooling for thousands of Michigan families.

![COVID kindergarten](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/covid-k-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12"))
```

### 6. Ann Arbor: island of stability

While Detroit hemorrhages students, Ann Arbor maintains around 17,000 and high diversity. The university town's economic stability and educated workforce create a different enrollment trajectory.

![Ann Arbor stable](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/aa-stable-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(grepl("Ann Arbor", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 7. Multiracial enrollment growing fastest

Multiracial students are Michigan's fastest-growing demographic, increasing 31% from 57,291 to 75,055 students since 2018. While overall enrollment declines, multiracial and Hispanic populations continue to grow.

![Multiracial growth](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/multiracial-growth-1.png)

```r
library(mischooldata)
library(dplyr)

enr <- fetch_enr_multi(2018:2025)

enr %>%
  filter(is_state, subgroup == "multiracial", grade_level == "TOTAL") %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
# 2018: 57,291 students → 2025: 75,055 students (+31%)
```

### 8. Largest districts by enrollment

The 10 largest districts represent a mix of urban, suburban, and diverse communities. Detroit remains the largest despite decades of decline.

![Largest districts](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/largest-districts-1.png)

```r
fetch_enr(2025) %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)
```

### 9. Flint's water crisis visible in enrollment

Flint Community Schools lost over 40% of students during and after the water crisis. The crisis accelerated an already declining enrollment as families fled the city.

![Flint crisis](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/flint-crisis-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(grepl("Flint Community", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 10. Oakland County suburbs holding

Oakland County districts like Troy, Rochester, and Novi maintain enrollment while Detroit collapses. These affluent suburbs benefit from strong economies and excellent school reputations.

![Oakland suburbs](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/oakland-suburbs-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(grepl("Troy|Rochester|Novi|Farmington", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 11. Dearborn: Arab American educational hub

Dearborn Public Schools serves one of the largest Arab American communities in the nation. The district maintains stable enrollment with a unique demographic profile.

![Dearborn enrollment](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/dearborn-enrollment-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(grepl("Dearborn", district_name), !grepl("Heights", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 12. Black student enrollment declining

Black student enrollment in Michigan has declined significantly, driven primarily by Detroit's collapse. This demographic shift is reshaping the state's educational landscape.

![Black decline](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/black-decline-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(is_state, subgroup == "black", grade_level == "TOTAL")
```

### 13. Lansing bucking the urban decline

Unlike Detroit and Flint, Lansing School District has maintained relatively stable enrollment. The state capital's diverse economy and state government employment provide a buffer.

![Lansing stable](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/lansing-stable-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(grepl("Lansing School District", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

### 14. High school enrollment shrinking faster

High school grades are shrinking faster than elementary grades statewide, as the birth rate decline from the 2008 recession reaches secondary schools.

![High school vs elementary](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/hs-vs-elem-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "02", "03", "04", "05",
                            "09", "10", "11", "12"))
```

### 15. Demographic transformation: Michigan's changing face

Michigan's racial demographics are shifting dramatically. White student enrollment has declined substantially while Hispanic and multiracial populations grow.

![Demographic shift](https://almartin82.github.io/mischooldata/articles/enrollment-trends_files/figure-html/demographic-shift-1.png)

```r
fetch_enr_multi(2018:2025) %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial"))
```

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
