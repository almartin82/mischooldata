# Import local assessment data file

Imports assessment data from a locally downloaded Excel file. Use this
when direct download is not available (M-STEP data).

## Usage

``` r
import_local_assessment(filepath, end_year, level = "all")
```

## Arguments

- filepath:

  Path to the local Excel file

- end_year:

  School year the data represents

- level:

  Level of data: "all", "state", "district", "school"

## Value

Data frame with assessment data

## Details

To download M-STEP data:

1.  Visit https://www.mischooldata.org/

2.  Navigate to Grades 3-8 State Testing or High School State Testing

3.  Use Report Builder to create and export data

4.  Save the exported Excel file

5.  Use this function to import

## Examples

``` r
if (FALSE) { # \dontrun{
# Import manually downloaded M-STEP data
mstep <- import_local_assessment("~/Downloads/mstep_2024.xlsx", 2024)
} # }
```
