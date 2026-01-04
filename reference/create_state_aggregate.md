# Create state-level aggregate from district data

This is used as a fallback when the Excel file doesn't have a state
sheet.

## Usage

``` r
create_state_aggregate(district_df, end_year)
```

## Arguments

- district_df:

  Processed district data frame

- end_year:

  School year end

## Value

Single-row data frame with state totals
