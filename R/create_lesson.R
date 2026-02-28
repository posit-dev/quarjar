#' Create a Lesson
#'
#' Creates a new lesson in a Skilljar course.
#'
#' @param course_id Character. The ID of the course to add the lesson to.
#' @param title Character. The title of the lesson.
#' @param type Character. The type of lesson. Default is "MODULAR" (supports multiple content items).
#'   Other options: "ASSET", "HTML", "WEB_PACKAGE", "QUIZ", "VILT", "SECTION".
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param order Numeric. Position of the lesson in the course. Default is 0.
#' @param description_html Character. HTML description of the lesson. Default is empty.
#' @param optional Logical. Whether the lesson is optional. Default is FALSE.
#' @param display_fullscreen Logical or NULL. Whether to display the lesson in
#'   fullscreen mode. When NULL (default), the field is omitted from the request
#'   and Skilljar uses its own default.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the created lesson details.
#'
#' @examples
#' \dontrun{
#' # Create a MODULAR lesson (type is MODULAR by default)
#' lesson <- create_lesson(
#'   course_id = "abc123",
#'   title = "Introduction to R"
#' )
#'
#' # Then add content items to it
#' publish_html_content(
#'   lesson_id = lesson$id,
#'   html_path = "content.html",
#'   title = "Lesson Content"
#' )
#' }
#'
#' @export
create_lesson <- function(
  course_id,
  title,
  type = "MODULAR",
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  order = 0,
  description_html = "",
  optional = FALSE,
  display_fullscreen = NULL,
  base_url = "https://api.skilljar.com"
) {
  # Validate inputs
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (missing(title) || is.null(title) || title == "") {
    rlang::abort("title is required")
  }

  if (api_key == "") {
    rlang::abort(
      "api_key is required. Set SKILLJAR_API_KEY environment variable or pass api_key argument."
    )
  }

  valid_types <- c(
    "ASSET",
    "HTML",
    "WEB_PACKAGE",
    "QUIZ",
    "VILT",
    "MODULAR",
    "SECTION"
  )
  if (!type %in% valid_types) {
    rlang::abort(sprintf(
      "Invalid lesson type '%s'. Must be one of: %s",
      type,
      paste(valid_types, collapse = ", ")
    ))
  }

  # Create lesson
  message(sprintf("Creating %s lesson '%s' (order: %d)...", type, title, order))

  body <- list(
    course_id = as.character(course_id),
    title = title,
    type = type,
    order = as.integer(order),
    description_html = description_html,
    optional = optional
  )
  if (!is.null(display_fullscreen)) {
    body$display_fullscreen <- as.logical(display_fullscreen)
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/lessons") |>
    httr2::req_body_json(body)

  resp <- perform_request(req, sprintf("create lesson '%s'", title))
  body <- httr2::resp_body_json(resp)
  cli::cli_alert_success("Lesson created with ID: {body$id}")

  invisible(body)
}

#' Create a Modular Lesson with HTML Content
#'
#' Convenience function that creates a MODULAR lesson and adds HTML content to it.
#' This is the typical workflow for publishing Quarto-rendered HTML.
#'
#' @param course_id Character. The ID of the course to add the lesson to.
#' @param lesson_title Character. The title of the lesson.
#' @param html_path Character. Path to the HTML file to publish.
#' @param content_title Character. Title for the content item within the lesson.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param lesson_order Numeric. Position of the lesson in the course. If NULL (default),
#'   automatically detects the next available order number.
#' @param content_order Numeric. Position of the content item in the lesson. Default is 0.
#' @param description_html Character. HTML description of the lesson. Default is empty.
#' @param display_fullscreen Logical or NULL. Whether to display the lesson in
#'   fullscreen mode. When NULL (default), the field is omitted from the request
#'   and Skilljar uses its own default.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list with two elements: `lesson` (the created lesson) and
#'   `content_item` (the created content item).
#'
#' @examples
#' \dontrun{
#' # Uses SKILLJAR_API_KEY environment variable
#' result <- create_lesson_with_content(
#'   course_id = "abc123",
#'   lesson_title = "Introduction to R",
#'   html_path = "output/intro.html",
#'   content_title = "Lesson Content"
#' )
#'
#' cat("Lesson ID:", result$lesson$id, "\n")
#' cat("Content Item ID:", result$content_item$id, "\n")
#' }
#'
#' @export
create_lesson_with_content <- function(
  course_id,
  lesson_title,
  html_path,
  content_title,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  lesson_order = NULL,
  content_order = 0,
  description_html = "",
  display_fullscreen = NULL,
  base_url = "https://api.skilljar.com"
) {
  # Auto-detect next order if not specified
  if (is.null(lesson_order)) {
    message("Auto-detecting next lesson order...")
    lesson_order <- get_next_lesson_order(
      course_id = course_id,
      api_key = api_key,
      base_url = base_url
    )
    message(sprintf("Using order: %d", lesson_order))
  }

  # Create MODULAR lesson
  lesson <- create_lesson(
    course_id = course_id,
    title = lesson_title,
    type = "MODULAR",
    api_key = api_key,
    order = lesson_order,
    description_html = description_html,
    display_fullscreen = display_fullscreen,
    base_url = base_url
  )

  # Add content to the lesson
  content_item <- publish_html_content(
    lesson_id = lesson$id,
    html_path = html_path,
    title = content_title,
    api_key = api_key,
    order = content_order,
    base_url = base_url
  )

  result <- list(
    lesson = lesson,
    content_item = content_item
  )

  cli::cli_alert_success(
    "Successfully created lesson '{lesson$title}' with content '{content_item$header}'"
  )

  invisible(result)
}
