# mischooldata: Fetch and Process Michigan School Data

Downloads and processes school data from the Michigan Center for
Educational Performance and Information (CEPI) via MI School Data.
Provides functions for fetching headcount enrollment data and
transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/mischooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/mischooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- `tidy_enr`:

  Transform wide data to tidy (long) format

- `id_enr_aggs`:

  Add aggregation level flags

- `enr_grade_aggs`:

  Create grade-level aggregations

## Cache functions

- `cache_status`:

  View cached data files

- `clear_cache`:

  Remove cached data files

## ID System

Michigan uses several ID systems:

- District Code: 5 digits (e.g., 82015 = Detroit Public Schools)

- Building Code: 5 digits

- ISD (Intermediate School District) Code: 2 digits

## Data Sources

Data is sourced from the Michigan CEPI MI School Data system:

- MI School Data: <https://www.mischooldata.org/>

- CEPI: <https://www.michigan.gov/cepi>

## Data Availability

Michigan provides enrollment headcount data from 1995-96 to present:

- Era 1 (1995-2012): Legacy format with combined files

- Era 2 (2013-2020): Transitional format with Fall/Spring separation

- Era 3 (2021-present): Current format with standardized columns

## See also

Useful links:

- <https://almartin82.github.io/mischooldata/>

- <https://github.com/almartin82/mischooldata>

- Report bugs at <https://github.com/almartin82/mischooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
