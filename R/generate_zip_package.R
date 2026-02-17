#' Generate ZIP Package from Quarto Document
#'
#' Renders a Quarto (.qmd) document to HTML and packages it into a ZIP file suitable
#' for upload as a web package to Skilljar. The rendered content is placed in a
#' staging directory and then zipped.
#'
#' @param qmd_path Character. Path to the Quarto (.qmd) file to render and package.
#' @param output_dir Character or NULL. Directory where the rendered output and ZIP file
#'   will be created. If NULL (default), uses the same directory as the .qmd file.
#' @param quiet Logical. If TRUE, suppresses rendering and zip creation messages.
#'   Default is FALSE.
#' @param overwrite Logical. If TRUE, overwrites existing ZIP file with the same name.
#'   If FALSE and ZIP file exists, throws an error. Default is TRUE.
#'
#' @return Character (invisibly). The absolute path to the created ZIP file.
#'
#' @details
#' This function performs the following steps:
#' \enumerate{
#'   \item Validates that the input is a .qmd file and that it exists
#'   \item Renders the Quarto document to HTML using \code{quarto::quarto_render()}
#'   \item Outputs the rendered HTML as "index.html" in a staging directory
#'     named "_<filename>" (e.g., "_lesson1" for "lesson1.qmd")
#'   \item Creates a ZIP file containing the rendered output directory
#'   \item Cleans up the staging directory after successful ZIP creation
#'   \item Returns the absolute path to the ZIP file
#' }
#'
#' By default, both the staging directory and the ZIP file are created
#' in the same directory as the source .qmd file. This can be changed using the
#' \code{output_dir} parameter.
#'
#' The output directory structure ensures that when the ZIP is extracted,
#' "index.html" is at the root level, which is required by most web package formats.
#'
#' The generated ZIP file can then be:
#' \itemize{
#'   \item Uploaded to a web server or cloud storage using \code{upload_asset()}
#'   \item Used to create a Skilljar lesson with \code{create_lesson_with_content()}
#' }
#'
#' @section Dependencies:
#' This function requires the \code{quarto} package and the Quarto CLI to be installed.
#'
#' @examples
#' \dontrun{
#' # Render and package a Quarto document (output in same directory as .qmd)
#' zip_path <- generate_zip_package("lessons/lesson1.qmd")
#' # Returns: "/path/to/lessons/lesson1.zip"
#'
#' # Specify a different output directory
#' zip_path <- generate_zip_package("lessons/lesson1.qmd", output_dir = "output")
#' # Returns: "output/lesson1.zip"
#'
#' # Quiet mode (suppress messages)
#' zip_path <- generate_zip_package("lesson1.qmd", quiet = TRUE)
#'
#' # Don't overwrite existing ZIP files
#' zip_path <- generate_zip_package("lesson1.qmd", overwrite = FALSE)
#'
#' # Complete workflow: Generate ZIP and create lesson with content
#' # Step 1: Generate the ZIP
#' zip_path <- generate_zip_package("module1.qmd")
#'
#' # Step 2: Upload the asset to Skilljar
#' asset <- upload_asset(zip_path, name = "Module 1 Content")
#'
#' # Step 3: Create lesson with the uploaded content
#' lesson <- create_lesson_with_content(
#'   course_id = 12345,
#'   title = "Module 1: Introduction",
#'   asset_id = asset$id
#' )
#' }
#'
#' @seealso
#' \code{\link{upload_asset}} for uploading assets to Skilljar,
#' \code{\link{create_lesson_with_content}} for creating lessons with content
#'
#' @importFrom utils zip
#' @export
generate_zip_package <- function(qmd_path, output_dir = NULL, quiet = FALSE, overwrite = TRUE) {
  if (tools::file_ext(qmd_path) != "qmd") {
    stop("Input file must have a .qmd extension.")
  }
  if (!file.exists(qmd_path)) {
    stop("File not found: ", qmd_path)
  }

  # Normalize qmd_path to absolute path
  qmd_path <- normalizePath(qmd_path, mustWork = TRUE)

  # Determine output directory (default to same directory as .qmd file)
  if (is.null(output_dir)) {
    output_dir <- normalizePath(dirname(qmd_path), mustWork = TRUE)
  } else {
    # Ensure output directory exists
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    output_dir <- normalizePath(output_dir, mustWork = TRUE)
  }

  file_name <- tools::file_path_sans_ext(basename(qmd_path))
  temp_output_dir <- file.path(output_dir, paste0("_", file_name))

  # Register cleanup of temp directory to ensure it's removed even on error
  on.exit(unlink(temp_output_dir, recursive = TRUE), add = TRUE)

  zip_file <- file.path(output_dir, paste0(file_name, ".zip"))
  if (!overwrite && file.exists(zip_file)) {
    cli::cli_abort(
      "Zip file already exists: {.file {zip_file}}. Use {.code overwrite = TRUE} to overwrite."
    )
  }

  quarto::quarto_render(
    input = qmd_path,
    output_file = "index.html",
    quarto_args = c("--output-dir", temp_output_dir),
    quiet = quiet
  )

  # Change to output directory for zipping (so zip contains relative paths)
  withr::with_dir(output_dir, {
    zip_extras <- if (quiet) "-q" else ""
    zip(zipfile = basename(zip_file), files = basename(temp_output_dir), extras = zip_extras)
  })

  if (!file.exists(zip_file)) {
    cli::cli_abort("Failed to create zip file: {.file {zip_file}}")
  }

  # Clean up the staging directory after successful zip creation
  unlink(temp_output_dir, recursive = TRUE)

  cli::cli_alert_success("Created zip file: {.file {zip_file}}")
  invisible(zip_file)
}
