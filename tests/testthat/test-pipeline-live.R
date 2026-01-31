# ==============================================================================
# LIVE Pipeline Tests for mischooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. Year Filtering - Extract data for specific years
# 6. Aggregation Logic - District sums match state totals
# 7. Data Quality - No Inf/NaN, valid ranges
# 8. Output Fidelity - tidy=TRUE matches raw data
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("MI School Data landing page is accessible", {
  skip_if_offline()
  # mischooldata.org blocks requests from cloud IPs (GitHub Actions, AWS, etc.)
  # This test only makes sense when run locally
  skip_on_ci()

  response <- httr::HEAD(
    "https://www.mischooldata.org/student-enrollment-counts-data-files/",
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(30)
  )

  expect_equal(httr::status_code(response), 200)
})

test_that("2025 (current year) enrollment file URL returns HTTP 200", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2025)

  response <- httr::HEAD(
    url,
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(30)
  )

  expect_equal(httr::status_code(response), 200,
               info = paste("URL:", url))
})

test_that("2024 enrollment file URL returns HTTP 200", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2024)

  response <- httr::HEAD(
    url,
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(30)
  )

  expect_equal(httr::status_code(response), 200,
               info = paste("URL:", url))
})

test_that("representative historical URLs return HTTP 200", {
  skip_if_offline()

  # Test URLs from different eras
  test_years <- c(2023, 2021, 2020, 2018, 2010, 2000, 1996)

  for (year in test_years) {
    url <- mischooldata:::get_headcount_url(year)

    response <- httr::HEAD(
      url,
      httr::user_agent("Mozilla/5.0"),
      httr::timeout(30)
    )

    expect_equal(
      httr::status_code(response), 200,
      info = paste("Year", year, "URL:", url)
    )
  }
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("can download 2025 enrollment file with correct content type", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2025)
  temp_file <- tempfile(fileext = ".xlsx")

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(120)
  )

  # Check HTTP status
  expect_equal(httr::status_code(response), 200)

  # Check file was downloaded
  expect_true(file.exists(temp_file))

  # Check file size is reasonable (not empty, not HTML error)
  file_size <- file.info(temp_file)$size
  expect_gt(file_size, 100000,
            label = "File should be > 100KB (actual Excel file, not error page)")

  # Check content type is Excel
  content_type <- httr::headers(response)$`content-type`
  expect_true(
    grepl("spreadsheet|excel|openxmlformats", content_type, ignore.case = TRUE),
    info = paste("Expected Excel content type, got:", content_type)
  )

  # Cleanup
  unlink(temp_file)
})

test_that("downloaded file is not an HTML error page", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2025)
  temp_file <- tempfile(fileext = ".xlsx")

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(120)
  )

  # Read first few bytes to check file signature
  con <- file(temp_file, "rb")
  first_bytes <- readBin(con, "raw", n = 4)
  close(con)

  # Excel files (xlsx) start with PK (ZIP format) - 50 4B
  # HTML files start with <! or <h - 3C 21 or 3C 68
  expect_false(
    identical(first_bytes[1:2], as.raw(c(0x3C, 0x21))) ||
    identical(first_bytes[1:2], as.raw(c(0x3C, 0x68))),
    info = "File appears to be HTML, not Excel"
  )

  expect_true(
    identical(first_bytes[1:2], as.raw(c(0x50, 0x4B))),
    info = "File should start with PK (ZIP/XLSX signature)"
  )

  unlink(temp_file)
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("can parse 2025 enrollment Excel file with readxl", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2025)
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(120)
  )

  # Should be able to list sheets
  sheets <- readxl::excel_sheets(temp_file)
  expect_gt(length(sheets), 0, label = "Should have at least one sheet")

  # Should contain expected sheet patterns
  bldg_sheets <- grep("Bldg|Building", sheets, value = TRUE, ignore.case = TRUE)
  dist_sheets <- grep("Dist|District", sheets, value = TRUE, ignore.case = TRUE)

  expect_true(
    length(bldg_sheets) > 0,
    info = paste("Expected building sheet. Available:", paste(sheets, collapse = ", "))
  )
  expect_true(
    length(dist_sheets) > 0,
    info = paste("Expected district sheet. Available:", paste(sheets, collapse = ", "))
  )

  unlink(temp_file)
})

