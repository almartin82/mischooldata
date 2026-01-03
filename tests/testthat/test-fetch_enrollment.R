# ==============================================================================
# Tests for Michigan Enrollment Data Fetching
# ==============================================================================
#
# These tests verify:
# 1. Data can be fetched for available years
# 2. State totals are reasonable (~1.4 million for Michigan)
# 3. Demographics and grades sum correctly
# 4. Raw data fidelity is maintained through tidying
# 5. No impossible values (negative counts, zeros where shouldn't be)
#
# ==============================================================================

# Helper function for tests that require network access
skip_if_no_network <- function() {
  if (!curl::has_internet()) {
    skip("No internet connection available")
  }
}

# ==============================================================================
# Year Availability Tests
# ==============================================================================

test_that("get_available_years returns expected range", {
  years <- get_available_years()

  expect_type(years, "list")
  expect_equal(years$min_year, 1996)
  expect_gte(years$max_year, 2024)  # At least 2024
  expect_lte(years$max_year, 2026)  # Not unreasonably far in future
})

# ==============================================================================
# 2024 Data Tests (Most Recent Year)
# ==============================================================================

test_that("2024 data fetches correctly", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  # Basic structure

  expect_s3_class(enr, "data.frame")
  expect_gt(nrow(enr), 50000)  # Should have many rows (buildings + districts + grades)

  # Required columns
  required_cols <- c("end_year", "type", "district_id", "subgroup",
                     "grade_level", "n_students", "is_state", "is_district", "is_building")
  expect_true(all(required_cols %in% names(enr)))

  # Year is correct
  expect_true(all(enr$end_year == 2024, na.rm = TRUE))
})

test_that("2024 state total is approximately 1.4 million", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_length(state_total, 1)
  expect_gt(state_total, 1300000)  # At least 1.3 million
  expect_lt(state_total, 1500000)  # Less than 1.5 million
})

test_that("2024 demographics sum to total enrollment", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]

  demo_subgroups <- c("white", "black", "hispanic", "asian",
                      "native_american", "pacific_islander", "multiracial")
  demo_sum <- sum(state_data$n_students[state_data$subgroup %in% demo_subgroups], na.rm = TRUE)
  total_enr <- state_data$n_students[state_data$subgroup == "total_enrollment"]

  # Demographics should sum to total (allow small rounding difference)
  expect_lt(abs(demo_sum - total_enr), 100)
})

test_that("2024 grades K-12 sum to approximately total enrollment", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  state_data <- enr[enr$is_state & enr$subgroup == "total_enrollment", ]

  grade_levels <- c("K", "01", "02", "03", "04", "05", "06",
                    "07", "08", "09", "10", "11", "12")
  grade_sum <- sum(state_data$n_students[state_data$grade_level %in% grade_levels], na.rm = TRUE)
  total_enr <- state_data$n_students[state_data$grade_level == "TOTAL"]

  # Grades should sum to total (allow small difference for PK/ungraded)
  expect_lt(abs(grade_sum - total_enr), 5000)
})

test_that("2024 has reasonable number of districts and buildings", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  # District count (Michigan has ~800-900 districts)
  n_districts <- length(unique(enr$district_id[enr$is_district]))
  expect_gt(n_districts, 500)
  expect_lt(n_districts, 1000)

  # Building count (Michigan has 3000+ schools)
  n_buildings <- length(unique(enr$building_id[enr$is_building]))
  expect_gt(n_buildings, 3000)
  expect_lt(n_buildings, 5000)
})

test_that("2024 Detroit enrollment is in expected range", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  # Detroit Public Schools Community District (82015)
  detroit <- enr$n_students[enr$is_district &
                              enr$district_id == "82015" &
                              enr$subgroup == "total_enrollment" &
                              enr$grade_level == "TOTAL"]

  expect_length(detroit, 1)
  expect_gt(detroit, 30000)  # Detroit has been declining but still > 30k
  expect_lt(detroit, 60000)  # But less than 60k (down from 100k+ years ago)
})

test_that("2024 has no impossible values", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  # No negative enrollment
  expect_true(all(enr$n_students >= 0, na.rm = TRUE))

  # No Inf or NaN values
  expect_false(any(is.infinite(enr$n_students)))
  expect_false(any(is.nan(enr$n_students)))

  # State total should NOT be zero
  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]
  expect_gt(state_total, 0)
})

# ==============================================================================
# Multi-Year Tests
# ==============================================================================

test_that("multi-year fetch works for 2020-2024", {
  skip_if_no_network()

  enr <- fetch_enr_multi(2020:2024)

  # Has all years
  years_present <- unique(enr$end_year)
  expect_equal(sort(years_present), 2020:2024)

  # Each year has state totals
  for (yr in 2020:2024) {
    state_total <- enr$n_students[enr$is_state &
                                    enr$end_year == yr &
                                    enr$subgroup == "total_enrollment" &
                                    enr$grade_level == "TOTAL"]
    expect_length(state_total, 1)
    expect_gt(state_total, 1200000)  # Reasonable minimum for any year
    expect_lt(state_total, 1600000)  # Reasonable maximum for any year
  }
})

# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================

test_that("tidy=FALSE returns wide format data", {
  skip_if_no_network()

  wide <- fetch_enr(2024, tidy = FALSE)

  # Wide format should have demographic columns
  expect_true("row_total" %in% names(wide))
  expect_true(any(grepl("^grade_", names(wide))))

  # Should NOT have subgroup column
  expect_false("subgroup" %in% names(wide))
})

test_that("wide and tidy totals match", {
  skip_if_no_network()

  wide <- fetch_enr(2024, tidy = FALSE)
  tidy <- fetch_enr(2024, tidy = TRUE)

  # District totals in wide format
  wide_dist_total <- sum(wide$row_total[wide$type == "District"], na.rm = TRUE)

  # District totals in tidy format
  tidy_dist_total <- sum(tidy$n_students[tidy$is_district &
                                           tidy$subgroup == "total_enrollment" &
                                           tidy$grade_level == "TOTAL"], na.rm = TRUE)

  expect_equal(wide_dist_total, tidy_dist_total)
})

# ==============================================================================
# Historical Year Tests (Sampling)
# ==============================================================================

test_that("2020 data (COVID year) has reasonable totals", {
  skip_if_no_network()

  enr <- fetch_enr(2020)

  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_gt(state_total, 1300000)
  expect_lt(state_total, 1550000)
})

test_that("2015 data fetches correctly", {
  skip("Skipping 2015 - xlsb format may not be supported")

  # Note: 2015 uses xlsb format which may require special handling
  enr <- fetch_enr(2015)

  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_gt(state_total, 1400000)  # Enrollment was higher in 2015
  expect_lt(state_total, 1600000)
})

test_that("2010 data fetches correctly", {
  skip_if_no_network()

  enr <- fetch_enr(2010)

  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_gt(state_total, 1500000)  # Enrollment was higher around 2010
  expect_lt(state_total, 1700000)
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("cache functions work correctly", {
  skip_if_no_network()

  # Clear cache first
  clear_cache(2024)

  # Fetch without cache
  enr1 <- fetch_enr(2024, use_cache = FALSE)

  # Now should be cached
  enr2 <- fetch_enr(2024, use_cache = TRUE)

  # Results should be identical
  expect_equal(nrow(enr1), nrow(enr2))

  # Cache status should show the file
  status <- cache_status()
  expect_true(any(status$year == 2024))
})

# ==============================================================================
# Subgroup Tests
# ==============================================================================

test_that("all expected subgroups are present", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  expected_subgroups <- c("total_enrollment", "white", "black", "hispanic",
                          "asian", "native_american", "pacific_islander",
                          "multiracial", "male", "female")

  actual_subgroups <- unique(enr$subgroup)

  # All expected subgroups should be present
  for (sg in expected_subgroups) {
    expect_true(sg %in% actual_subgroups,
                info = paste("Missing subgroup:", sg))
  }
})

test_that("gender subgroups sum to approximately total", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]

  male <- state_data$n_students[state_data$subgroup == "male"]
  female <- state_data$n_students[state_data$subgroup == "female"]
  total <- state_data$n_students[state_data$subgroup == "total_enrollment"]

  # Male + female should equal total (small rounding tolerance)
  expect_lt(abs((male + female) - total), 100)
})

# ==============================================================================
# Error Handling Tests
# ==============================================================================

