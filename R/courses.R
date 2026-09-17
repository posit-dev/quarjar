#' Get Course Details
#'
#' Retrieves detailed information about a specific course.
#'
#' @param course_id Character. The ID of the Skilljar course.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Defaults to the \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#'
#' @return A list containing the course details.
#'
#' @examples
#' \dontrun{
#' course <- get_course(
#'   course_id = "abc123",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' print(course$title)
#' }
#'
#' @export
get_course <- function(
  course_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = quarjar_base_url()
) {
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (is.null(api_key) || api_key == "") {
    rlang::abort("api_key is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/courses") |>
    httr2::req_url_path_append(as.character(course_id))

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) != 200) {
    rlang::abort(sprintf(
      "Failed to retrieve course. Status: %d, Body: %s",
      httr2::resp_status(resp),
      httr2::resp_body_string(resp)
    ))
  }

  httr2::resp_body_json(resp)
}

#' List Lessons in a Course
#'
#' Retrieves all lessons for a specific course.
#'
#' @param course_id Character. The ID of the Skilljar course.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Defaults to the \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#'
#' @return A list containing the lessons.
#'
#' @examples
#' \dontrun{
#' lessons <- list_lessons(
#'   course_id = "abc123",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' print(length(lessons$results))
#' }
#'
#' @export
list_lessons <- function(
  course_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = quarjar_base_url()
) {
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (is.null(api_key) || api_key == "") {
    rlang::abort("api_key is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/lessons") |>
    httr2::req_url_query(course_id = course_id)

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) != 200) {
    rlang::abort(sprintf(
      "Failed to list lessons. Status: %d, Body: %s",
      httr2::resp_status(resp),
      httr2::resp_body_string(resp)
    ))
  }

  httr2::resp_body_json(resp)
}

#' Get Next Available Lesson Order
#'
#' Finds the next available order number for a new lesson in a course.
#'
#' Skilljar's dashboard spaces lesson orders in increments of 10, so this
#' function follows the same convention: it returns the highest order
#' currently in use plus 10. For an empty course it returns 0.
#'
#' @param course_id Character. The ID of the Skilljar course.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Defaults to the \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#'
#' @return Integer. The next available order number.
#'
#' @examples
#' \dontrun{
#' next_order <- get_next_lesson_order(
#'   course_id = "abc123",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' }
#'
#' @export
get_next_lesson_order <- function(
  course_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = quarjar_base_url()
) {
  orders <- get_lesson_orders(
    course_id = course_id,
    api_key = api_key,
    base_url = base_url
  )

  if (nrow(orders) == 0) {
    return(0L)
  }

  as.integer(max(orders$order) + 10L)
}

# Internal helper: check a requested lesson order against the orders already
# in use for a course, and either return the requested order unchanged or
# (depending on policy) abort with diagnostics / warn and shift to the next
# free order. `existing` is the data frame returned by get_lesson_orders().
resolve_lesson_order_conflict <- function(
  requested,
  existing,
  on_conflict = c("error", "auto"),
  course_id = "<unknown>"
) {
  on_conflict <- match.arg(on_conflict)
  requested <- as.integer(requested)

  if (nrow(existing) == 0 || !requested %in% existing$order) {
    return(requested)
  }

  clash <- existing[existing$order == requested, , drop = FALSE]
  next_free <- as.integer(max(existing$order) + 10L)

  if (on_conflict == "auto") {
    cli::cli_alert_warning(
      "Requested lesson order {.val {requested}} is already used in course
       {.val {course_id}} by lesson {.val {clash$lesson_id[1]}}
       ({clash$title[1]}); placing lesson at the next free order
       {.val {next_free}} instead."
    )
    return(next_free)
  }

  rlang::abort(c(
    sprintf(
      "Lesson order %d is already in use in course '%s'.",
      requested,
      course_id
    ),
    "x" = sprintf(
      "Currently held by lesson %s (%s).",
      clash$lesson_id[1],
      clash$title[1]
    ),
    "i" = sprintf(
      "Orders in use: %s.",
      paste(sort(existing$order), collapse = ", ")
    ),
    "i" = sprintf(
      "Pick an unused order (e.g. %d), or set
       {.field skilljar.on_order_conflict: auto} to place the lesson at the
       next free order instead.",
      next_free
    )
  ))
}
