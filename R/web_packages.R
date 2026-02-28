#' Create Web Package from Remote ZIP URL
#'
#' Creates a web package in Skilljar by providing a URL to a remotely hosted ZIP file.
#' The ZIP file can contain HTML5 content, SCORM packages, or other web-based learning content.
#' Skilljar will download and re-host the content.
#'
#' @param content_url Character. URL to the remotely hosted ZIP file containing the web package.
#' @param title Character. Title for the web package. May be overridden after processing.
#' @param redirect_on_completion Logical. Whether to redirect on completion. Default is TRUE.
#' @param sync_on_completion Logical. Whether to synchronize on completion. Default is FALSE.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the web package details including:
#'   \itemize{
#'     \item id - Web package ID
#'     \item type - Package type (determined after processing)
#'     \item title - Package title
#'     \item state - Processing state (e.g., \code{"READY"} when processing is complete)
#'     \item redirect_on_completion - Redirect setting
#'     \item sync_on_completion - Sync setting
#'   }
#'
#' @details
#' **Asynchronous Processing:** Web packages are processed asynchronously by Skilljar.
#' The package type is determined after processing the ZIP file.
#' Supported types include SCORM packages and HTML5 content.
#'
#' If you create a lesson immediately after creating a web package, it may fail if
#' processing hasn't completed. Consider using `get_web_package()` to check the
#' processing state before creating lessons, or implement retry logic.
#'
#' The content_url must be publicly accessible for Skilljar to download.
#' Consider using a temporary signed URL from a cloud storage service if needed.
#'
#' @examples
#' \dontrun{
#' # Create a web package from a remote ZIP file
#' pkg <- create_web_package(
#'   content_url = "https://example.com/my-scorm-package.zip",
#'   title = "Introduction to R Programming"
#' )
#'
#' # Create with custom completion settings
#' pkg <- create_web_package(
#'   content_url = "https://example.com/html5-course.zip",
#'   title = "Advanced Data Analysis",
#'   redirect_on_completion = FALSE,
#'   sync_on_completion = TRUE
#' )
#' }
#'
#' @export
create_web_package <- function(
  content_url,
  title,
  redirect_on_completion = TRUE,
  sync_on_completion = FALSE,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  # Validate inputs
  if (missing(content_url) || is.null(content_url) || content_url == "") {
    rlang::abort("content_url is required")
  }

  # Validate URL format
  if (!grepl("^https?://", content_url, ignore.case = TRUE)) {
    rlang::abort("content_url must be a valid HTTP or HTTPS URL")
  }

  if (missing(title) || is.null(title) || title == "") {
    rlang::abort("title is required")
  }

  if (api_key == "") {
    rlang::abort(
      "api_key is required. Set SKILLJAR_API_KEY environment variable or pass api_key argument."
    )
  }

  # Create request
  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/web-packages") |>
    httr2::req_body_json(list(
      content_url = content_url,
      web_package = list(
        title = title,
        redirect_on_completion = redirect_on_completion,
        sync_on_completion = sync_on_completion
      )
    ))

  resp <- perform_request(req, sprintf("create web package '%s'", title))
  body <- httr2::resp_body_json(resp)
  cli::cli_alert_success("Web package created with ID: {body$id}")

  invisible(body)
}


#' Get Web Package Details
#'
#' Retrieves detailed information for a specific web package.
#'
#' @param web_package_id Character. The ID of the web package to retrieve.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the web package details including:
#'   \itemize{
#'     \item id - Web package ID
#'     \item type - Package type (e.g., SCORM, HTML5)
#'     \item title - Package title
#'     \item state - Processing state (e.g., \code{"READY"} when processing is complete)
#'     \item download_url - Signed URL for downloading (valid for 1 hour)
#'     \item redirect_on_completion - Redirect setting
#'     \item sync_on_completion - Sync setting
#'   }
#'
#' @examples
#' \dontrun{
#' pkg <- get_web_package(web_package_id = "abc123")
#' cat("Package type:", pkg$type, "\n")
#' cat("Download URL:", pkg$download_url, "\n")
#' }
#'
#' @export
get_web_package <- function(
  web_package_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  if (missing(web_package_id) || is.null(web_package_id)) {
    rlang::abort("web_package_id is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/web-packages") |>
    httr2::req_url_path_append(as.character(web_package_id))

  resp <- perform_request(req, "retrieve web package")
  httr2::resp_body_json(resp)
}


#' List Web Packages
#'
#' Retrieves a paginated list of all web packages in your organization.
#'
#' @param page Integer. Page number to retrieve. Default is 1.
#' @param page_size Integer. Number of results per page. Default is 20.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing:
#'   \itemize{
#'     \item count - Total number of web packages
#'     \item next - URL for next page (if available)
#'     \item previous - URL for previous page (if available)
#'     \item results - List of web package summaries
#'   }
#'
#' @examples
#' \dontrun{
#' # List all web packages (first page)
#' packages <- list_web_packages()
#'
#' # List with custom page size
#' packages <- list_web_packages(page = 1, page_size = 50)
#' }
#'
#' @export
list_web_packages <- function(
  page = 1,
  page_size = 20,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/web-packages") |>
    httr2::req_url_query(
      page = as.integer(page),
      page_size = as.integer(page_size)
    )

  resp <- perform_request(req, "list web packages")
  httr2::resp_body_json(resp)
}


#' Delete Web Package
#'
#' Deletes a web package from your organization.
#' Deletion is only permitted if the web package is not associated with any lessons.
#'
#' @param web_package_id Character. The ID of the web package to delete.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return Invisible NULL on success.
#'
#' @examples
#' \dontrun{
#' delete_web_package(web_package_id = "abc123")
#' }
#'
#' @export
delete_web_package <- function(
  web_package_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  if (missing(web_package_id) || is.null(web_package_id)) {
    rlang::abort("web_package_id is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/web-packages") |>
    httr2::req_url_path_append(as.character(web_package_id)) |>
    httr2::req_method("DELETE")

  perform_request(req, "delete web package")
  cli::cli_alert_success("Web package {web_package_id} deleted")

  invisible(NULL)
}


#' Create Lesson with Web Package Content
#'
#' Creates a WEB_PACKAGE type lesson and associates it with an existing web package.
#' This is a convenience function that combines lesson creation with web package assignment.
#'
#' @param course_id Character. The ID of the course to add the lesson to.
#' @param lesson_title Character. Title for the lesson.
#' @param web_package_id Character. ID of an existing web package to associate with the lesson.
#' @param description Character. Optional description for the lesson.
#' @param display_fullscreen Logical or NULL. Whether to display the lesson in
#'   fullscreen mode. When NULL (default), the field is omitted from the request
#'   and Skilljar uses its own default.
#' @param order Integer. Optional position of the lesson in the course.
#'   If NULL (default), automatically uses the next available order number.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the lesson details.
#'
#' @examples
#' \dontrun{
#' # Create lesson with existing web package
#' lesson <- create_lesson_with_web_package(
#'   course_id = "course123",
#'   lesson_title = "SCORM Module 1",
#'   web_package_id = "pkg456"
#' )
#' }
#'
#' @export
create_lesson_with_web_package <- function(
  course_id,
  lesson_title,
  web_package_id,
  description = NULL,
  display_fullscreen = NULL,
  order = NULL,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  # Validate inputs
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (missing(lesson_title) || is.null(lesson_title) || lesson_title == "") {
    rlang::abort("lesson_title is required")
  }

  if (missing(web_package_id) || is.null(web_package_id)) {
    rlang::abort("web_package_id is required")
  }

  # Auto-detect order if not provided
  if (is.null(order)) {
    order <- get_next_lesson_order(
      course_id = course_id,
      api_key = api_key,
      base_url = base_url
    )
    cli::cli_alert_info("Using auto-detected order: {order}")
  }

  # Build lesson body
  lesson_body <- list(
    course_id = course_id,
    title = lesson_title,
    type = "WEB_PACKAGE",
    content_web_package_id = web_package_id,
    order = as.integer(order)
  )

  # Add optional description
  if (!is.null(description)) {
    lesson_body$description_html <- description
  }

  # Add optional display_fullscreen
  if (!is.null(display_fullscreen)) {
    lesson_body$display_fullscreen <- as.logical(display_fullscreen)
  }

  # Create the lesson
  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/lessons") |>
    httr2::req_body_json(lesson_body)

  resp <- perform_request(req, sprintf("create lesson '%s'", lesson_title))
  body <- httr2::resp_body_json(resp)
  cli::cli_alert_success("Lesson created with ID: {body$id}")

  invisible(body)
}
