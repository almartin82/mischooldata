# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Michigan
# assessment data.
#
# Michigan assessment systems:
# - MEAP (2007-2014): Michigan Educational Assessment Program
# - M-STEP (2015-present): Michigan Student Test of Educational Progress
# - No 2020 data due to COVID-19 testing waiver
#
# Data Access Limitation:
# Michigan's M-STEP data is served through the MI School Data portal
# (mischooldata.org) which uses interactive reports. Direct download URLs
# are not publicly available. Users may need to download data manually
# and use import_local_assessment().
#
# ==============================================================================


#' Fetch Michigan assessment data
#'
#' Downloads and returns assessment data from the Michigan Department of
#' Education. Includes M-STEP (2015-present) and MEAP (2007-2014).
#'
#' **Important Note:** Michigan serves M-STEP data through an interactive portal
#' without direct download URLs. This function attempts to access available
#' historical data, but may not be able to retrieve M-STEP data for all years.
#' For M-STEP data, consider using `import_local_assessment()` with manually
#' downloaded files from https://www.mischooldata.org/
#'
#' Assessment systems:
#' - **M-STEP** (2015-present): Michigan Student Test of Educational Progress
#'   - Proficiency levels: Not Proficient, Partially Proficient, Proficient, Advanced
#'   - Grades 3-8 and 11 tested in ELA, Math
#'   - Grades 5, 8, 11 tested in Science and Social Studies
#' - **MEAP** (2007-2014): Michigan Educational Assessment Program
#'   - Legacy assessment, data availability may be limited
#' - **2020**: No data (COVID-19 testing waiver)
#'
#' @param end_year School year end (2023-24 = 2024). Valid range: 2007-2025 (no 2020).
#' @param level Level of data to fetch: "all" (default), "state", "district", "school"
#' @param tidy If TRUE (default), returns data in long (tidy) format with
#'   proficiency_level column. If FALSE, returns wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with assessment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 M-STEP assessment data
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Get wide format
#' assess_wide <- fetch_assessment(2024, tidy = FALSE)
#'
#' # Force fresh download
#' assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
#' }
fetch_assessment <- function(end_year, level = "all", tidy = TRUE, use_cache = TRUE) {

  # Get available years
  available <- get_available_assessment_years()

  # Special handling for 2020 (COVID waiver year)
  if (end_year == 2020) {
    stop("2020 assessment data is not available due to COVID-19 testing waiver. ",
         "No statewide testing was administered in Spring 2020.")
  }

  # Validate year
  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "), ". ",
      "Got: ", end_year, "\n",
      "Note: 2020 had no testing due to COVID-19 pandemic."
    ))
  }

  # Validate level
  level <- tolower(level)
  if (!level %in% c("all", "state", "district", "school")) {
    stop("level must be one of 'all', 'state', 'district', 'school'")
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "assessment_tidy" else "assessment_wide"

  # Check cache first
  if (use_cache && assessment_cache_exists(end_year, cache_type, level)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_assessment_cache(end_year, cache_type, level))
  }

  # Get raw data
  raw <- get_raw_assessment(end_year, level)

  # Check if any data was retrieved
  total_rows <- sum(
    nrow(raw$state %||% data.frame()),
    nrow(raw$district %||% data.frame()),
    nrow(raw$school %||% data.frame())
  )

  if (total_rows == 0) {
    warning(paste("No assessment data available for year", end_year,
                  "\nFor M-STEP data (2015+), download manually from mischooldata.org",
                  "\nthen use import_local_assessment()"))
    if (tidy) {
      return(create_empty_tidy_assessment())
    } else {
      return(create_empty_assessment_result(end_year))
    }
  }

  # Process to standard schema
  processed <- process_assessment(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_assessment(processed)
  } else {
    # Add aggregation flags to wide format too
    processed <- id_assessment_aggs(processed)
  }

  # Cache the result
  if (use_cache && nrow(processed) > 0) {
    write_assessment_cache(processed, end_year, cache_type, level)
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#' Note: 2020 is automatically excluded (COVID-19 testing waiver).
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param level Level of data to fetch: "all" (default), "state", "district", "school"
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' assess_multi <- fetch_assessment_multi(c(2022, 2023, 2024))
#'
#' # Track proficiency trends at state level
#' assess_multi |>
#'   dplyr::filter(is_state, subject == "Math", grade == "All") |>
#'   dplyr::filter(proficiency_level %in% c("proficient", "advanced")) |>
#'   dplyr::group_by(end_year) |>
#'   dplyr::summarize(pct_proficient = sum(pct, na.rm = TRUE))
#' }
fetch_assessment_multi <- function(end_years, level = "all", tidy = TRUE, use_cache = TRUE) {

  # Get available years
  available <- get_available_assessment_years()

  # Remove 2020 if present (COVID waiver year)
  if (2020 %in% end_years) {
    warning("2020 excluded: No assessment data due to COVID-19 testing waiver.")
    end_years <- end_years[end_years != 2020]
  }

  # Validate years
  invalid_years <- end_years[!end_years %in% available$years]
  if (length(invalid_years) > 0) {
    stop(paste0(
      "Invalid years: ", paste(invalid_years, collapse = ", "), "\n",
      "Valid years are: ", paste(available$years, collapse = ", ")
    ))
  }

  if (length(end_years) == 0) {
    stop("No valid years to fetch")
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      tryCatch({
        fetch_assessment(yr, level = level, tidy = tidy, use_cache = use_cache)
      }, error = function(e) {
        warning(paste("Failed to fetch year", yr, ":", e$message))
        if (tidy) create_empty_tidy_assessment() else create_empty_assessment_result(yr)
      })
    }
  )

  # Combine, filtering out empty data frames
  results <- results[!sapply(results, function(x) nrow(x) == 0)]
  dplyr::bind_rows(results)
}


