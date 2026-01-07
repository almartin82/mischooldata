# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw CEPI enrollment data into a
# clean, standardized format.
#
# Michigan column naming conventions:
# - tot_ai: American Indian/Alaska Native
# - tot_as: Asian
# - tot_aa: African American/Black
# - tot_hw: Hawaiian/Pacific Islander
# - tot_wh: White
# - tot_hs: Hispanic/Latino
# - tot_mr: Multiracial (Two or more races)
# - tot_m_*: Male counts by race
# - tot_f_*: Female counts by race
# - k_totl, g1_totl, etc.: Grade-level totals
# - tot_male, tot_fem, tot_all: Overall totals
#
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' Michigan uses various markers for suppressed data (*, <, etc.)
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Handle character input
  if (is.character(x)) {
    # Remove commas and whitespace
    x <- gsub(",", "", x)
    x <- trimws(x)

    # Handle common suppression markers
    x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "NULL")] <- NA_character_
    x[grepl("^<", x)] <- NA_character_  # Any < prefixed values
  }

  suppressWarnings(as.numeric(x))
}


#' Process raw CEPI enrollment data
#'
#' Transforms raw data into a standardized schema combining building,
#' district, and state data.
#'
#' @param raw_data List containing building, district, and state data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process building data
  building_processed <- NULL
  if (!is.null(raw_data$building) && nrow(raw_data$building) > 0) {
    building_processed <- process_building_enr(raw_data$building, end_year)
  }

  # Process district data
  district_processed <- NULL
  if (!is.null(raw_data$district) && nrow(raw_data$district) > 0) {
    district_processed <- process_district_enr(raw_data$district, end_year)
  }

  # Process or create state aggregate
  state_processed <- NULL
  if (!is.null(raw_data$state) && nrow(raw_data$state) > 0) {
    state_processed <- process_state_enr(raw_data$state, end_year)
  } else if (!is.null(district_processed)) {
    # Create state aggregate from district data
    state_processed <- create_state_aggregate(district_processed, end_year)
  }

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, building_processed)

  result
}


