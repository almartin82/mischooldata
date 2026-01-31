# Get available assessment years

Returns information about which years of assessment data are available
from the Michigan Department of Education.

## Usage

``` r
get_available_assessment_years()
```

## Value

A list with components:

- years:

  Vector of available years

- min_year:

  Earliest available year

- max_year:

  Most recent available year

- gap_years:

  Years with no data (2020)

- note:

  Description of data availability

## Details

Assessment history:

- **MEAP** (2007-2014): Michigan Educational Assessment Program

- **M-STEP** (2015-present): Michigan Student Test of Educational
  Progress

- **2020**: No data due to COVID-19 pandemic testing waiver

## Examples

``` r
get_available_assessment_years()
#> $years
#>  [1] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2021 2022
#> [16] 2023 2024 2025
#> 
#> $min_year
#> [1] 2007
#> 
#> $max_year
#> [1] 2025
#> 
#> $gap_years
#> [1] 2020
#> 
#> $meap_years
#> [1] 2007 2008 2009 2010 2011 2012 2013 2014
#> 
#> $mstep_years
#>  [1] 2015 2016 2017 2018 2019 2021 2022 2023 2024 2025
#> 
#> $note
#> [1] "2020 assessment data is not available due to COVID-19 testing waiver. MEAP (2007-2014) and M-STEP (2015-present) data available."
#> 
```
