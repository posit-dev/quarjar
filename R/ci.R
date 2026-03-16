# CI helper functions -----------------------------------------------------------
# These functions are designed to be called from GitHub Actions workflow steps
# using `shell: Rscript {0}`.  Each function reads its inputs from environment
# variables (set via the workflow's `env:` block) and writes step outputs to
# $GITHUB_OUTPUT using the standard `key=value` format.
#
# Naming convention: ci_* prefix makes it unambiguous that these are CI
# helpers and not part of the regular user-facing API.

# Internal helper: write a key=value line to $GITHUB_OUTPUT
.ci_write_output <- function(key, value) {
  output_file <- Sys.getenv("GITHUB_OUTPUT")
  if (!nchar(output_file)) {
    cli::cli_alert_warning("GITHUB_OUTPUT not set; would write: {key}={value}")
    return(invisible(NULL))
  }
  cat(key, "=", value, "\n", sep = "", file = output_file, append = TRUE)
}


#' Generate a timestamped ZIP package (CI helper)
#'
#' Renders a Quarto document, appends a timestamp to the ZIP filename for
#' uniqueness, and writes \code{zip_path} and \code{zip_filename} to
#' \code{$GITHUB_OUTPUT}.  Intended for use in GitHub Actions via
#' \code{shell: Rscript \{0\}}.
#'
#' @section Environment variables:
#' \describe{
#'   \item{\code{QMD_FILE}}{Path to the \code{.qmd} file to render (required).}
#' }
#'
#' @param qmd_file Character. Path to the \code{.qmd} file.
#'   Defaults to the \code{QMD_FILE} environment variable.
#' @param quiet Logical. Suppress rendering messages. Default \code{FALSE}.
#'
#' @return Invisibly returns the path to the timestamped ZIP file.
#'
#' @examples
#' \dontrun{
#' # In a GitHub Actions step (shell: Rscript {0}):
#' library(quarjar)
#' ci_generate_zip()
#' }
#'
#' @export
ci_generate_zip <- function(
  qmd_file = Sys.getenv("QMD_FILE"),
  quiet = FALSE
) {
  if (!nchar(qmd_file)) {
    rlang::abort("qmd_file is required (set QMD_FILE env var or pass directly)")
  }

  zip_path <- generate_zip_package(qmd_file, quiet = quiet)

  base_name <- tools::file_path_sans_ext(basename(zip_path))
  timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
  timestamped_filename <- sprintf("%s-%s.zip", base_name, timestamp)
  timestamped_path <- file.path(dirname(zip_path), timestamped_filename)

  file.rename(zip_path, timestamped_path)

  .ci_write_output("zip_path", timestamped_path)
  .ci_write_output("zip_filename", timestamped_filename)

  cli::cli_alert_success("ZIP package created: {timestamped_path}")
  invisible(timestamped_path)
}


