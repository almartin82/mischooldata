# Tidy assessment data

Transforms wide assessment data to long format with proficiency_level
column. The wide format has separate columns for each proficiency level
(pct_not_proficient, pct_partially_proficient, pct_proficient,
pct_advanced). The tidy format pivots these into a single
proficiency_level column.

## Usage

``` r
tidy_assessment(df)
```

## Arguments

- df:

  A wide data.frame of processed assessment data

## Value

A long data.frame of tidied assessment data

## Examples

``` r
if (FALSE) { # \dontrun{
wide_data <- fetch_assessment(2024, tidy = FALSE)
tidy_data <- tidy_assessment(wide_data)
} # }
```
