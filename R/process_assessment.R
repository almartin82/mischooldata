# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Michigan assessment data
# into a clean, standardized format.
#
# Michigan assessment systems:
# - MEAP (2007-2014): Michigan Educational Assessment Program
#   - Proficiency levels: Level 1, Level 2, Level 3, Level 4
#   - Grades 3-8 tested
# - M-STEP (2015-present): Michigan Student Test of Educational Progress
#   - Proficiency levels: Not Proficient, Partially Proficient, Proficient, Advanced
#   - Grades 3-8 and 11 tested
#
# ==============================================================================


#' Process raw Michigan assessment data
#'
#' Transforms raw assessment data into a standardized schema combining
#' state, district, and school data.
#'
#' @param raw_data List containing state, district, and/or school data frames
#'   from get_raw_assessment or import_local_assessment
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_assessment <- function(raw_data, end_year) {

  result_list <- list()

  # Process each level if present
  if ("state" %in% names(raw_data) && nrow(raw_data$state) > 0) {
    result_list$state <- process_assessment_level(raw_data$state, end_year, "State")
  }

  if ("district" %in% names(raw_data) && nrow(raw_data$district) > 0) {
    result_list$district <- process_assessment_level(raw_data$district, end_year, "District")
  }

  if ("school" %in% names(raw_data) && nrow(raw_data$school) > 0) {
    result_list$school <- process_assessment_level(raw_data$school, end_year, "School")
  }

  # Combine all levels
  if (length(result_list) == 0) {
    return(create_empty_assessment_result(end_year))
  }

  dplyr::bind_rows(result_list)
}