#' Process building-level enrollment data
#'
#' @param df Raw building data frame
#' @param end_year School year end
#' @return Processed building data frame
#' @keywords internal
process_building_enr <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Building", n_rows),
    stringsAsFactors = FALSE
  )

  # IDs
  campus_col <- find_col(c("Building Code", "BuildingCode", "BLDG_CODE", "BCODE"))
  if (!is.null(campus_col)) {
    result$campus_id <- trimws(df[[campus_col]])
  }

  district_col <- find_col(c("District Code", "DistrictCode", "DIST_CODE", "DCODE"))
  if (!is.null(district_col)) {
    result$district_id <- trimws(df[[district_col]])
  }

  # Names
  campus_name_col <- find_col(c("Building Name", "BuildingName", "BLDG_NAME", "BNAME"))
  if (!is.null(campus_name_col)) {
    result$campus_name <- trimws(df[[campus_name_col]])
  }

  district_name_col <- find_col(c("District Name", "DistrictName", "DIST_NAME", "DNAME"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(df[[district_name_col]])
  }

  # Total enrollment
  total_col <- find_col(c("tot_all", "TOT_ALL", "TOTAL", "K12_TOTAL"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - map Michigan column names to standard names
  # Modern files (2010+): tot_ai, tot_as, etc.
  # Older files (1996-2003): Need to sum TOT_M_IND + TOT_F_IND, etc.
  demo_map <- list(
    native_american = c("tot_ai", "AMERICAN_INDIAN"),
    asian = c("tot_as", "ASIAN"),
    black = c("tot_aa", "AFRICAN_AMERICAN", "BLACK"),
    pacific_islander = c("tot_hw", "HAWAIIAN", "PACIFIC_ISLANDER"),
    white = c("tot_wh", "WHITE"),
    hispanic = c("tot_hs", "HISPANIC"),
    multiracial = c("tot_mr", "TWO_OR_MORE", "MULTIRACIAL")
  )

  # Map for older files that have separate M/F columns
  legacy_demo_map <- list(
    native_american = c("TOT_M_IND", "TOT_F_IND"),
    asian = c("TOT_M_ASN", "TOT_F_ASN"),
    black = c("TOT_M_BLK", "TOT_F_BLK"),
    white = c("TOT_M_WHT", "TOT_F_WHT"),
    hispanic = c("TOT_M_HSP", "TOT_F_HSP")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else if (name %in% names(legacy_demo_map)) {
      # Try legacy columns (sum male + female)
      m_col <- find_col(legacy_demo_map[[name]][1])
      f_col <- find_col(legacy_demo_map[[name]][2])
      if (!is.null(m_col) && !is.null(f_col)) {
        m_vals <- safe_numeric(df[[m_col]])
        f_vals <- safe_numeric(df[[f_col]])
        result[[name]] <- ifelse(is.na(m_vals) & is.na(f_vals), NA_real_,
                                  rowSums(cbind(m_vals, f_vals), na.rm = TRUE))
      }
    }
  }

  # Gender
  male_col <- find_col(c("tot_male", "TOT_MALE", "MALE"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(c("tot_fem", "TOT_FEMALE", "tot_female", "FEMALE"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Grade levels
  grade_map <- list(
    grade_k = c("k_totl", "K_TOTAL", "KINDERGARTEN"),
    grade_01 = c("g1_totl", "G1_TOTAL", "GRADE_1"),
    grade_02 = c("g2_totl", "G2_TOTAL", "GRADE_2"),
    grade_03 = c("g3_totl", "G3_TOTAL", "GRADE_3"),
    grade_04 = c("g4_totl", "G4_TOTAL", "GRADE_4"),
    grade_05 = c("g5_totl", "G5_TOTAL", "GRADE_5"),
    grade_06 = c("g6_totl", "G6_TOTAL", "GRADE_6"),
    grade_07 = c("g7_totl", "G7_TOTAL", "GRADE_7"),
    grade_08 = c("g8_totl", "G8_TOTAL", "GRADE_8"),
    grade_09 = c("g9_totl", "G9_TOTAL", "GRADE_9"),
    grade_10 = c("g10_totl", "G10_TOTAL", "GRADE_10"),
    grade_11 = c("g11_totl", "G11_TOTAL", "GRADE_11"),
    grade_12 = c("g12_totl", "G12_TOTAL", "GRADE_12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # IDs
  district_col <- find_col(c("District Code", "DistrictCode", "DIST_CODE", "DCODE"))
  if (!is.null(district_col)) {
    result$district_id <- trimws(df[[district_col]])
  }

  result$campus_id <- rep(NA_character_, n_rows)

  # Names
  district_name_col <- find_col(c("District Name", "DistrictName", "DIST_NAME", "DNAME"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(df[[district_name_col]])
  }

  result$campus_name <- rep(NA_character_, n_rows)

  # Total enrollment
  total_col <- find_col(c("tot_all", "TOT_ALL", "TOTAL", "K12_TOTAL"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - map Michigan column names to standard names
  demo_map <- list(
    native_american = c("tot_ai", "AMERICAN_INDIAN"),
    asian = c("tot_as", "ASIAN"),
    black = c("tot_aa", "AFRICAN_AMERICAN", "BLACK"),
    pacific_islander = c("tot_hw", "HAWAIIAN", "PACIFIC_ISLANDER"),
    white = c("tot_wh", "WHITE"),
    hispanic = c("tot_hs", "HISPANIC"),
    multiracial = c("tot_mr", "TWO_OR_MORE", "MULTIRACIAL")
  )

  # Map for older files that have separate M/F columns
  legacy_demo_map <- list(
    native_american = c("TOT_M_IND", "TOT_F_IND"),
    asian = c("TOT_M_ASN", "TOT_F_ASN"),
    black = c("TOT_M_BLK", "TOT_F_BLK"),
    white = c("TOT_M_WHT", "TOT_F_WHT"),
    hispanic = c("TOT_M_HSP", "TOT_F_HSP")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else if (name %in% names(legacy_demo_map)) {
      # Try legacy columns (sum male + female)
      m_col <- find_col(legacy_demo_map[[name]][1])
      f_col <- find_col(legacy_demo_map[[name]][2])
      if (!is.null(m_col) && !is.null(f_col)) {
        m_vals <- safe_numeric(df[[m_col]])
        f_vals <- safe_numeric(df[[f_col]])
        result[[name]] <- ifelse(is.na(m_vals) & is.na(f_vals), NA_real_,
                                  rowSums(cbind(m_vals, f_vals), na.rm = TRUE))
      }
    }
  }

  # Gender
  male_col <- find_col(c("tot_male", "TOT_MALE", "MALE"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(c("tot_fem", "TOT_FEMALE", "tot_female", "FEMALE"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Grade levels
  grade_map <- list(
    grade_k = c("k_totl", "K_TOTAL", "KINDERGARTEN"),
    grade_01 = c("g1_totl", "G1_TOTAL", "GRADE_1"),
    grade_02 = c("g2_totl", "G2_TOTAL", "GRADE_2"),
    grade_03 = c("g3_totl", "G3_TOTAL", "GRADE_3"),
    grade_04 = c("g4_totl", "G4_TOTAL", "GRADE_4"),
    grade_05 = c("g5_totl", "G5_TOTAL", "GRADE_5"),
    grade_06 = c("g6_totl", "G6_TOTAL", "GRADE_6"),
    grade_07 = c("g7_totl", "G7_TOTAL", "GRADE_7"),
    grade_08 = c("g8_totl", "G8_TOTAL", "GRADE_8"),
    grade_09 = c("g9_totl", "G9_TOTAL", "GRADE_9"),
    grade_10 = c("g10_totl", "G10_TOTAL", "GRADE_10"),
    grade_11 = c("g11_totl", "G11_TOTAL", "GRADE_11"),
    grade_12 = c("g12_totl", "G12_TOTAL", "GRADE_12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Process state-level enrollment data
#'
#' @param df Raw state data frame
#' @param end_year School year end
#' @return Processed state data frame (single row)
#' @keywords internal
process_state_enr <- function(df, end_year) {

  cols <- names(df)

  # Helper to find column by pattern
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Filter to just the State row (for files that have a Level column)
  level_col <- find_col(c("Level", "LEVEL", "EntityLevel"))
  if (!is.null(level_col)) {
    state_rows <- df[[level_col]] == "State"
    if (any(state_rows, na.rm = TRUE)) {
      df <- df[state_rows, , drop = FALSE]
    }
  }

  if (nrow(df) == 0) {
    # Return NULL if no data (will trigger fallback to create_state_aggregate)
    return(NULL)
  }

  # Take first row only
  df <- df[1, , drop = FALSE]

  # Re-define cols after filtering
  cols <- names(df)

  result <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Total enrollment
  total_col <- find_col(c("tot_all", "TOT_ALL", "TOTAL", "K12_TOTAL"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - map Michigan column names to standard names
  demo_map <- list(
    native_american = c("tot_ai", "AMERICAN_INDIAN"),
    asian = c("tot_as", "ASIAN"),
    black = c("tot_aa", "AFRICAN_AMERICAN", "BLACK"),
    pacific_islander = c("tot_hw", "HAWAIIAN", "PACIFIC_ISLANDER"),
    white = c("tot_wh", "WHITE"),
    hispanic = c("tot_hs", "HISPANIC"),
    multiracial = c("tot_mr", "TWO_OR_MORE", "MULTIRACIAL")
  )

  # Map for older files that have separate M/F columns
  legacy_demo_map <- list(
    native_american = c("TOT_M_IND", "TOT_F_IND"),
    asian = c("TOT_M_ASN", "TOT_F_ASN"),
    black = c("TOT_M_BLK", "TOT_F_BLK"),
    white = c("TOT_M_WHT", "TOT_F_WHT"),
    hispanic = c("TOT_M_HSP", "TOT_F_HSP")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else if (name %in% names(legacy_demo_map)) {
      # Try legacy columns (sum male + female)
      m_col <- find_col(legacy_demo_map[[name]][1])
      f_col <- find_col(legacy_demo_map[[name]][2])
      if (!is.null(m_col) && !is.null(f_col)) {
        m_val <- safe_numeric(df[[m_col]])
        f_val <- safe_numeric(df[[f_col]])
        result[[name]] <- sum(c(m_val, f_val), na.rm = TRUE)
        if (is.na(m_val) && is.na(f_val)) result[[name]] <- NA_real_
      }
    }
  }

  # Gender
  male_col <- find_col(c("tot_male", "TOT_MALE", "MALE"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(c("tot_fem", "TOT_FEMALE", "tot_female", "FEMALE"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Grade levels
  grade_map <- list(
    grade_k = c("k_totl", "K_TOTAL", "KINDERGARTEN"),
    grade_01 = c("g1_totl", "G1_TOTAL", "GRADE_1"),
    grade_02 = c("g2_totl", "G2_TOTAL", "GRADE_2"),
    grade_03 = c("g3_totl", "G3_TOTAL", "GRADE_3"),
    grade_04 = c("g4_totl", "G4_TOTAL", "GRADE_4"),
    grade_05 = c("g5_totl", "G5_TOTAL", "GRADE_5"),
    grade_06 = c("g6_totl", "G6_TOTAL", "GRADE_6"),
    grade_07 = c("g7_totl", "G7_TOTAL", "GRADE_7"),
    grade_08 = c("g8_totl", "G8_TOTAL", "GRADE_8"),
    grade_09 = c("g9_totl", "G9_TOTAL", "GRADE_9"),
    grade_10 = c("g10_totl", "G10_TOTAL", "GRADE_10"),
    grade_11 = c("g11_totl", "G11_TOTAL", "GRADE_11"),
    grade_12 = c("g12_totl", "G12_TOTAL", "GRADE_12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Create state-level aggregate from district data
#'
#' This is used as a fallback when the Excel file doesn't have a state sheet.
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
  }

  state_row
}
