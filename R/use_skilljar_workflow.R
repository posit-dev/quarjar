#' Use Skilljar Publishing Workflow
#'
#' Adds the GitHub Actions workflow for publishing Quarto documents to Skilljar
#' to your repository. This function copies the workflow file to
#' `.github/workflows/publish-quarto-to-skilljar.yml` in your project.
#'
#' @param overwrite Logical. If TRUE, overwrites an existing workflow file.
#'   Default is FALSE.
#'
#' @return Invisibly returns the path to the created workflow file.
#'
#' @details
#' This function sets up a complete CI/CD pipeline that:
#' \itemize{
#'   \item Renders your Quarto document to HTML
#'   \item Packages it as a ZIP file with a timestamped filename
#'   \item Publishes the ZIP to GitHub Pages in a `skilljar-zips/` subdirectory for public hosting
#'   \item Creates a Skilljar web package from the GitHub Pages URL
#'   \item Creates a WEB_PACKAGE lesson in your Skilljar course
#' }
#'
#' The workflow stores ZIP files in a `skilljar-zips/` subdirectory on the
#' `gh-pages` branch, allowing you to use GitHub Pages for other content
#' (like rendered Quarto documents) alongside the Skilljar publishing workflow.
#'
#' **Setup Requirements:**
#'
#' Before using this workflow, you must:
#' \enumerate{
#'   \item Enable GitHub Pages in your repository (Settings → Pages → Deploy from `gh-pages` branch)
#'   \item Add your Skilljar API key as a repository secret named `SKILLJAR_API_KEY`
#'   \item Set repository permissions to "Read and write" (Settings → Actions → General)
#' }
#'
#' **Usage:**
#'
#' After running this function, trigger the workflow from the Actions tab in your
#' GitHub repository with the following inputs:
#' \itemize{
#'   \item `qmd-file`: Path to your Quarto (.qmd) file
#'   \item `course-id`: Your Skilljar course ID
#'   \item `lesson-title`: Title for the lesson
#'   \item `package-title`: (optional) Title for the web package
#' }
#'
#' For complete setup instructions and troubleshooting, see the
#' [setup guide](https://github.com/posit-dev/quarjar/blob/main/GITHUB_ACTION_SETUP.md).
#'
#' @examples
#' \dontrun{
#' # Add the workflow to your project
#' use_skilljar_workflow()
#' }
#'
#' @export
use_skilljar_workflow <- function(overwrite = FALSE) {
  # Check that we're not in the quarjar package directory itself
  if (
    basename(getwd()) == "quarjar" && file.exists("R/use_skilljar_workflow.R")
  ) {
    cli::cli_abort(
      c(
        "This function should not be run from the quarjar package directory.",
        "i" = "Navigate to your project directory first, then run this function."
      )
    )
  }

  # Check if we're in a git repository
  if (!dir.exists(".git")) {
    cli::cli_abort(
      c(
        "This doesn't appear to be a Git repository.",
        "i" = "Initialize a Git repository first with {.code git init}"
      )
    )
  }

  # Create .github/workflows directory if it doesn't exist
  workflows_dir <- ".github/workflows"
  if (!dir.exists(workflows_dir)) {
    dir.create(workflows_dir, recursive = TRUE)
    cli::cli_alert_info("Created {.file {workflows_dir}/} directory")
  }

  # Target path for the workflow
  target_path <- file.path(workflows_dir, "publish-quarto-to-skilljar.yml")

  # Check if file already exists
  if (file.exists(target_path) && !overwrite) {
    if (interactive()) {
      cli::cli_text("Workflow file already exists at {.file {target_path}}")
      response <- readline(prompt = "Overwrite? (y/n): ")

      if (is.null(response) || !tolower(trimws(response)) %in% c("y", "yes")) {
        cli::cli_alert_info("Workflow installation cancelled.")
        return(invisible(NULL))
      }
    } else {
      # Non-interactive and file exists and overwrite not specified
      cli::cli_abort(
        c(
          "Workflow file already exists: {.file {target_path}}",
          "i" = "Set {.code overwrite = TRUE} to replace it"
        )
      )
    }
  }

  # Get source workflow file from package installation
  source_path <- system.file(
    "workflows",
    "publish-quarto-to-skilljar.yml",
    package = "quarjar",
    mustWork = TRUE
  )

  # Copy the workflow file
  file.copy(source_path, target_path, overwrite = overwrite)

  cli::cli_alert_success("Added GitHub Actions workflow: {.file {target_path}}")

  # Print setup instructions
  cli::cli_h2("Next Steps")

  cli::cli_ol(c(
    "Enable GitHub Pages in repository settings (Settings \u2192 Pages \u2192 Deploy from {.field gh-pages} branch)",
    "Add {.envvar SKILLJAR_API_KEY} secret (Settings \u2192 Secrets and variables \u2192 Actions)",
    "Set repository permissions to 'Read and write' (Settings \u2192 Actions \u2192 General)",
    "Commit and push the workflow file to your repository",
    "Trigger the workflow from the Actions tab"
  ))

  cli::cli_alert_info(
    "For complete setup instructions, see: {.url https://github.com/posit-dev/quarjar/blob/main/GITHUB_ACTION_SETUP.md}"
  )

  invisible(target_path)
}
