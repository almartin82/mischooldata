# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Michigan Department of Education via MI School Data.
#
# Assessment systems:
# - MEAP (2007-2014): Michigan Educational Assessment Program (historical)
# - M-STEP (2015-present): Michigan Student Test of Educational Progress
# - No 2020 data due to COVID-19 pandemic testing waiver
#
# Data access limitation:
# Michigan's assessment data is served through the MI School Data portal
# (mischooldata.org) which uses interactive reports and the Report Builder.
# Direct download URLs are not publicly available for M-STEP data.
#
# Historical MEAP data URLs exist but michigan.gov's CDN blocks programmatic
# access. Users can download data manually from mischooldata.org and import
# using import_local_assessment().
#
# ==============================================================================


#' Get available assessment years
#'
#' Returns information about which years of assessment data are available
#' from the Michigan Department of Education.
#'
#' Assessment history:
#' - **MEAP** (2007-2014): Michigan Educational Assessment Program
#' - **M-STEP** (2015-present): Michigan Student Test of Educational Progress
#' - **2020**: No data due to COVID-19 pandemic testing waiver
#'
#' @return A list with components:
#'   \describe{
#'     \item{years}{Vector of available years}
#'     \item{min_year}{Earliest available year}
#'     \item{max_year}{Most recent available year}
#'     \item{gap_years}{Years with no data (2020)}
#'     \item{note}{Description of data availability}
#'   }
#' @export
#' @examples
#' get_available_assessment_years()
get_available_assessment_years <- function() {
  # MEAP: 2007-2014 (tested fall, data shows previous year content)
  # M-STEP: 2015-present (tested spring)
  # 2020: No testing due to COVID-19

  meap_years <- 2007:2014
  mstep_years <- c(2015:2019, 2021:2025)
  all_years <- sort(c(meap_years, mstep_years))

  list(
    years = all_years,
    min_year = min(all_years),
    max_year = max(all_years),
    gap_years = 2020,
    meap_years = meap_years,
    mstep_years = mstep_years,
    note = "2020 assessment data is not available due to COVID-19 testing waiver. MEAP (2007-2014) and M-STEP (2015-present) data available."
  )
}


#' Get assessment URL for historical MEAP data
#'
#' Returns the URL for historical MEAP assessment files.
#' Note: These URLs exist but michigan.gov CDN may block programmatic access.
#'
#' @param end_year School year end
#' @return URL string or NULL if not available
#' @keywords internal
get_assessment_url <- function(end_year) {

  base_url <- "https://www.michigan.gov/cepi/-/media/Project/Websites/cepi/MiSchoolData/historical/Historical_Assessments/"

  # Historical MEAP data (2009-2013)
  if (end_year >= 2009 && end_year <= 2013) {
    return(paste0(base_url, end_year, "MEAP.zip"))
  }

  # MME data
  if (end_year >= 2007 && end_year <= 2011) {
    return(paste0(base_url, "2007-2011MME.xlsx"))
  }

  if (end_year >= 2011 && end_year <= 2014) {
    return(paste0(base_url, "2011-2014MME.zip"))
  }

  # M-STEP (2015+): No direct download URLs available
  # Data must be accessed through MI School Data portal
  NULL
}


