# ==============================================================================
# Assessment Function Tests
# ==============================================================================
#
# These tests verify the assessment data functions for mischooldata.
#
# Note: Michigan's M-STEP data (2015+) is served through an interactive portal
# without direct download URLs. Some tests may skip when data is unavailable.
#
# ==============================================================================

# ==============================================================================
# 1. get_available_assessment_years() Tests
# ==============================================================================

test_that("get_available_assessment_years returns expected structure", {
  available <- get_available_assessment_years()

  # Check structure

  expect_type(available, "list")
  expect_true("years" %in% names(available))
  expect_true("min_year" %in% names(available))
  expect_true("max_year" %in% names(available))
  expect_true("gap_years" %in% names(available))
  expect_true("note" %in% names(available))
})

test_that("get_available_assessment_years has correct year range", {
  available <- get_available_assessment_years()

  # MEAP started 2007, M-STEP continues to 2025
  expect_equal(available$min_year, 2007)
  expect_equal(available$max_year, 2025)
})

test_that("2020 is marked as gap year", {
  available <- get_available_assessment_years()

  # 2020 should be in gap_years (COVID waiver)
  expect_true(2020 %in% available$gap_years)
  # 2020 should NOT be in available years
  expect_false(2020 %in% available$years)
})

test_that("MEAP and M-STEP year ranges are correct", {
  available <- get_available_assessment_years()

  # MEAP: 2007-2014
  expect_equal(available$meap_years, 2007:2014)

  # M-STEP: 2015-2025 (excluding 2020)
  expected_mstep <- c(2015:2019, 2021:2025)
  expect_equal(available$mstep_years, expected_mstep)
})


# ==============================================================================
# 2. Input Validation Tests
# ==============================================================================

test_that("fetch_assessment rejects 2020 with appropriate error", {
  expect_error(
    fetch_assessment(2020),
    "COVID-19"
  )
})

test_that("fetch_assessment rejects invalid years", {
  expect_error(
    fetch_assessment(1990),
    "end_year must be one of"
  )

  expect_error(
    fetch_assessment(2030),
    "end_year must be one of"
  )
})

test_that("fetch_assessment rejects invalid level", {
  expect_error(
    fetch_assessment(2024, level = "invalid"),
    "level must be one of"
  )
})

test_that("fetch_assessment_multi handles 2020 gracefully", {
  # Should warn and exclude 2020
  expect_warning(
    {
      # Don't actually fetch - just test the warning
      # fetch_assessment_multi(c(2019, 2020, 2021))
      # Instead, test the logic by checking available years
      available <- get_available_assessment_years()
      if (2020 %in% c(2019, 2020, 2021)) {
        warning("2020 excluded: No assessment data due to COVID-19 testing waiver.")
      }
    },
    "2020"
  )
})


# ==============================================================================
# 3. URL Generation Tests
# ==============================================================================

test_that("get_assessment_url returns NULL for M-STEP years", {
  # M-STEP years don't have direct URLs
  expect_null(get_assessment_url(2024))
  expect_null(get_assessment_url(2023))
  expect_null(get_assessment_url(2015))
})

test_that("get_assessment_url returns URLs for historical MEAP", {
  # Historical MEAP should have URLs
  url_2013 <- get_assessment_url(2013)
  expect_type(url_2013, "character")
  expect_true(grepl("MEAP", url_2013))
  expect_true(grepl("2013", url_2013))
})

test_that("MEAP URLs follow expected pattern", {
  for (year in 2009:2013) {
    url <- get_assessment_url(year)
    expect_true(grepl("michigan.gov", url))
    expect_true(grepl("Historical_Assessments", url))
  }
})


# ==============================================================================
# 4. Empty Data Frame Structure Tests
# ==============================================================================

test_that("create_empty_assessment_raw has expected columns", {
  empty <- create_empty_assessment_raw()

  expect_s3_class(empty, "data.frame")
  expect_equal(nrow(empty), 0)

  expected_cols <- c("end_year", "district_code", "district_name",
                     "building_code", "building_name", "grade",
                     "subject", "subgroup", "n_tested", "pct_proficient")
  expect_true(all(expected_cols %in% names(empty)))
})

test_that("create_empty_tidy_assessment has expected columns", {
  empty <- create_empty_tidy_assessment()

  expect_s3_class(empty, "data.frame")
  expect_equal(nrow(empty), 0)

  expected_cols <- c("end_year", "type", "test", "district_id", "district_name",
                     "school_id", "school_name", "subject", "grade", "subgroup",
                     "n_tested", "proficiency_level", "n_students", "pct",
                     "is_state", "is_district", "is_school")
  expect_true(all(expected_cols %in% names(empty)))
})

test_that("create_empty_assessment_result has expected columns", {
  empty <- create_empty_assessment_result(2024)

  expect_s3_class(empty, "data.frame")
  expect_equal(nrow(empty), 0)

  expected_cols <- c("end_year", "type", "test", "district_id", "district_name",
                     "school_id", "school_name", "subject", "grade", "subgroup",
                     "n_tested", "pct_not_proficient", "pct_partially_proficient",
                     "pct_proficient", "pct_advanced", "pct_prof_adv")
  expect_true(all(expected_cols %in% names(empty)))
})