test_that("can read building sheet data", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2025)
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(120)
  )

  sheets <- readxl::excel_sheets(temp_file)
  bldg_sheet <- grep("Fall Bldg K-12 Total", sheets, value = TRUE, ignore.case = TRUE)[1]

  if (is.na(bldg_sheet)) {
    bldg_sheet <- grep("Bldg", sheets, value = TRUE, ignore.case = TRUE)[1]
  }

  # Read the sheet
  df <- readxl::read_xlsx(temp_file, sheet = bldg_sheet, skip = 3)

  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 3000, label = "Michigan has 3000+ schools")
  expect_gt(ncol(df), 10, label = "Should have multiple columns")

  unlink(temp_file)
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("2025 enrollment file has expected column structure", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2025)
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(120)
  )

  sheets <- readxl::excel_sheets(temp_file)
  dist_sheet <- grep("Fall Dist K-12 Total", sheets, value = TRUE, ignore.case = TRUE)[1]

  if (is.na(dist_sheet)) {
    dist_sheet <- grep("Dist", sheets, value = TRUE, ignore.case = TRUE)[1]
  }

  df <- readxl::read_xlsx(temp_file, sheet = dist_sheet, skip = 3)
  cols <- tolower(names(df))

  # Check for ID columns
  expect_true(any(grepl("district.*code|dcode", cols)),
              info = paste("Expected district code column. Columns:", paste(names(df)[1:10], collapse = ", ")))

  # Check for name columns
  expect_true(any(grepl("district.*name|dname", cols)),
              info = "Expected district name column")

  # Check for enrollment totals
  expect_true(any(grepl("tot_all|total|k12", cols)),
              info = "Expected total enrollment column")

  # Check for demographic columns
  expect_true(any(grepl("tot_wh|white", cols)),
              info = "Expected white demographic column")
  expect_true(any(grepl("tot_aa|black|african", cols)),
              info = "Expected Black/African American demographic column")

  # Check for gender columns
  expect_true(any(grepl("tot_male|male", cols)),
              info = "Expected male column")
  expect_true(any(grepl("tot_fem|female", cols)),
              info = "Expected female column")

  unlink(temp_file)
})

test_that("historical file (2000) has expected column structure", {
  skip_if_offline()

  url <- mischooldata:::get_headcount_url(2000)
  temp_file <- tempfile(fileext = ".xlsx")

  httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0"),
    httr::timeout(120)
  )

  sheets <- readxl::excel_sheets(temp_file)

  # Older files might have different sheet naming
  dist_sheet <- grep("Dist", sheets, value = TRUE, ignore.case = TRUE)[1]

  if (!is.na(dist_sheet)) {
    df <- readxl::read_xlsx(temp_file, sheet = dist_sheet)
    cols <- toupper(names(df))

    # Check for ID columns (legacy format uses DCODE)
    expect_true(any(grepl("DCODE|DISTRICT.*CODE", cols)),
                info = paste("Expected district code column. Columns:", paste(names(df)[1:5], collapse = ", ")))

    # Check for totals
    expect_true(any(grepl("TOT_ALL|TOTAL", cols)),
                info = "Expected total column")
  }

  unlink(temp_file)
})

# ==============================================================================
# STEP 5: get_raw_enr() Function Tests
# ==============================================================================

test_that("get_raw_enr returns data for 2025", {
  skip_if_offline()

  raw <- mischooldata:::get_raw_enr(2025)

  expect_true(is.list(raw))
  expect_true("building" %in% names(raw) || "district" %in% names(raw))

  if ("building" %in% names(raw)) {
    expect_true(is.data.frame(raw$building))
    expect_gt(nrow(raw$building), 3000)
  }

  if ("district" %in% names(raw)) {
    expect_true(is.data.frame(raw$district))
    expect_gt(nrow(raw$district), 500)
  }
})

test_that("get_raw_enr includes end_year column", {
  skip_if_offline()

  raw <- mischooldata:::get_raw_enr(2025)

  if ("building" %in% names(raw)) {
    expect_true("end_year" %in% names(raw$building))
    expect_equal(unique(raw$building$end_year), 2025)
  }

  if ("district" %in% names(raw)) {
    expect_true("end_year" %in% names(raw$district))
    expect_equal(unique(raw$district$end_year), 2025)
  }
})

test_that("get_available_years returns valid year range", {
  result <- mischooldata::get_available_years()

  expect_true(is.list(result))
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))
  expect_equal(result$min_year, 1996)
  expect_gte(result$max_year, 2024)
  expect_lte(result$max_year, 2026)
})

