# Get available years for Michigan enrollment data

Returns the range of years for which enrollment data can be fetched from
the Michigan Center for Educational Performance and Information (CEPI).

## Usage

``` r
get_available_years()
```

## Value

A list with components:

- min_year:

  Earliest available year (1996)

- max_year:

  Most recent available year (2025)

- description:

  Human-readable description of the date range

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 1996
#> 
#> $max_year
#> [1] 2024
#> 
#> $description
#> [1] "Michigan enrollment data is available from 1996 to 2024"
#> 
```
