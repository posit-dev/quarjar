#' Get Lesson Details
#'
#' Retrieves detailed information about a specific lesson.
#'
#' @param lesson_id Character or numeric. The ID of the Skilljar lesson.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Defaults to the \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
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
get_lesson <- function(
  lesson_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = quarjar_base_url()
) {
  if (missing(lesson_id) || is.null(lesson_id)) {
    rlang::abort("lesson_id is required")
  }

  if (is.null(api_key) || api_key == "") {
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
#'   Defaults to the \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
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
list_content_items <- function(
  lesson_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = quarjar_base_url()
) {
  if (missing(lesson_id) || is.null(lesson_id)) {
    rlang::abort("lesson_id is required")
  }

  if (is.null(api_key) || api_key == "") {
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

#' Get Lesson Order for a Course
#'
#' Retrieves the lesson order currently in use for a course, i.e. the
#' position of each lesson in the course curriculum as configured in
#' Skilljar.
#'
#' The Skilljar API does not have a dedicated "lesson order" endpoint.
#' Instead, every lesson returned by the lessons list endpoint
#' (\href{https://api.skilljar.com/docs/#lessons-list}{GET /v1/lessons})
#' carries an \code{order} field. This function collects all lessons for a
#' course (following pagination) and returns them sorted by \code{order}.
#'
#' @param course_id Character. The ID of the Skilljar course.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Defaults to the \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#' @param page_size Integer. Number of lessons to request per page
#'   (maximum 100).
#'
#' @return A data frame with one row per lesson and columns:
#'   \itemize{
#'     \item \code{lesson_id}: the lesson ID
#'     \item \code{title}: the lesson title
#'     \item \code{type}: the lesson type
#'     \item \code{order}: the lesson order value used by Skilljar
#'   }
#'   Rows are sorted by \code{order}. Returns an empty data frame if the
#'   course has no lessons.
#'
#' @examples
#' \dontrun{
#' orders <- get_lesson_orders(
#'   course_id = "abc123",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' print(orders)
#' }
#'
#' @export
get_lesson_orders <- function(
  course_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = quarjar_base_url(),
  page_size = 100
) {
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (is.null(api_key) || api_key == "") {
    rlang::abort("api_key is required")
  }

  fetch_page <- function(page) {
    req <- skilljar_request(api_key = api_key, base_url = base_url) |>
      httr2::req_url_path_append("v1/lessons") |>
      httr2::req_url_query(
        course_id = course_id,
        page = page,
        page_size = page_size
      )

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

  lessons <- list()
  page <- 1
  repeat {
    result <- fetch_page(page)
    lessons <- c(lessons, result$results)
    if (length(result[["next"]]) == 0 || result[["next"]] == "") {
      break
    }
    page <- page + 1
  }

  if (length(lessons) == 0) {
    return(
      data.frame(
        lesson_id = character(),
        title = character(),
        type = character(),
        order = integer()
      )
    )
  }

  orders <- data.frame(
    lesson_id = vapply(lessons, function(x) x$id, character(1)),
    title = vapply(lessons, function(x) x$title, character(1)),
    type = vapply(lessons, function(x) x$type, character(1)),
    order = vapply(lessons, function(x) as.integer(x$order), integer(1))
  )

  orders <- orders[order(orders$order), , drop = FALSE]
  rownames(orders) <- NULL
  orders
}