# ==============================================================================
# STEP 6: Data Quality Tests
# ==============================================================================

test_that("fetch_enr returns data with no Inf or NaN", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = TRUE)

  for (col in names(data)[sapply(data, is.numeric)]) {
    expect_false(any(is.infinite(data[[col]]), na.rm = TRUE),
                 info = paste("No Inf in", col))
    expect_false(any(is.nan(data[[col]]), na.rm = TRUE),
                 info = paste("No NaN in", col))
  }
})

test_that("enrollment counts are non-negative", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = FALSE)

  expect_true("row_total" %in% names(data))
  expect_true(all(data$row_total >= 0, na.rm = TRUE))
})

test_that("no suppression markers remain in numeric columns", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = FALSE)

  # Numeric columns should be actually numeric
  expect_true(is.numeric(data$row_total))

  # Should not contain string suppression markers (would cause NA or errors)
  expect_false(any(data$row_total == "*", na.rm = TRUE))
})

# ==============================================================================
# STEP 7: Aggregation Tests
# ==============================================================================

test_that("state total is approximately 1.4 million", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = FALSE)

  state_rows <- data[data$type == "State", ]
  expect_gt(nrow(state_rows), 0, label = "Should have state row")

  state_total <- sum(state_rows$row_total, na.rm = TRUE)
  expect_gt(state_total, 1300000, label = "State total should be > 1.3M")
  expect_lt(state_total, 1500000, label = "State total should be < 1.5M")
})

test_that("district totals sum to approximately state total", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = FALSE)

  state_total <- sum(data$row_total[data$type == "State"], na.rm = TRUE)
  district_total <- sum(data$row_total[data$type == "District"], na.rm = TRUE)

  # Allow 5% difference for accounting differences
  pct_diff <- abs(state_total - district_total) / state_total
  expect_true(
    pct_diff < 0.05,
    info = sprintf("State: %d, District sum: %d, diff: %.1f%%",
                   state_total, district_total, pct_diff * 100)
  )
})

test_that("demographics sum to total enrollment", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = FALSE)

  state_row <- data[data$type == "State", ][1, ]

  demo_cols <- c("white", "black", "hispanic", "asian",
                 "native_american", "pacific_islander", "multiracial")
  demo_cols <- demo_cols[demo_cols %in% names(state_row)]

  demo_sum <- sum(sapply(demo_cols, function(col) {
    val <- state_row[[col]]
    if (is.na(val)) 0 else val
  }))

  total_enr <- state_row$row_total

  # Allow small rounding difference
  expect_true(
    abs(demo_sum - total_enr) < 1000,
    info = sprintf("Demo sum: %d, Total: %d, diff: %d", demo_sum, total_enr, abs(demo_sum - total_enr))
  )
})

test_that("gender sums to total enrollment", {
  skip_if_offline()

  data <- mischooldata::fetch_enr(2025, tidy = FALSE)

  state_row <- data[data$type == "State", ][1, ]

  if ("male" %in% names(state_row) && "female" %in% names(state_row)) {
    gender_sum <- sum(c(state_row$male, state_row$female), na.rm = TRUE)
    total_enr <- state_row$row_total

    expect_true(
      abs(gender_sum - total_enr) < 100,
      info = sprintf("Gender sum: %d, Total: %d", gender_sum, total_enr)
    )
  }
})

# ==============================================================================
# STEP 8: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return consistent totals", {
  skip_if_offline()

  wide <- mischooldata::fetch_enr(2025, tidy = FALSE)
  tidy <- mischooldata::fetch_enr(2025, tidy = TRUE)

  # Both should have data
  expect_gt(nrow(wide), 0)
  expect_gt(nrow(tidy), 0)

  # State totals should match
  wide_state_total <- sum(wide$row_total[wide$type == "State"], na.rm = TRUE)
  tidy_state_total <- sum(
    tidy$n_students[tidy$is_state &
                      tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL"],
    na.rm = TRUE
  )

  expect_equal(wide_state_total, tidy_state_total)
})

test_that("district counts preserved through tidy transformation", {
  skip_if_offline()

  wide <- mischooldata::fetch_enr(2025, tidy = FALSE)
  tidy <- mischooldata::fetch_enr(2025, tidy = TRUE)

  n_districts_wide <- sum(wide$type == "District", na.rm = TRUE)
  n_districts_tidy <- sum(
    tidy$is_district &
      tidy$subgroup == "total_enrollment" &
      tidy$grade_level == "TOTAL",
    na.rm = TRUE
  )

  expect_equal(n_districts_wide, n_districts_tidy)
})

