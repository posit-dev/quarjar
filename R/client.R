#' Create Skilljar API Request Base
#'
#' Creates a base httr2 request object configured for the Skilljar API
#' with authentication.
#'
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return An httr2 request object configured with base URL and authentication.
#'
#' @examples
#' \dontrun{
#' req <- skilljar_request()  # Uses SKILLJAR_API_KEY env var
#' }
#'
#' @export
skilljar_request <- function(
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  if (api_key == "") {
    rlang::abort(
      "api_key is required. Set SKILLJAR_API_KEY environment variable or pass api_key argument."
    )
  }

  httr2::request(base_url) |>
    httr2::req_auth_basic(username = api_key, password = "")
}
