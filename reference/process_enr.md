# Process raw CEPI enrollment data

Transforms raw data into a standardized schema combining building,
district, and state data.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  List containing building, district, and state data frames from
  get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns
