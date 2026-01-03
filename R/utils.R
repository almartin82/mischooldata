# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Get available years for Michigan enrollment data
#'
#' Returns the range of years for which enrollment data can be fetched
#' from the Michigan Center for Educational Performance and Information (CEPI).
#'
#' @return A list with components:
#'   \describe{
#'     \item{min_year}{Earliest available year (1996)}
#'     \item{max_year}{Most recent available year (2024)}
#'     \item{description}{Human-readable description of the date range}
#'   }
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  list(
    min_year = 1996,
    max_year = 2025,
    description = "Michigan enrollment data is available from 1996 to 2025"
  )
}
