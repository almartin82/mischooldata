# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from CEPI.
# Data comes from MI School Data Excel files hosted on michigan.gov.
#
# URL patterns vary by year:
# - 2021-present: michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/
# - 2018-2020: michigan.gov/documents/cepi/
# - 1992-2017: michigan.gov/-/media/Project/Websites/cepi/MISchoolData/
#
# ==============================================================================

#' Get the download URL for a specific year
#'
#' Constructs the download URL for MI School Data headcount files.
#' URL patterns change over time based on how CEPI has organized their files.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return Character string with download URL
#' @keywords internal
get_headcount_url <- function(end_year) {

  # URL patterns by era
  # Era 1 (1992-2017): Legacy URLs with varying patterns
  # Era 2 (2018-2020): documents/cepi pattern

  # Era 3 (2021+): cepi/-/media pattern

  if (end_year >= 2025) {
    # 2024-25
    url <- "https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/2024-25/Spring_2025_Headcount.xlsx"
  } else if (end_year == 2024) {
    url <- "https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/2023-24/Spring_2024_Headcount.xlsx"
  } else if (end_year == 2023) {
    url <- "https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MISchoolData/2022-23/Fall_Spring_2022_headcount.xlsx"
  } else if (end_year == 2022) {
    url <- "https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MiSchoolData/2021-22/Fall_2021_headcount.xlsx"
  } else if (end_year == 2021) {
    url <- "https://michigan.gov/documents/cepi/Fall_2020_headcount_719042_7.xlsx"
  } else if (end_year == 2020) {
    url <- "https://michigan.gov/documents/cepi/Fall_2019_headcount_684498_7.xlsx"
  } else if (end_year == 2019) {
    url <- "https://michigan.gov/documents/cepi/Fall_2018_headcount_652426_7.xlsx"
  } else if (end_year == 2018) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2017-18/17_Fall_headcount.xlsx"
  } else if (end_year == 2017) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2016-17/1617_Fall_headcount.xlsx"
  } else if (end_year == 2016) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2015-16/1516_Fall_Spring_headcount.xlsx"
  } else if (end_year == 2015) {
    # Note: 2014-15 file is .xlsb format, may need special handling
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2014-15/1415_Fall_Spring_headcount.xlsb"
  } else if (end_year == 2014) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2013-14/1314_headcount.xlsx"
  } else if (end_year == 2013) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2012-13/1213_headcount.xlsx"
  } else if (end_year == 2012) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2011-12/1112_headcount.xlsx"
  } else if (end_year == 2011) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2010-11/1011_headcount.xlsx"
  } else if (end_year == 2010) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2009-10/0910_headcount.xlsx"
  } else if (end_year == 2009) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2008-09/0809_headcount.xlsx"
  } else if (end_year == 2008) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2007-08/0708_headcount.xlsx"
  } else if (end_year == 2007) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2006-07/0607_headcount.xlsx"
  } else if (end_year == 2006) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2005-06/0506_headcount.xlsx"
  } else if (end_year == 2005) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2004-05/0405_headcount.xlsx"
  } else if (end_year == 2004) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2003-04/0304_headcount.xlsx"
  } else if (end_year == 2003) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2002-03/0203_headcount.xlsx"
  } else if (end_year == 2002) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2001-02/0102_headcount.xlsx"
  } else if (end_year == 2001) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/2000-01/0001_headcount.xlsx"
  } else if (end_year == 2000) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/1999-00/9900_headcount.xlsx"
  } else if (end_year == 1999) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/1998-99/9899_headcount.xlsx"
  } else if (end_year == 1998) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/1997-98/9798_headcount.xlsx"
  } else if (end_year == 1997) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/1996-97/9697_headcount.xlsx"
  } else if (end_year == 1996) {
    url <- "https://www.michigan.gov/-/media/Project/Websites/cepi/MISchoolData/1995-96/95-96_headcount.xlsx"
  } else {
    stop(paste("No data available for year", end_year))
  }

  url
}


