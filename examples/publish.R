#!/usr/bin/env Rscript

# Example script for publishing HTML content to Skilljar
#
# Before running this script:
# 1. Set SKILLJAR_API_KEY environment variable
# 2. Set SKILLJAR_LESSON_ID environment variable
# 3. Ensure the HTML file exists
#
# Usage:
#   Rscript examples/publish.R

library(quarjar)

# Get credentials from environment
api_key <- Sys.getenv("SKILLJAR_API_KEY")
lesson_id <- Sys.getenv("SKILLJAR_LESSON_ID")

# Validate credentials
if (api_key == "") {
  stop("SKILLJAR_API_KEY environment variable is not set")
}

if (lesson_id == "") {
  stop("SKILLJAR_LESSON_ID environment variable is not set")
}

# Path to HTML file (relative to repository root)
html_path <- "examples/test.html"

# Check if file exists
if (!file.exists(html_path)) {
  stop(sprintf("HTML file not found: %s", html_path))
}

# Publish to Skilljar
cat("Publishing HTML content to Skilljar...\n")
cat(sprintf("Lesson ID: %s\n", lesson_id))
cat(sprintf("HTML file: %s\n", html_path))
cat("\n")

result <- publish_html_content(
  lesson_id = lesson_id,
  html_path = html_path,
  title = "Test Content - Skilljar Publisher",
  api_key = api_key,
  order = 0
)

cat("\n")
cat("✅ Successfully published content!\n")
cat(sprintf("Content Item ID: %s\n", result$id))
cat(sprintf("Content Item Header: %s\n", result$header))
cat(sprintf("Content Item Order: %s\n", result$order))
