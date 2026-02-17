# Example: Creating and Managing Web Packages in Skilljar
# =========================================================

library(quarjar)

# Set your API key (do this once per session)
Sys.setenv(SKILLJAR_API_KEY = "your-api-key-here")

# Example 1: Create web package from a remote ZIP URL
# ----------------------------------------------------
# Your ZIP file must be hosted on a publicly accessible URL

web_pkg <- create_web_package(
  content_url = "https://example.com/my-scorm-package.zip",
  title = "Introduction to R Programming - SCORM"
)

cat("Created web package with ID:", web_pkg$id, "\n")
cat("Package type:", web_pkg$type, "\n")
cat("Package state:", web_pkg$state, "\n")


# Example 2: Get web package details
# -----------------------------------
pkg_details <- get_web_package(web_package_id = web_pkg$id)
cat("\nPackage Details:\n")
cat("  Title:", pkg_details$title, "\n")
cat("  Type:", pkg_details$type, "\n")
cat("  Download URL:", pkg_details$download_url, "\n")
cat("  (URL valid for 1 hour)\n")


# Example 3: List all web packages
# ---------------------------------
all_packages <- list_web_packages(page = 1, page_size = 20)
cat("\nTotal web packages:", all_packages$count, "\n")
cat("Showing packages:\n")
for (pkg in all_packages$results) {
  cat("  -", pkg$title, "(ID:", pkg$id, ")\n")
}


# Example 4: Create a lesson with the web package
# ------------------------------------------------
# This creates a WEB_PACKAGE type lesson and associates it with the package

lesson <- create_lesson_with_web_package(
  course_id = "your-course-id-here",
  lesson_title = "Module 1: Introduction",
  web_package_id = web_pkg$id,
  description = "<p>Complete this SCORM module to learn the basics.</p>"
)

cat("\nCreated lesson with ID:", lesson$id, "\n")


# Example 5: Delete a web package (only if not associated with lessons)
# ----------------------------------------------------------------------
# Uncomment to delete
# delete_web_package(web_package_id = "package-id-to-delete")


# Complete workflow example
# --------------------------
# Create a web package from a hosted URL and create a lesson

complete_workflow <- function(zip_url, course_id, lesson_title) {
  # Step 1: Create the web package from your hosted URL
  cat("Creating web package...\n")
  pkg <- create_web_package(
    content_url = zip_url,
    title = lesson_title
  )

  # Step 2: Create a lesson with the package
  cat("Creating lesson...\n")
  lesson <- create_lesson_with_web_package(
    course_id = course_id,
    lesson_title = lesson_title,
    web_package_id = pkg$id
  )

  cat("\n✓ Complete! Lesson ID:", lesson$id, "\n")

  return(list(package = pkg, lesson = lesson))
}

# Usage (your ZIP must already be hosted):
# result <- complete_workflow(
#   zip_url = "https://example.com/module1.zip",
#   course_id = "abc123",
#   lesson_title = "Module 1: Getting Started"
# )