#' Download raw assessment data from Michigan DOE
#'
#' Attempts to download assessment data from Michigan Department of Education
#' sources. Due to data access limitations, this function may not be able to
#' download data for all years.
#'
#' **Important:** Michigan's assessment data is primarily available through the
#' MI School Data portal (mischooldata.org) which requires interactive access.
#' For M-STEP data (2015+), use import_local_assessment() with manually
#' downloaded files.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @param level Level of data to fetch: "all" (default), "state", "district", "school"
#' @return List with state, district, and/or school data frames
#' @keywords internal
get_raw_assessment <- function(end_year, level = "all") {

  # Validate year
  available <- get_available_assessment_years()

  if (end_year == 2020) {
    stop("Assessment data is not available for 2020 due to COVID-19 testing waiver.")
  }

  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year
    ))
  }

  message(paste("Attempting to download Michigan assessment data for", end_year, "..."))

  # Try to get the URL
  url <- get_assessment_url(end_year)

  if (is.null(url)) {
    # M-STEP years don't have direct download URLs
    warning(
      "Direct download not available for M-STEP data (2015+).\n",
      "Michigan provides M-STEP data through the MI School Data portal.\n",
      "Please download manually from: https://www.mischooldata.org/\n",
      "Then use import_local_assessment() to load the data.\n",
      "Returning empty data frame."
    )
    return(list(
      state = create_empty_assessment_raw(),
      district = create_empty_assessment_raw(),
      school = create_empty_assessment_raw()
    ))
  }

  # Attempt download (may fail due to CDN restrictions)
  result <- download_assessment_file(url, end_year, level)

  result
}


