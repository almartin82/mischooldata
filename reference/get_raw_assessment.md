# Download raw assessment data from Michigan DOE

Attempts to download assessment data from Michigan Department of
Education sources. Due to data access limitations, this function may not
be able to download data for all years.

## Usage

``` r
get_raw_assessment(end_year, level = "all")
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24)

- level:

  Level of data to fetch: "all" (default), "state", "district", "school"

## Value

List with state, district, and/or school data frames

## Details

**Important:** Michigan's assessment data is primarily available through
the MI School Data portal (mischooldata.org) which requires interactive
access. For M-STEP data (2015+), use import_local_assessment() with
manually downloaded files.
