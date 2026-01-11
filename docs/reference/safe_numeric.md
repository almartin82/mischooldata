# Convert to numeric, handling suppression markers

Michigan uses various markers for suppressed data (\*, \<, etc.)

## Usage

``` r
safe_numeric(x)
```

## Arguments

- x:

  Vector to convert

## Value

Numeric vector with NA for non-numeric values