#' Create a Skilljar web package and wait for READY (CI helper)
#'
#' Creates a web package from a publicly accessible ZIP URL, polls until the
#' package \code{state} is \code{"READY"}, and (on the update path) captures
#' the ID of the web package currently attached to the lesson so it can be
#' deleted afterwards.  Writes \code{new_web_package_id} and
#' \code{old_web_package_id} to \code{$GITHUB_OUTPUT}.
#'
#' @section Environment variables:
#' \describe{
#'   \item{\code{ZIP_URL}}{Public URL of the ZIP file (required).}
#'   \item{\code{PACKAGE_TITLE}}{Title for the web package; falls back to
#'     \code{LESSON_TITLE} when empty.}
#'   \item{\code{LESSON_TITLE}}{Lesson title used as fallback package title.}
#'   \item{\code{LESSON_ID}}{Existing lesson ID; non-empty triggers the update
#'     path (capture of the old web package ID).}
#'   \item{\code{SKILLJAR_API_KEY}}{Skilljar API key.}
#'   \item{\code{BASE_URL}}{Skilljar API base URL. When unset, falls back to
#'     the \code{quarjar.base_url} option, then \code{"https://api.skilljar.com"}.}
#' }
#'
#' @param zip_url Character. Public URL of the ZIP file.
#' @param package_title Character. Title for the web package.
#'   Falls back to \code{lesson_title} when empty.
#' @param lesson_title Character. Lesson title used as fallback package title.
#' @param lesson_id Character. Existing lesson ID; non-empty triggers the
#'   update path.
#' @param api_key Character. Skilljar API key.
#' @param base_url Character. Skilljar API base URL. Defaults to the
#'   \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#' @param max_poll_attempts Integer. Maximum number of 10-second polling
#'   intervals. Default 12 (2 minutes total).
#'
#' @return Invisibly returns a named list with \code{new_web_package_id} and
#'   \code{old_web_package_id}.
#'
#' @examples
#' \dontrun{
#' # In a GitHub Actions step (shell: Rscript {0}):
#' library(quarjar)
#' ci_create_web_package()
#' }
#'
#' @export
ci_create_web_package <- function(
  zip_url = Sys.getenv("ZIP_URL"),
  package_title = Sys.getenv("PACKAGE_TITLE"),
  lesson_title = Sys.getenv("LESSON_TITLE"),
  lesson_id = Sys.getenv("LESSON_ID"),
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = Sys.getenv("BASE_URL", unset = quarjar_base_url()),
  max_poll_attempts = 12L
) {
  if (!nchar(zip_url)) {
    rlang::abort("zip_url is required (set ZIP_URL env var or pass directly)")
  }

  # Resolve package title
  if (!nchar(package_title)) {
    package_title <- lesson_title
  }
  if (!nchar(package_title)) {
    rlang::abort("package_title or lesson_title must be provided")
  }

  cli::cli_h2("Creating web package")
  pkg <- create_web_package(
    content_url = zip_url,
    title = package_title,
    api_key = api_key,
    base_url = base_url
  )
  cli::cli_alert_info("Web package ID: {pkg$id}")

  # Poll until READY
  cli::cli_h2("Waiting for web package processing")
  attempt <- 1L
  ready <- FALSE

  while (attempt <= max_poll_attempts) {
    cli::cli_alert_info("Polling attempt {attempt}/{max_poll_attempts}")
    Sys.sleep(10)

    pkg_status <- tryCatch(
      get_web_package(
        web_package_id = pkg$id,
        api_key = api_key,
        base_url = base_url
      ),
      error = function(e) {
        cli::cli_alert_warning("Error checking status: {conditionMessage(e)}")
        NULL
      }
    )

    if (!is.null(pkg_status)) {
      cli::cli_alert_info("Package state: {pkg_status$state}")
      if (identical(pkg_status$state, "READY")) {
        cli::cli_alert_success("Web package is READY")
        ready <- TRUE
        break
      }
    }

    attempt <- attempt + 1L
  }

  if (!ready) {
    cli::cli_alert_warning(
      "Web package not READY after {max_poll_attempts} attempts; proceeding anyway."
    )
  }

  # On the update path, capture the ID of the currently-attached web package
  old_pkg_id <- ""
  if (nchar(lesson_id) > 0) {
    lesson_existing <- get_lesson(
      lesson_id,
      api_key = api_key,
      base_url = base_url
    )
    old_pkg_id <- lesson_existing$content_web_package_id
    if (is.null(old_pkg_id) || is.na(old_pkg_id)) old_pkg_id <- ""
  }

  .ci_write_output("new_web_package_id", pkg$id)
  .ci_write_output("old_web_package_id", old_pkg_id)

  invisible(list(new_web_package_id = pkg$id, old_web_package_id = old_pkg_id))
}