#' Process a single level of assessment data
#'
#' @param df Raw data frame for one level (state/district/school)
#' @param end_year School year end
#' @param type Record type ("State", "District", "School")
#' @return Processed data frame
#' @keywords internal
process_assessment_level <- function(df, end_year, type) {

  if (nrow(df) == 0) {
    return(create_empty_assessment_result(end_year))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep(type, n_rows),
    stringsAsFactors = FALSE
  )

  # Determine assessment type based on year
  if (end_year <= 2014) {
    result$test <- rep("MEAP", n_rows)
  } else {
    result$test <- rep("M-STEP", n_rows)
  }

  # District ID
  district_col <- find_col(c("^district_code$", "^district_id$", "^dcode$", "^districtcode$"))
  if (!is.null(district_col)) {
    district_vals <- trimws(as.character(df[[district_col]]))
    result$district_id <- ifelse(
      district_vals == "" | is.na(district_vals),
      NA_character_,
      sprintf("%05d", as.integer(district_vals))
    )
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # District name
  district_name_col <- find_col(c("^district_name$", "^districtname$", "^dname$"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  # School/Building ID
  school_col <- find_col(c("^building_code$", "^school_code$", "^bcode$", "^buildingcode$", "^school_id$"))
  if (!is.null(school_col)) {
    school_vals <- trimws(as.character(df[[school_col]]))
    result$school_id <- ifelse(
      school_vals == "" | is.na(school_vals),
      NA_character_,
      sprintf("%05d", as.integer(school_vals))
    )
  } else {
    result$school_id <- rep(NA_character_, n_rows)
  }

  # School/Building name
  school_name_col <- find_col(c("^building_name$", "^school_name$", "^bname$", "^buildingname$"))
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(as.character(df[[school_name_col]]))
  } else {
    result$school_name <- rep(NA_character_, n_rows)
  }

  # Subject
  subject_col <- find_col(c("^subject$", "^content_area$", "^subject_area$", "^testsubject$"))
  if (!is.null(subject_col)) {
    result$subject <- standardize_mi_subject(df[[subject_col]])
  } else {
    result$subject <- rep(NA_character_, n_rows)
  }

  # Grade
  grade_col <- find_col(c("^grade$", "^grade_level$", "^tested_grade$", "^gradelevel$"))
  if (!is.null(grade_col)) {
    result$grade <- standardize_mi_grade(df[[grade_col]])
  } else {
    result$grade <- rep(NA_character_, n_rows)
  }

  # Subgroup
  subgroup_col <- find_col(c("^subgroup$", "^student_group$", "^demographic$", "^reportinggroup$"))
  if (!is.null(subgroup_col)) {
    result$subgroup <- standardize_mi_subgroup(df[[subgroup_col]])
  } else {
    result$subgroup <- rep("All Students", n_rows)
  }

  # Number tested
  n_tested_col <- find_col(c("^n_tested$", "^number_tested$", "^tested$", "^totalstudents$", "^numbertested$"))
  if (!is.null(n_tested_col)) {
    result$n_tested <- safe_numeric(df[[n_tested_col]])
  } else {
    result$n_tested <- rep(NA_integer_, n_rows)
  }

  # Proficiency percentages - Michigan uses different naming by era
  # MEAP: Level 1-4 or Beginning/Developing/Proficient/Advanced
  # M-STEP: Not Proficient/Partially Proficient/Proficient/Advanced

  # Try M-STEP naming first, then MEAP
  pct_not_prof_col <- find_col(c("^pct_not_proficient$", "^not_proficient$", "^level_1$", "^pct_level_1$", "^beginning$"))
  if (!is.null(pct_not_prof_col)) {
    result$pct_not_proficient <- safe_numeric(df[[pct_not_prof_col]])
  } else {
    result$pct_not_proficient <- rep(NA_real_, n_rows)
  }

  pct_part_prof_col <- find_col(c("^pct_partially_proficient$", "^partially_proficient$", "^level_2$", "^pct_level_2$", "^developing$"))
  if (!is.null(pct_part_prof_col)) {
    result$pct_partially_proficient <- safe_numeric(df[[pct_part_prof_col]])
  } else {
    result$pct_partially_proficient <- rep(NA_real_, n_rows)
  }

  pct_prof_col <- find_col(c("^pct_proficient$", "^proficient$", "^level_3$", "^pct_level_3$"))
  if (!is.null(pct_prof_col)) {
    result$pct_proficient <- safe_numeric(df[[pct_prof_col]])
  } else {
    result$pct_proficient <- rep(NA_real_, n_rows)
  }

  pct_adv_col <- find_col(c("^pct_advanced$", "^advanced$", "^level_4$", "^pct_level_4$"))
  if (!is.null(pct_adv_col)) {
    result$pct_advanced <- safe_numeric(df[[pct_adv_col]])
  } else {
    result$pct_advanced <- rep(NA_real_, n_rows)
  }

  # Combined proficient + advanced
  pct_prof_adv_col <- find_col(c("^pct_proficient_advanced$", "^proficient_advanced$", "^percent_meeting$"))
  if (!is.null(pct_prof_adv_col)) {
    result$pct_prof_adv <- safe_numeric(df[[pct_prof_adv_col]])
  } else {
    # Calculate if we have the components
    if (!all(is.na(result$pct_proficient)) && !all(is.na(result$pct_advanced))) {
      result$pct_prof_adv <- result$pct_proficient + result$pct_advanced
    } else {
      result$pct_prof_adv <- rep(NA_real_, n_rows)
    }
  }

  result
}


#' Standardize Michigan subject names
#'
#' @param x Vector of subject names
#' @return Standardized subject names
#' @keywords internal
standardize_mi_subject <- function(x) {
  x <- toupper(trimws(as.character(x)))

  # Standard subject mappings for Michigan
  x <- gsub("^ELA$|^ENGLISH.*LANGUAGE.*ARTS$|^READING$|^RLA$|^ENGLISH$", "ELA", x)
  x <- gsub("^MATH$|^MATHEMATICS$", "Math", x)
  x <- gsub("^SCIENCE$|^SCI$", "Science", x)
  x <- gsub("^SOCIAL.*STUDIES$|^SS$|^SOC.*STU$|^SOCIALSTUDIES$", "Social Studies", x)
  x <- gsub("^WRITING$", "Writing", x)

  x
}


#' Standardize Michigan grade levels
#'
#' @param x Vector of grade values
#' @return Standardized grade levels
#' @keywords internal
standardize_mi_grade <- function(x) {
  x <- toupper(trimws(as.character(x)))

  # Remove GRADE prefix
  x <- gsub("^GRADE\\s*", "", x)

  # Handle ordinal formats
  x <- gsub("^3RD$", "03", x)
  x <- gsub("^4TH$", "04", x)
  x <- gsub("^5TH$", "05", x)
  x <- gsub("^6TH$", "06", x)
  x <- gsub("^7TH$", "07", x)
  x <- gsub("^8TH$", "08", x)
  x <- gsub("^11TH$", "11", x)

  # Pad single digits
  x <- gsub("^([3-9])$", "0\\1", x)

  # All grades
  x <- gsub("^ALL.*GRADES$|^ALL$", "All", x)

  x
}


#' Standardize Michigan subgroup names
#'
#' @param x Vector of subgroup names
#' @return Standardized subgroup names
#' @keywords internal
standardize_mi_subgroup <- function(x) {
  x <- trimws(as.character(x))

  subgroup_map <- c(
    # All students
    "All Students" = "All Students",
    "ALL STUDENTS" = "All Students",
    "All" = "All Students",
    "ALL" = "All Students",

    # Race/ethnicity
    "Black or African American" = "Black",
    "BLACK OR AFRICAN AMERICAN" = "Black",
    "African American" = "Black",
    "Black" = "Black",

    "White" = "White",
    "WHITE" = "White",

    "Hispanic or Latino" = "Hispanic",
    "HISPANIC OR LATINO" = "Hispanic",
    "Hispanic/Latino" = "Hispanic",
    "Hispanic" = "Hispanic",

    "Asian" = "Asian",
    "ASIAN" = "Asian",

    "American Indian or Alaska Native" = "Native American",
    "AMERICAN INDIAN OR ALASKA NATIVE" = "Native American",
    "American Indian" = "Native American",
    "Native American" = "Native American",

    "Native Hawaiian or Other Pacific Islander" = "Pacific Islander",
    "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" = "Pacific Islander",
    "Pacific Islander" = "Pacific Islander",

    "Two or More Races" = "Multiracial",
    "TWO OR MORE RACES" = "Multiracial",
    "Multiracial" = "Multiracial",
    "Multi-Racial" = "Multiracial",

    # Gender
    "Female" = "Female",
    "FEMALE" = "Female",
    "Male" = "Male",
    "MALE" = "Male",

    # Special populations
    "Economically Disadvantaged" = "Economically Disadvantaged",
    "ECONOMICALLY DISADVANTAGED" = "Economically Disadvantaged",
    "Low Income" = "Economically Disadvantaged",

    "Students with Disabilities" = "Students with Disabilities",
    "STUDENTS WITH DISABILITIES" = "Students with Disabilities",
    "SWD" = "Students with Disabilities",
    "Special Education" = "Students with Disabilities",

    "English Learners" = "English Learners",
    "ENGLISH LEARNERS" = "English Learners",
    "EL" = "English Learners",
    "ELL" = "English Learners",
    "LEP" = "English Learners",
    "Limited English Proficient" = "English Learners",

    "Homeless" = "Homeless",
    "HOMELESS" = "Homeless",

    "Migrant" = "Migrant",
    "MIGRANT" = "Migrant"
  )

  # Apply mapping
  result <- subgroup_map[x]

  # Keep original for unmapped values
  result[is.na(result)] <- x[is.na(result)]

  unname(result)
}


#' Safe numeric conversion
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Handle suppressed values (*, <, >, etc.)
  x <- gsub("[*<>]", "", as.character(x))
  x <- trimws(x)
  x[x == ""] <- NA
  suppressWarnings(as.numeric(x))
}


#' Create empty assessment result data frame
#'
#' @param end_year School year end
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_assessment_result <- function(end_year) {
  data.frame(
    end_year = integer(0),
    type = character(0),
    test = character(0),
    district_id = character(0),
    district_name = character(0),
    school_id = character(0),
    school_name = character(0),
    subject = character(0),
    grade = character(0),
    subgroup = character(0),
    n_tested = integer(0),
    pct_not_proficient = numeric(0),
    pct_partially_proficient = numeric(0),
    pct_proficient = numeric(0),
    pct_advanced = numeric(0),
    pct_prof_adv = numeric(0),
    stringsAsFactors = FALSE
  )
}
