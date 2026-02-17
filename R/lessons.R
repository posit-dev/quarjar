#' Get Lesson Details
#'
#' Retrieves detailed information about a specific lesson.
#'
#' @param lesson_id Character or numeric. The ID of the Skilljar lesson.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the lesson details.
#'
#' @examples
#' \dontrun{
#' lesson <- get_lesson(
#'   lesson_id = "12345",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' print(lesson$title)
#' }
#'
#' @export
get_lesson <- function(lesson_id, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  if (missing(lesson_id) || is.null(lesson_id)) {
    rlang::abort("lesson_id is required")
  }

  if (missing(api_key) || is.null(api_key) || api_key == "") {
    rlang::abort("api_key is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/lessons") |>
    httr2::req_url_path_append(as.character(lesson_id))

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) != 200) {
    rlang::abort(sprintf(
      "Failed to retrieve lesson. Status: %d, Body: %s",
      httr2::resp_status(resp),
      httr2::resp_body_string(resp)
    ))
  }

  httr2::resp_body_json(resp)
}

#' List Content Items in a Lesson
#'
#' Retrieves all content items for a specific lesson.
#'
#' @param lesson_id Character or numeric. The ID of the Skilljar lesson.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the content items.
#'
#' @examples
#' \dontrun{
#' items <- list_content_items(
#'   lesson_id = "12345",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' print(items)
#' }
#'
#' @export
list_content_items <- function(lesson_id, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  if (missing(lesson_id) || is.null(lesson_id)) {
    rlang::abort("lesson_id is required")
  }

  if (missing(api_key) || is.null(api_key) || api_key == "") {
    rlang::abort("api_key is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/lessons") |>
    httr2::req_url_path_append(as.character(lesson_id)) |>
    httr2::req_url_path_append("content-items")

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) != 200) {
    rlang::abort(sprintf(
      "Failed to list content items. Status: %d, Body: %s",
      httr2::resp_status(resp),
      httr2::resp_body_string(resp)
    ))
  }

  httr2::resp_body_json(resp)
}