#' Create or update a Skilljar lesson (CI helper)
#'
#' Routes to \code{\link{create_lesson_with_web_package}} (create path) or
#' \code{\link{update_lesson}} (update path) depending on whether
#' \code{lesson_id} is non-empty.  Writes \code{lesson_id} and
#' \code{is_new_lesson} (\code{"true"} / \code{"false"}) to
#' \code{$GITHUB_OUTPUT}.
#'
#' @section Environment variables:
#' \describe{
#'   \item{\code{LESSON_ID}}{Existing lesson ID; non-empty triggers the update
#'     path.}
#'   \item{\code{COURSE_ID}}{Course ID (create path only).}
#'   \item{\code{LESSON_TITLE}}{Lesson title (create path only).}
#'   \item{\code{NEW_WEB_PACKAGE_ID}}{New web package ID.}
#'   \item{\code{DISPLAY_FULLSCREEN}}{\code{"true"} or \code{"false"} (create
#'     path only; default \code{"true"}).}
#'   \item{\code{LESSON_ORDER}}{Integer lesson order (create path only; empty
#'     string triggers auto-detection).}
#'   \item{\code{SKILLJAR_API_KEY}}{Skilljar API key.}
#'   \item{\code{BASE_URL}}{Skilljar API base URL. When unset, falls back to
#'     the \code{quarjar.base_url} option, then \code{"https://api.skilljar.com"}.}
#' }
#'
#' @param lesson_id Character. Existing lesson ID. Non-empty triggers the
#'   update path.
#' @param course_id Character. Course ID (create path only).
#' @param lesson_title Character. Lesson title (create path only).
#' @param new_web_package_id Character. New web package ID.
#' @param display_fullscreen Logical or \code{NULL}. Fullscreen setting (create
#'   path only).  When \code{NULL}, resolved from the
#'   \code{DISPLAY_FULLSCREEN} env var (default \code{TRUE}).
#' @param lesson_order Integer, character, or \code{NULL}. Lesson order (create
#'   path only).  When \code{NULL}, resolved from the \code{LESSON_ORDER} env
#'   var; empty string triggers auto-detection.
#' @param api_key Character. Skilljar API key.
#' @param base_url Character. Skilljar API base URL. Defaults to the
#'   \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#'
#' @return Invisibly returns the lesson object returned by the API.
#'
#' @examples
#' \dontrun{
#' # In a GitHub Actions step (shell: Rscript {0}):
#' library(quarjar)
#' ci_create_or_update_lesson()
#' }
#'
#' @export
ci_create_or_update_lesson <- function(
  lesson_id = Sys.getenv("LESSON_ID"),
  course_id = Sys.getenv("COURSE_ID"),
  lesson_title = Sys.getenv("LESSON_TITLE"),
  new_web_package_id = Sys.getenv("NEW_WEB_PACKAGE_ID"),
  display_fullscreen = NULL,
  lesson_order = NULL,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = Sys.getenv("BASE_URL", unset = quarjar_base_url())
) {
  if (nchar(lesson_id) > 0) {
    # UPDATE PATH
    cli::cli_h2("Updating existing lesson")
    lesson <- update_lesson(
      lesson_id = lesson_id,
      content_web_package_id = new_web_package_id,
      api_key = api_key,
      base_url = base_url
    )
    .ci_write_output("is_new_lesson", "false")
  } else {
    # CREATE PATH
    cli::cli_h2("Creating new lesson")

    if (is.null(display_fullscreen)) {
      display_fullscreen <-
        tolower(Sys.getenv("DISPLAY_FULLSCREEN", unset = "true")) == "true"
    }

    if (is.null(lesson_order)) {
      lesson_order_raw <- Sys.getenv("LESSON_ORDER")
      lesson_order <- if (nchar(lesson_order_raw) > 0) {
        as.integer(lesson_order_raw)
      } else {
        NULL
      }
    }

    lesson <- create_lesson_with_web_package(
      course_id = course_id,
      lesson_title = lesson_title,
      web_package_id = new_web_package_id,
      display_fullscreen = display_fullscreen,
      order = lesson_order,
      api_key = api_key,
      base_url = base_url
    )
    .ci_write_output("is_new_lesson", "true")
  }

  .ci_write_output("lesson_id", lesson$id)
  invisible(lesson)
}