#' Download a single assessment file
#'
#' @param url URL to download
#' @param end_year School year end
#' @param level Data level
#' @return List with data frames
#' @keywords internal
download_assessment_file <- function(url, end_year, level) {

  # Determine file type
  is_zip <- grepl("\\.zip$", url, ignore.case = TRUE)
  file_ext <- if (is_zip) ".zip" else ".xlsx"

  # Create temp file
  tname <- tempfile(
    pattern = paste0("mi_assessment_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = file_ext
  )

  result <- tryCatch({
    # Download with browser user-agent (michigan.gov blocks default UA)
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"),
      httr::add_headers(
        "Accept" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel, */*",
        "Referer" = "https://www.mischooldata.org/"
      ),
      httr::timeout(180)
    )

    # Check for HTTP errors
    if (httr::http_error(response)) {
      warning(paste("HTTP error:", httr::status_code(response), "for URL:", url))
      unlink(tname)
      return(create_empty_result_list())
    }

    # Check file size (small files likely error pages)
    file_info <- file.info(tname)
    if (is.na(file_info$size) || file_info$size < 1000) {
      # Check if it's an HTML error page
      content <- tryCatch(
        readLines(tname, n = 5, warn = FALSE),
        error = function(e) ""
      )
      if (any(grepl("Access Denied|error|not found", content, ignore.case = TRUE))) {
        warning(
          "Michigan DOE server blocked programmatic access.\n",
          "Please download manually from: https://www.mischooldata.org/historical-assessment-data-files/\n",
          "Then use import_local_assessment() to load the data."
        )
        unlink(tname)
        return(create_empty_result_list())
      }
    }

    # Read the file
    df <- read_assessment_file(tname, is_zip, end_year)

    unlink(tname)
    df

  }, error = function(e) {
    message(paste("Download error:", e$message))
    unlink(tname)
    create_empty_result_list()
  })

  result
}


#' Read assessment file (Excel or ZIP)
#'
#' @param filepath Path to downloaded file
#' @param is_zip TRUE if ZIP file
#' @param end_year School year end
#' @return List with data frames
#' @keywords internal
read_assessment_file <- function(filepath, is_zip, end_year) {

  if (is_zip) {
    # Extract ZIP and read Excel files
    temp_dir <- tempdir()
    utils::unzip(filepath, exdir = temp_dir)

    # Find Excel files in extracted contents
    excel_files <- list.files(temp_dir, pattern = "\\.(xlsx|xls)$", full.names = TRUE, recursive = TRUE)

    if (length(excel_files) == 0) {
      warning("No Excel files found in ZIP archive")
      return(create_empty_result_list())
    }

    # Read all Excel files and combine
    all_data <- purrr::map_df(excel_files, function(f) {
      tryCatch({
        suppressMessages(readxl::read_excel(f, col_types = "text"))
      }, error = function(e) {
        message(paste("  Error reading", basename(f), ":", e$message))
        data.frame()
      })
    })

    # Clean up extracted files
    unlink(excel_files)

    # Categorize into state/district/school
    categorize_assessment_data(all_data, end_year)

  } else {
    # Read Excel file directly
    df <- tryCatch({
      suppressMessages(readxl::read_excel(filepath, col_types = "text"))
    }, error = function(e) {
      warning(paste("Error reading Excel file:", e$message))
      return(create_empty_result_list())
    })

    categorize_assessment_data(df, end_year)
  }
}


#' Categorize assessment data into state/district/school levels
#'
#' @param df Data frame from Excel file
#' @param end_year School year end
#' @return List with state, district, school data frames
#' @keywords internal
categorize_assessment_data <- function(df, end_year) {

  if (nrow(df) == 0) {
    return(create_empty_result_list())
  }

  # Add end_year
  df$end_year <- end_year

  # Clean column names
  names(df) <- tolower(gsub("\\s+", "_", trimws(names(df))))

  # Try to identify level based on columns or values
  # MEAP data typically has DistrictCode, BuildingCode columns

  has_building <- any(grepl("building|school|bcode", names(df), ignore.case = TRUE))
  has_district <- any(grepl("district|dcode", names(df), ignore.case = TRUE))

  # For now, return all data as school-level (most granular)
  # Processing will further categorize
  list(
    state = data.frame(),
    district = data.frame(),
    school = df
  )
}


#' Import local assessment data file
#'
#' Imports assessment data from a locally downloaded Excel file.
#' Use this when direct download is not available (M-STEP data).
#'
#' To download M-STEP data:
#' 1. Visit https://www.mischooldata.org/
#' 2. Navigate to Grades 3-8 State Testing or High School State Testing
#' 3. Use Report Builder to create and export data
#' 4. Save the exported Excel file
#' 5. Use this function to import
#'
#' @param filepath Path to the local Excel file
#' @param end_year School year the data represents
#' @param level Level of data: "all", "state", "district", "school"
#' @return Data frame with assessment data
#' @export
#' @examples
#' \dontrun{
#' # Import manually downloaded M-STEP data
#' mstep <- import_local_assessment("~/Downloads/mstep_2024.xlsx", 2024)
#' }
import_local_assessment <- function(filepath, end_year, level = "all") {

  if (!file.exists(filepath)) {
    stop(paste("File not found:", filepath))
  }

  # Validate year
  available <- get_available_assessment_years()
  if (!end_year %in% available$years) {
    warning(paste("Year", end_year, "not in expected range. Proceeding anyway."))
  }

  message(paste("Importing local assessment file for", end_year, "..."))

  # Read the Excel file
  df <- tryCatch({
    suppressMessages(readxl::read_excel(filepath, col_types = "text"))
  }, error = function(e) {
    stop(paste("Error reading Excel file:", e$message))
  })

  # Add end_year
  df$end_year <- end_year

  # Clean column names
  names(df) <- tolower(gsub("\\s+", "_", trimws(names(df))))

  # Return as list for compatibility with processing functions
  list(
    state = data.frame(),
    district = data.frame(),
    school = df
  )
}


#' Create empty assessment raw data frame
#'
#' Returns an empty data frame with expected column structure.
#'
#' @return Empty data frame
#' @keywords internal
create_empty_assessment_raw <- function() {
  data.frame(
    end_year = integer(0),
    district_code = character(0),
    district_name = character(0),
    building_code = character(0),
    building_name = character(0),
    grade = character(0),
    subject = character(0),
    subgroup = character(0),
    n_tested = integer(0),
    pct_proficient = numeric(0),
    stringsAsFactors = FALSE
  )
}


#' Create empty result list
#'
#' @return List with empty state, district, school data frames
#' @keywords internal
create_empty_result_list <- function() {
  list(
    state = create_empty_assessment_raw(),
    district = create_empty_assessment_raw(),
    school = create_empty_assessment_raw()
  )
}
