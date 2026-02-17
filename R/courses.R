#' Get Course Details
#'
#' Retrieves detailed information about a specific course.
#'
#' @param course_id Character. The ID of the Skilljar course.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
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
get_course <- function(course_id, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (missing(api_key) || is.null(api_key) || api_key == "") {
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
#'   Default is "https://api.skilljar.com".
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
list_lessons <- function(course_id, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  if (missing(course_id) || is.null(course_id)) {
    rlang::abort("course_id is required")
  }

  if (missing(api_key) || is.null(api_key) || api_key == "") {
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
#' @param course_id Character. The ID of the Skilljar course.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
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
get_next_lesson_order <- function(course_id, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  lessons <- list_lessons(course_id = course_id, api_key = api_key, base_url = base_url)

  if (length(lessons$results) == 0) {
    return(0L)
  }

  # Get all order values
  orders <- sapply(lessons$results, function(x) x$order)

  # Return max + 1
  as.integer(max(orders) + 1)
}
