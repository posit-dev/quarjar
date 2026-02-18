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
#'   \item Cleans up the staging directory when ZIP creation succeeds or rendering fails
#'   \item Returns the absolute path to the ZIP file
#' }
#'
#' The function uses \code{withr::with_dir()} around \code{utils::zip()} to safely
#' manage working directory changes, ensuring the working directory is always restored even if errors occur.
#'
#' By default, both the staging directory and the ZIP file are created
#' in the same directory as the source .qmd file. This can be changed using the
#' \code{output_dir} parameter.
#'
#' Cleanup behavior: The staging directory is automatically cleaned up when ZIP
#' creation succeeds or when rendering fails. However, if rendering succeeds but
#' ZIP creation fails, the staging directory is preserved for debugging purposes.
#'
#' The output directory structure ensures that when the ZIP is extracted,
#' "index.html" is at the root level, which is required by most web package formats.
#'
#' The generated ZIP file can be manually uploaded to a web server or cloud storage,
#' and the resulting URL can be used to create a Skilljar web package lesson.
#' For guidance on uploading to a hosting service and configuring Skilljar,
#' see the package README (\code{README.md}).
#'
#' @section Dependencies:
#' This function requires the \code{quarto} R package and the Quarto CLI to be installed.
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
#' }
#'
#' @importFrom utils zip
#' @export
generate_zip_package <- function(
  qmd_path,
  output_dir = NULL,
  quiet = FALSE,
  overwrite = TRUE
) {
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

  zip_file <- file.path(output_dir, paste0(file_name, ".zip"))
  if (!overwrite && file.exists(zip_file)) {
    cli::cli_abort(
      "Zip file already exists: {.file {zip_file}}. Use {.code overwrite = TRUE} to overwrite."
    )
  }

  # Track whether rendering and zip creation succeeded for cleanup purposes
  rendering_succeeded <- FALSE
  zip_created <- FALSE

  # Register cleanup handler - will run on ANY exit (success or failure)
  on.exit(
    {
      if (zip_created) {
        # Clean up staging directory after successful zip creation
        unlink(temp_output_dir, recursive = TRUE)
      } else if (!rendering_succeeded) {
        # Clean up staging directory if rendering failed
        unlink(temp_output_dir, recursive = TRUE)
      }
      # If rendering succeeded but subsequent operations failed, preserve staging directory for debugging
    },
    add = TRUE
  )

  quarto::quarto_render(
    input = qmd_path,
    output_file = "index.html",
    quarto_args = c("--output-dir", temp_output_dir),
    quiet = quiet
  )

  # Mark rendering as successful
  rendering_succeeded <- TRUE

  # Change to output directory for zipping (so zip contains relative paths)
  withr::with_dir(output_dir, {
    zip_extras <- if (quiet) "-q" else ""
    # Uses utils::zip() with default compression level (-6)
    zip_exit_code <- zip(
      zipfile = basename(zip_file),
      files = basename(temp_output_dir),
      extras = zip_extras
    )

    # zip() returns 0 on success, non-zero error code on failure
    if (zip_exit_code != 0) {
      cli::cli_abort(
        c(
          "Failed to create zip file",
          "x" = "Exit code: {zip_exit_code}",
          "i" = "Zip file: {.file {zip_file}}"
        )
      )
    }
  })

  # Mark zip as successfully created (triggers cleanup in on.exit handler)
  zip_created <- TRUE

  cli::cli_alert_success("Created zip file: {.file {zip_file}}")
  invisible(zip_file)
}
