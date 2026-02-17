#' Publish HTML Content to Skilljar Lesson
#'
#' Reads an HTML file and creates a content item in a Skilljar lesson with the HTML content.
#'
#' @param lesson_id Character or numeric. The ID of the Skilljar lesson (must be MODULAR type).
#' @param html_path Character. Path to the HTML file to publish.
#' @param title Character. Title for the content item.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param order Numeric. Position of the content item in the lesson. Default is 0.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the response from the Skilljar API, including the
#'   content item ID.
#'
#' @examples
#' \dontrun{
#' # Using environment variable
#' result <- publish_html_content(
#'   lesson_id = "12345",
#'   html_path = "output/lesson.html",
#'   title = "Introduction to R"
#' )
#' }
#'
#' @export
publish_html_content <- function(
  lesson_id,
  html_path,
  title,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  order = 0,
  base_url = "https://api.skilljar.com"
) {
  # Validate inputs
  if (missing(lesson_id) || is.null(lesson_id)) {
    rlang::abort("lesson_id is required")
  }

  if (missing(html_path) || !file.exists(html_path)) {
    rlang::abort(sprintf("HTML file not found: %s", html_path))
  }

  if (missing(title) || is.null(title) || title == "") {
    rlang::abort("title is required")
  }

  if (api_key == "") {
    rlang::abort(
      "api_key is required. Set SKILLJAR_API_KEY environment variable or pass api_key argument."
    )
  }

  # Step 1: Read HTML file content
  message("Reading HTML file...")
  lines <- readLines(html_path, warn = FALSE)
  html_content <- paste(lines, collapse = "\n")
  message(sprintf("  Read %d characters", nchar(html_content)))

  # Step 2: Create content item in lesson with HTML content
  message("Creating content item in lesson...")
  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/lessons") |>
    httr2::req_url_path_append(as.character(lesson_id)) |>
    httr2::req_url_path_append("content-items") |>
    httr2::req_body_json(list(
      type = "HTML",
      content_html = html_content,
      header = title,
      order = as.integer(order)
    ))

  resp <- perform_request(req, sprintf("create content item '%s'", title))
  body <- httr2::resp_body_json(resp)
  cli::cli_alert_success("Content item created with ID: {body$id}")

  invisible(body)
}