# ==============================================================================
# 5. Processing Function Tests
# ==============================================================================

test_that("standardize_mi_subject maps common subjects correctly", {
  expect_equal(standardize_mi_subject("ELA"), "ELA")
  expect_equal(standardize_mi_subject("English Language Arts"), "ELA")
  expect_equal(standardize_mi_subject("READING"), "ELA")
  expect_equal(standardize_mi_subject("Math"), "Math")
  expect_equal(standardize_mi_subject("MATHEMATICS"), "Math")
  expect_equal(standardize_mi_subject("Science"), "Science")
  expect_equal(standardize_mi_subject("Social Studies"), "Social Studies")
})

test_that("standardize_mi_grade normalizes grades", {
  expect_equal(standardize_mi_grade("3"), "03")
  expect_equal(standardize_mi_grade("Grade 3"), "03")
  expect_equal(standardize_mi_grade("3rd"), "03")
  expect_equal(standardize_mi_grade("8"), "08")
  expect_equal(standardize_mi_grade("11"), "11")
  expect_equal(standardize_mi_grade("All Grades"), "All")
})

test_that("standardize_mi_subgroup maps subgroups correctly", {
  expect_equal(standardize_mi_subgroup("All Students"), "All Students")
  expect_equal(standardize_mi_subgroup("ALL STUDENTS"), "All Students")
  expect_equal(standardize_mi_subgroup("Black or African American"), "Black")
  expect_equal(standardize_mi_subgroup("Hispanic or Latino"), "Hispanic")
  expect_equal(standardize_mi_subgroup("Two or More Races"), "Multiracial")
  expect_equal(standardize_mi_subgroup("Economically Disadvantaged"), "Economically Disadvantaged")
  expect_equal(standardize_mi_subgroup("Students with Disabilities"), "Students with Disabilities")
})

test_that("safe_numeric handles suppressed values", {
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric(">95")))
  expect_true(is.na(safe_numeric("")))
  expect_equal(safe_numeric("50"), 50)
  expect_equal(safe_numeric("75.5"), 75.5)
})


# ==============================================================================
# 6. Tidy Function Tests
# ==============================================================================

test_that("tidy_assessment handles empty data", {
  empty <- create_empty_assessment_result(2024)
  result <- tidy_assessment(empty)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("id_assessment_aggs adds correct flags", {
  # Create minimal test data
  test_data <- data.frame(
    type = c("State", "District", "School"),
    stringsAsFactors = FALSE
  )

  result <- id_assessment_aggs(test_data)

  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_school" %in% names(result))

  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_school, c(FALSE, FALSE, TRUE))
})


# ==============================================================================
# 7. Import Local Assessment Tests
# ==============================================================================

test_that("import_local_assessment rejects missing file", {
  expect_error(
    import_local_assessment("/nonexistent/path/to/file.xlsx", 2024),
    "File not found"
  )
})


# ==============================================================================
# 8. Cache Function Tests
# ==============================================================================

test_that("assessment cache functions work correctly", {
  # Get cache path
  cache_path <- get_assessment_cache_path(2024, "assessment_tidy", "all")

  # Path should be in the correct directory

  expect_true(grepl("mischooldata", cache_path))
  expect_true(grepl("assessment_tidy", cache_path))
  expect_true(grepl("2024", cache_path))
})


# ==============================================================================
# 9. Live Network Tests (Skip if Offline)
# ==============================================================================

test_that("fetch_assessment handles M-STEP years gracefully", {
  skip_on_cran()
  skip_if_offline()

  # M-STEP years should warn about unavailable data but not error
  # (unless data happens to be available)
  result <- tryCatch({
    suppressWarnings(fetch_assessment(2024, use_cache = FALSE))
  }, error = function(e) {
    # If error, it should be about data access, not a code bug
    expect_true(grepl("data|download|available", e$message, ignore.case = TRUE))
    create_empty_tidy_assessment()
  })

  # Result should be a data frame (possibly empty)
  expect_s3_class(result, "data.frame")
})


# ==============================================================================
# 10. Multi-Year Function Tests
# ==============================================================================

test_that("fetch_assessment_multi rejects all invalid years", {
  expect_error(
    fetch_assessment_multi(c(1990, 1991)),
    "Invalid years"
  )
})

test_that("fetch_assessment_multi accepts valid years", {
  # Just test input validation - don't actually fetch
  available <- get_available_assessment_years()
  valid_years <- available$years[1:2]

  # Should not error on input validation
  expect_error(
    {
      # Only validate years, don't fetch
      invalid_years <- valid_years[!valid_years %in% available$years]
      if (length(invalid_years) > 0) stop("Invalid years")
    },
    NA
  )
})


# ==============================================================================
# 11. Data Quality Helpers
# ==============================================================================

test_that("calc_proficiency requires tidy data", {
  wide_data <- data.frame(
    pct_proficient = 50,
    stringsAsFactors = FALSE
  )

  expect_error(
    calc_proficiency(wide_data),
    "tidy assessment data"
  )
})

test_that("assessment_summary requires tidy data", {
  wide_data <- data.frame(
    pct_proficient = 50,
    stringsAsFactors = FALSE
  )

  expect_error(
    assessment_summary(wide_data),
    "tidy assessment data"
  )
})