#' Download raw enrollment data from CEPI
#'
#' Downloads the MI School Data headcount Excel file for a given year.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return List with building, district, and state data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  message(paste("Downloading CEPI enrollment data for", end_year, "..."))

  url <- get_headcount_url(end_year)

  # Create temp file
  temp_file <- tempfile(fileext = ".xlsx")

  # Download with browser user-agent (CEPI blocks curl default UA)
  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"),
      httr::timeout(300)
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

    # Verify file is a valid Excel file
    file_info <- file.info(temp_file)
    if (file_info$size < 1000) {
      content <- readLines(temp_file, n = 5, warn = FALSE)
      if (any(grepl("Access Denied|error|not found", content, ignore.case = TRUE))) {
        stop("Server returned an error page instead of data file")
      }
    }

  }, error = function(e) {
    stop(paste("Failed to download enrollment data for year", end_year,
               "\nError:", e$message,
               "\nURL:", url))
  })

  # Read the Excel file
  # Sheet naming conventions vary by year, but we look for K-12 Total sheets
  sheets <- readxl::excel_sheets(temp_file)

  # Find the appropriate sheets
  # Modern files (2016+): "Fall Bldg K-12 Total Data", "Fall Dist K-12 Total Data", "Fall State K-12 Total Data"
  # Older files may have different naming

  result <- list()

  # Building data
  # Patterns ordered by preference: modern files -> older files
  bldg_sheet <- find_sheet(sheets, c(
    "Fall Bldg K-12 Total Data",
    "Fall Bldg Total",
    "Fall Bldg Total Data",
    "Fall Bldg Enrollment Data",
    "Bldg K-12 Total",
    "Building"
  ))
  if (!is.null(bldg_sheet)) {
    result$building <- read_headcount_sheet(temp_file, bldg_sheet, "building", end_year)
  }

  # District data
  dist_sheet <- find_sheet(sheets, c(
    "Fall Dist K-12 Total Data",
    "Fall Dist Total",
    "Fall Dist Total Data",
    "Fall Dist Enrollment Data",
    "Dist K-12 Total",
    "District"
  ))
  if (!is.null(dist_sheet)) {
    result$district <- read_headcount_sheet(temp_file, dist_sheet, "district", end_year)
  }

  # State data
  state_sheet <- find_sheet(sheets, c(
    "Fall State K-12 Total Data",
    "Fall State Total",
    "Fall State Total Data",
    "Fall State Enrollment Data",
    "State K-12 Total",
    "State"
  ))
  if (!is.null(state_sheet)) {
    result$state <- read_headcount_sheet(temp_file, state_sheet, "state", end_year)
  }

  # Clean up temp file
  unlink(temp_file)

  # Add end_year to all data frames
  result$building$end_year <- end_year
  result$district$end_year <- end_year
  if (!is.null(result$state)) {
    result$state$end_year <- end_year
  }

  result
}


#' Find a sheet by name pattern
#'
#' @param sheets Vector of sheet names
#' @param patterns Vector of patterns to match (in order of preference)
#' @return Matched sheet name or NULL
#' @keywords internal
find_sheet <- function(sheets, patterns) {
  for (pattern in patterns) {
    matched <- grep(pattern, sheets, value = TRUE, ignore.case = TRUE)
    if (length(matched) > 0) {
      return(matched[1])
    }
  }
  NULL
}


#' Read a headcount sheet from the Excel file
#'
#' @param file_path Path to Excel file
#' @param sheet_name Name of sheet to read
#' @param level Data level (building, district, state)
#' @param end_year School year end (used to determine file format era)
#' @return Data frame
#' @keywords internal
read_headcount_sheet <- function(file_path, sheet_name, level, end_year = 2024) {

  # Determine skip rows based on year and file format
  # Era 1 (1996-2003): No header rows, columns start with data names like UNG_M_IND, DCODE
  # Era 2 (2004-2010): Some files have description rows, but column names start with data names

  # Era 3 (2016+): 3-row header (title, blank rows, then column names at row 4)

  # Peek at first few rows to detect format
  peek <- readxl::read_xlsx(
    file_path,
    sheet = sheet_name,
    n_max = 5,
    col_types = "text"
  )

  first_col_name <- names(peek)[1]

  # Detect skip rows based on actual content
  # If first column name looks like a data column, skip = 0
  # Data column patterns: DCODE, BCODE, Level, tot_*, k_*, g1_*, UNG_*, TOT_*, K_*, etc.
  data_col_patterns <- c(
    "^(District|Building|DCODE|BCODE|Level)",  # ID columns
    "^(tot_|k_|g[0-9]|UNG_|TOT_|K_|G[0-9]|PK_)",  # Data columns (various eras)
    "^(DNAME|BNAME|ISD)"  # Name columns
  )

  is_data_col <- any(sapply(data_col_patterns, function(p) grepl(p, first_col_name, ignore.case = TRUE)))

  if (is_data_col) {
    skip_rows <- 0
  } else {
    # Check if row 4 has data column names (skip = 3)
    # Look at the first column values - if row 4 contains "Level" or data patterns, skip 3
    if (nrow(peek) >= 4) {
      row4_val <- peek[[1]][4]
      if (!is.na(row4_val) && any(sapply(data_col_patterns, function(p) grepl(p, row4_val, ignore.case = TRUE)))) {
        skip_rows <- 3
      } else {
        # Default: try skip = 0 for legacy files
        skip_rows <- 0
      }
    } else {
      skip_rows <- 0
    }
  }

  df <- readxl::read_xlsx(
    file_path,
    sheet = sheet_name,
    skip = skip_rows,
    col_types = "text"  # Read all as text, convert later
  )

  # Remove empty rows and metadata rows
  # Common markers: "Return to", "End of", NA in first column
  if (nrow(df) > 0) {
    first_col <- names(df)[1]

    # Handle case where first column might be NA
    if (!is.na(first_col) && first_col != "NA") {
      # Remove rows where first column is NA
      df <- df[!is.na(df[[first_col]]), , drop = FALSE]

      # Remove metadata rows
      if (nrow(df) > 0) {
        df <- df[!grepl("^Return|^End of", df[[first_col]], ignore.case = TRUE), , drop = FALSE]
      }
    }
  }

  df
}
