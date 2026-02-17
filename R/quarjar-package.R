#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' quarjar: Publish Quarto Content to Skilljar
#'
#' The quarjar package provides tools for publishing Quarto-rendered HTML content
#' to Skilljar lessons via the Skilljar API. It streamlines the workflow of
#' maintaining training materials as code and automatically publishing them to
#' your Skilljar courses.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{create_lesson_with_content}} - Create a MODULAR lesson and add HTML content (recommended)
#'   \item \code{\link{publish_html_content}} - Publish HTML to an existing MODULAR lesson
#'   \item \code{\link{create_lesson}} - Create a lesson (without content)
#'   \item \code{\link{get_lesson}} - Retrieve lesson details
#'   \item \code{\link{list_lessons}} - List lessons in a course
#' }
#'
#' @section Getting Started:
#' Set your Skilljar API key as an environment variable:
#' \preformatted{
#' Sys.setenv(SKILLJAR_API_KEY = "your-key-here")
#' }
#'
#' Then publish Quarto content:
#' \preformatted{
#' library(quarjar)
#' create_lesson_with_content(
#'   course_id = "your-course-id",
#'   lesson_title = "My Lesson",
#'   html_path = "output/lesson.html",
#'   content_title = "Content"
#' )
#' }
#'
#' @name quarjar-package
NULL