#' Safely delete the old Skilljar web package (CI helper)
#'
#' Attempts to delete a web package, emitting a warning (rather than an error)
#' on failure so that the workflow step does not fail.  Intended for the
#' clean-up step on the update path.
#'
#' @section Environment variables:
#' \describe{
#'   \item{\code{OLD_WEB_PACKAGE_ID}}{ID of the web package to delete.}
#'   \item{\code{SKILLJAR_API_KEY}}{Skilljar API key.}
#'   \item{\code{BASE_URL}}{Skilljar API base URL. When unset, falls back to
#'     the \code{quarjar.base_url} option, then \code{"https://api.skilljar.com"}.}
#' }
#'
#' @param old_web_package_id Character. ID of the web package to delete.
#' @param api_key Character. Skilljar API key.
#' @param base_url Character. Skilljar API base URL. Defaults to the
#'   \code{quarjar.base_url} option, falling back to
#'   \code{"https://api.skilljar.com"}.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @examples
#' \dontrun{
#' # In a GitHub Actions step (shell: Rscript {0}):
#' library(quarjar)
#' ci_delete_old_web_package()
#' }
#'
#' @export
ci_delete_old_web_package <- function(
  old_web_package_id = Sys.getenv("OLD_WEB_PACKAGE_ID"),
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = Sys.getenv("BASE_URL", unset = quarjar_base_url())
) {
  tryCatch(
    delete_web_package(
      web_package_id = old_web_package_id,
      api_key = api_key,
      base_url = base_url
    ),
    error = function(e) {
      cli::cli_alert_warning(
        "Could not delete old web package: {conditionMessage(e)}"
      )
    }
  )
  invisible(NULL)
}


#' Inject Skilljar lesson ID into QMD front matter (CI helper)
#'
#' Reads a Quarto document, appends \code{skilljar_lesson_id} to the YAML
#' front matter (if not already present), and writes the file back in place.
#' This replaces the Python front-matter-patching script used in the
#' "Write lesson ID back to main" workflow step, eliminating the Python
#' dependency for that step.
#'
#' The function exits silently (returning \code{FALSE}) if
#' \code{skilljar_lesson_id} is already present, so it is safe to call
#' idempotently.
#'
#' @section Environment variables:
#' \describe{
#'   \item{\code{QMD_FILE}}{Path to the \code{.qmd} file.}
#'   \item{\code{LESSON_ID}}{Skilljar lesson ID to inject.}
#' }
#'
#' @param qmd_file Character. Path to the \code{.qmd} file.
#' @param lesson_id Character. Skilljar lesson ID to inject.
#'
#' @return Invisibly returns \code{TRUE} if the file was modified,
#'   \code{FALSE} if \code{skilljar_lesson_id} was already present (file
#'   left unchanged).
#'
#' @examples
#' \dontrun{
#' # In a GitHub Actions step (shell: Rscript {0}):
#' library(quarjar)
#' ci_write_lesson_id()
#' }
#'
#' @export
ci_write_lesson_id <- function(
  qmd_file = Sys.getenv("QMD_FILE"),
  lesson_id = Sys.getenv("LESSON_ID")
) {
  if (!nchar(qmd_file)) {
    rlang::abort("qmd_file is required (set QMD_FILE env var or pass directly)")
  }
  if (!nchar(lesson_id)) {
    rlang::abort(
      "lesson_id is required (set LESSON_ID env var or pass directly)"
    )
  }
  if (!file.exists(qmd_file)) {
    rlang::abort(paste("File not found:", qmd_file))
  }

  lines <- readLines(qmd_file, warn = FALSE)
  sep_idx <- which(grepl("^---\\s*$", lines))

  if (length(sep_idx) < 2) {
    rlang::abort(paste("No YAML front matter found in", qmd_file))
  }

  fm_lines <- lines[seq(sep_idx[1] + 1L, sep_idx[2] - 1L)]

  if (any(grepl("^skilljar_lesson_id:", fm_lines))) {
    cli::cli_alert_info(
      "skilljar_lesson_id already present in {qmd_file} - no changes written"
    )
    return(invisible(FALSE))
  }

  # Append the new field just before the closing ---
  new_lines <- c(
    lines[seq_len(sep_idx[2] - 1L)],
    paste0('skilljar_lesson_id: "', lesson_id, '"'),
    lines[seq(sep_idx[2], length(lines))]
  )

  writeLines(new_lines, qmd_file)
  cli::cli_alert_success("Wrote skilljar_lesson_id to {qmd_file}")
  invisible(TRUE)
}