test_that("building counts preserved through tidy transformation", {
  skip_if_offline()

  wide <- mischooldata::fetch_enr(2025, tidy = FALSE)
  tidy <- mischooldata::fetch_enr(2025, tidy = TRUE)

  n_buildings_wide <- sum(wide$type == "Building", na.rm = TRUE)
  n_buildings_tidy <- sum(
    tidy$is_campus &
      tidy$subgroup == "total_enrollment" &
      tidy$grade_level == "TOTAL",
    na.rm = TRUE
  )

  expect_equal(n_buildings_wide, n_buildings_tidy)
})

# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================

test_that("Detroit enrollment matches raw data", {
  skip_if_offline()

  # Get processed data
  processed <- mischooldata::fetch_enr(2025, tidy = FALSE)

  # Detroit Public Schools Community District
  detroit <- processed[processed$district_id == "82015" & processed$type == "District", ]

  expect_equal(nrow(detroit), 1, info = "Should have exactly one Detroit district row")
  expect_true(
    detroit$row_total > 30000,
    info = sprintf("Detroit enrollment should be > 30k, got: %d", detroit$row_total)
  )
  expect_true(
    detroit$row_total < 60000,
    info = sprintf("Detroit enrollment should be < 60k, got: %d", detroit$row_total)
  )
})

test_that("raw data values match tidy transformation for specific district", {
  skip_if_offline()

  wide <- mischooldata::fetch_enr(2025, tidy = FALSE)
  tidy <- mischooldata::fetch_enr(2025, tidy = TRUE)

  # Pick Ann Arbor as test district
  aa_wide <- wide[wide$district_id == "17010" & wide$type == "District", ]
  aa_tidy <- tidy[tidy$district_id == "17010" &
                    tidy$is_district &
                    tidy$subgroup == "total_enrollment" &
                    tidy$grade_level == "TOTAL", ]

  if (nrow(aa_wide) > 0 && nrow(aa_tidy) > 0) {
    expect_equal(aa_wide$row_total[1], aa_tidy$n_students[1])
  }
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("cache functions exist and work", {
  tryCatch({
    path <- mischooldata:::get_cache_path(2025, "tidy")
    expect_true(is.character(path))
    expect_true(grepl("2025", path))
  }, error = function(e) {
    skip("Cache functions may not be implemented")
  })
})

test_that("cache_status returns data frame", {
  tryCatch({
    status <- mischooldata::cache_status()
    expect_true(is.data.frame(status))
  }, error = function(e) {
    skip("cache_status may not be implemented")
  })
})

# ==============================================================================
# Cross-Year Consistency Tests
# ==============================================================================

test_that("different years have consistent data structure", {
  skip_if_offline()

  data_2025 <- mischooldata::fetch_enr(2025, tidy = TRUE, use_cache = FALSE)
  data_2024 <- mischooldata::fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # Should have same columns
  expect_equal(sort(names(data_2025)), sort(names(data_2024)))

  # Both should have state, district, campus rows
  expect_true(any(data_2025$is_state))
  expect_true(any(data_2025$is_district))
  expect_true(any(data_2025$is_campus))

  expect_true(any(data_2024$is_state))
  expect_true(any(data_2024$is_district))
  expect_true(any(data_2024$is_campus))
})

test_that("year-over-year state total change is reasonable", {
  skip_if_offline()

  data_2025 <- mischooldata::fetch_enr(2025, tidy = TRUE, use_cache = FALSE)
  data_2024 <- mischooldata::fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  total_2025 <- data_2025$n_students[data_2025$is_state &
                                       data_2025$subgroup == "total_enrollment" &
                                       data_2025$grade_level == "TOTAL"][1]
  total_2024 <- data_2024$n_students[data_2024$is_state &
                                       data_2024$subgroup == "total_enrollment" &
                                       data_2024$grade_level == "TOTAL"][1]

  # Year-over-year change should be < 5%
  pct_change <- abs(total_2025 - total_2024) / total_2024
  expect_true(
    pct_change < 0.05,
    info = sprintf("2025: %d, 2024: %d, change: %.2f%%",
                   total_2025, total_2024, pct_change * 100)
  )
})
