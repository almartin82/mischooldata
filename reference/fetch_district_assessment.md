# Get assessment data for a specific district

Convenience function to fetch assessment data for a single district.

## Usage

``` r
fetch_district_assessment(end_year, district_id, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end

- district_id:

  5-digit district ID (e.g., "82015" for Detroit)

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified district

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Detroit Public Schools assessment data
detroit_assess <- fetch_district_assessment(2024, "82015")

# Get Ann Arbor assessment data
aa_assess <- fetch_district_assessment(2024, "17010")
} # }
```