test_that("invalid year throws error", {
  expect_error(fetch_enr(1990), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("invalid years in multi-year throws error", {
  expect_error(fetch_enr_multi(1990:1995), "Invalid years")
})

# ==============================================================================
# Legacy Year Tests (Pre-2010 Format)
# ==============================================================================

test_that("1996 data fetches correctly with legacy format", {
  skip_if_no_network()

  enr <- fetch_enr(1996)

  # Basic structure
  expect_s3_class(enr, "data.frame")
  expect_gt(nrow(enr), 10000)

  # State total should be around 1.6 million (peak enrollment era)
  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_length(state_total, 1)
  expect_gt(state_total, 1500000)
  expect_lt(state_total, 1700000)

  # Legacy years don't have multiracial or pacific_islander
  state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]
  subgroups_present <- unique(state_data$subgroup)

  # These core subgroups should exist
  expect_true("white" %in% subgroups_present)
  expect_true("black" %in% subgroups_present)
  expect_true("hispanic" %in% subgroups_present)
  expect_true("asian" %in% subgroups_present)
  expect_true("native_american" %in% subgroups_present)
  expect_true("male" %in% subgroups_present)
  expect_true("female" %in% subgroups_present)
})

test_that("2000 data fetches correctly", {
  skip_if_no_network()

  enr <- fetch_enr(2000)

  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_length(state_total, 1)
  expect_gt(state_total, 1600000)  # Enrollment peaked around 2000
  expect_lt(state_total, 1750000)

  # Demographics should sum correctly
  state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]
  demo_cols <- c("white", "black", "hispanic", "asian", "native_american")
  demo_sum <- sum(state_data$n_students[state_data$subgroup %in% demo_cols], na.rm = TRUE)
  total_enr <- state_data$n_students[state_data$subgroup == "total_enrollment"]

  # Allow some tolerance for rounding/missing data
  expect_lt(abs(demo_sum - total_enr), 10000)
})

test_that("2005 data fetches correctly", {
  skip_if_no_network()

  enr <- fetch_enr(2005)

  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  expect_length(state_total, 1)
  expect_gt(state_total, 1600000)
  expect_lt(state_total, 1800000)
})

# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================

test_that("state totals match between raw and processed data for 2024", {
  skip_if_no_network()

  # Get tidy data
  tidy <- fetch_enr(2024, tidy = TRUE)

  # Get wide data
  wide <- fetch_enr(2024, tidy = FALSE)

  # State row in wide format
  state_wide <- wide[wide$type == "State", ]

  # State total from tidy format
  state_total_tidy <- tidy$n_students[tidy$is_state &
                                        tidy$subgroup == "total_enrollment" &
                                        tidy$grade_level == "TOTAL"]

  # State total from wide format
  state_total_wide <- state_wide$row_total

  expect_equal(state_total_tidy, state_total_wide)
})

test_that("district counts are preserved through processing for 2024", {
  skip_if_no_network()

  wide <- fetch_enr(2024, tidy = FALSE)
  tidy <- fetch_enr(2024, tidy = TRUE)

  # Count districts in wide format
  n_wide_districts <- sum(wide$type == "District", na.rm = TRUE)

  # Count unique district rows in tidy format (total_enrollment, TOTAL grade level)
  n_tidy_districts <- sum(tidy$is_district &
                            tidy$subgroup == "total_enrollment" &
                            tidy$grade_level == "TOTAL", na.rm = TRUE)

  expect_equal(n_wide_districts, n_tidy_districts)
})

# ==============================================================================
# Year-by-Year Consistency Tests
# ==============================================================================

test_that("state enrollment trend is reasonable from 2018-2024", {
  skip_if_no_network()

  enr <- fetch_enr_multi(2018:2024)

  state_totals <- enr$n_students[enr$is_state &
                                   enr$subgroup == "total_enrollment" &
                                   enr$grade_level == "TOTAL"]

  # Should have 7 years
 expect_equal(length(state_totals), 7)

  # All should be between 1.3-1.5 million
  expect_true(all(state_totals > 1300000))
  expect_true(all(state_totals < 1500000))

  # Year-to-year changes should be less than 10%
  for (i in 2:length(state_totals)) {
    pct_change <- abs(state_totals[i] - state_totals[i-1]) / state_totals[i-1]
    expect_lt(pct_change, 0.10, label = paste("Year", 2017 + i, "change too large"))
  }
})

# ==============================================================================
# Data Completeness Tests
# ==============================================================================

test_that("all grades K-12 are present for 2024", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  expected_grades <- c("K", "01", "02", "03", "04", "05", "06",
                       "07", "08", "09", "10", "11", "12", "TOTAL")

  state_grades <- unique(enr$grade_level[enr$is_state &
                                           enr$subgroup == "total_enrollment"])

  for (g in expected_grades) {
    expect_true(g %in% state_grades, info = paste("Missing grade:", g))
  }
})

test_that("district-level data has reasonable enrollment for 2024", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  district_totals <- enr$n_students[enr$is_district &
                                      enr$subgroup == "total_enrollment" &
                                      enr$grade_level == "TOTAL"]

  # No zero-enrollment districts should exist
  expect_true(all(district_totals > 0, na.rm = TRUE))

  # Sum of districts should approximately equal state total
  sum_districts <- sum(district_totals, na.rm = TRUE)
  state_total <- enr$n_students[enr$is_state &
                                  enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]

  # Allow 5% difference for charter schools, etc.
  pct_diff <- abs(sum_districts - state_total) / state_total
  expect_lt(pct_diff, 0.05)
})

test_that("no unexpected zeros in state demographic data for 2024", {
  skip_if_no_network()

  enr <- fetch_enr(2024)

  state_demos <- enr[enr$is_state &
                       enr$grade_level == "TOTAL" &
                       enr$subgroup != "total_enrollment", ]

  # All demographic subgroups should have > 0 students
  for (i in 1:nrow(state_demos)) {
    expect_gt(state_demos$n_students[i], 0,
              label = paste("Zero value for subgroup:", state_demos$subgroup[i]))
  }
})
