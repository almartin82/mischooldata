# Read a headcount sheet from the Excel file

Read a headcount sheet from the Excel file

## Usage

``` r
read_headcount_sheet(file_path, sheet_name, level, end_year = 2024)
```

## Arguments

- file_path:

  Path to Excel file

- sheet_name:

  Name of sheet to read

- level:

  Data level (building, district, state)

- end_year:

  School year end (used to determine file format era)

## Value

Data frame