#' Get assessment data for a specific district
#'
#' Convenience function to fetch assessment data for a single district.
#'
#' @param end_year School year end
#' @param district_id 5-digit district ID (e.g., "82015" for Detroit)
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified district
#' @export
#' @examples
#' \dontrun{
#' # Get Detroit Public Schools assessment data
#' detroit_assess <- fetch_district_assessment(2024, "82015")
#'
#' # Get Ann Arbor assessment data
#' aa_assess <- fetch_district_assessment(2024, "17010")
#' }
fetch_district_assessment <- function(end_year, district_id, tidy = TRUE, use_cache = TRUE) {

  # Normalize district_id
  district_id <- sprintf("%05d", as.integer(district_id))

  # Fetch district-level data
  df <- fetch_assessment(end_year, level = "district", tidy = tidy, use_cache = use_cache)

  # Filter to requested district
  df |>
    dplyr::filter(district_id == !!district_id)
}


#' Get assessment data for a specific school
#'
#' Convenience function to fetch assessment data for a single school.
#'
#' @param end_year School year end
#' @param district_id 5-digit district ID
#' @param school_id 5-digit school/building ID
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified school
#' @export
#' @examples
#' \dontrun{
#' # Get a specific school's assessment data
#' school_assess <- fetch_school_assessment(2024, "82015", "01234")
#' }
fetch_school_assessment <- function(end_year, district_id, school_id, tidy = TRUE, use_cache = TRUE) {

  # Normalize IDs
  district_id <- sprintf("%05d", as.integer(district_id))
  school_id <- sprintf("%05d", as.integer(school_id))

  # Fetch school-level data
  df <- fetch_assessment(end_year, level = "school", tidy = tidy, use_cache = use_cache)

  # Filter to requested school
  df |>
    dplyr::filter(district_id == !!district_id, school_id == !!school_id)
}


# ==============================================================================
# Assessment Cache Functions
# ==============================================================================

#' Get assessment cache file path
#'
#' @param end_year School year end
#' @param cache_type Cache type (assessment_tidy, assessment_wide)
#' @param level Data level
#' @return Full path to cache file
#' @keywords internal
get_assessment_cache_path <- function(end_year, cache_type, level) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, "_", level, "_", end_year, ".rds"))
}


#' Check if assessment cache exists
#'
#' @param end_year School year end
#' @param cache_type Cache type
#' @param level Data level
#' @param max_age Maximum age in days (default 30)
#' @return TRUE if valid cache exists
#' @keywords internal
assessment_cache_exists <- function(end_year, cache_type, level, max_age = 30) {
  cache_path <- get_assessment_cache_path(end_year, cache_type, level)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read assessment data from cache
#'
#' @param end_year School year end
#' @param cache_type Cache type
#' @param level Data level
#' @return Cached data frame
#' @keywords internal
read_assessment_cache <- function(end_year, cache_type, level) {
  cache_path <- get_assessment_cache_path(end_year, cache_type, level)
  readRDS(cache_path)
}


#' Write assessment data to cache
#'
#' @param df Data frame to cache
#' @param end_year School year end
#' @param cache_type Cache type
#' @param level Data level
#' @return Invisibly returns the cache path
#' @keywords internal
write_assessment_cache <- function(df, end_year, cache_type, level) {
  cache_path <- get_assessment_cache_path(end_year, cache_type, level)
  saveRDS(df, cache_path)
  invisible(cache_path)
}


# Null coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
