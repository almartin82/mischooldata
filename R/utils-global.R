# ==============================================================================
# Global Variable Declarations for NSE
# ==============================================================================
#
# This file declares global variables for non-standard evaluation (NSE)
# to prevent R CMD CHECK notes about undefined variables.
#
# ==============================================================================

utils::globalVariables(
  c(
    # Data frame columns used in NSE (dplyr::select, dplyr::mutate, etc.)
    "subgroup",
    "grade_level",
    "n_students",
    "row_total",
    "type",
    "pct",
    "is_state",
    "is_district",
    "is_campus",
    "is_school",
    "end_year",
    "district_id",
    "campus_id",
    "district_name",
    "campus_name",
    # Assessment-specific columns
    "school_id",
    "school_name",
    "test",
    "subject",
    "grade",
    "n_tested",
    "proficiency_level",
    "pct_not_proficient",
    "pct_partially_proficient",
    "pct_proficient",
    "pct_advanced",
    "pct_prof_adv"
  )
)
