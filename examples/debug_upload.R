# Debug Asset Upload
# This script helps diagnose issues with uploading files to Skilljar

library(quarjar)
library(httr2)

# Set your API key
api_key <- Sys.getenv("SKILLJAR_API_KEY")

if (api_key == "") {
  stop("Please set SKILLJAR_API_KEY environment variable")
}

# Create a simple test ZIP file
test_zip <- tempfile(fileext = ".zip")
cat("Creating test ZIP file at:", test_zip, "\n")

# Create a simple file to zip
test_content <- tempfile(fileext = ".html")
writeLines("<html><body>Test</body></html>", test_content)

# Zip it
zip(test_zip, test_content, flags = "-j")

cat("Test ZIP created:", file.exists(test_zip), "\n")
cat("ZIP size:", file.size(test_zip), "bytes\n")

# Method 1: Try uploading with current implementation
cat("\n=== Method 1: Current Implementation ===\n")
tryCatch(
  {
    asset_id <- upload_asset(test_zip, api_key = api_key)
    cat("✓ Asset uploaded successfully! ID:", asset_id, "\n")

    # Get asset details
    asset_details <- httr2::request("https://api.skilljar.com") |>
      httr2::req_auth_basic(username = api_key, password = "") |>
      httr2::req_url_path_append("v1/assets") |>
      httr2::req_url_path_append(asset_id) |>
      httr2::req_perform() |>
      httr2::resp_body_json()

    cat("Asset type:", asset_details$type, "\n")
    cat("Asset name:", asset_details$name, "\n")
    cat("Download URL:", substr(asset_details$download_url, 1, 80), "...\n")
  },
  error = function(e) {
    cat("✗ Error:", conditionMessage(e), "\n")
  }
)

# Method 2: Try different multipart structure
cat("\n=== Method 2: Alternative Multipart Structure ===\n")
tryCatch(
  {
    req <- httr2::request("https://api.skilljar.com") |>
      httr2::req_auth_basic(username = api_key, password = "") |>
      httr2::req_url_path_append("v1/assets") |>
      httr2::req_body_multipart(
        file = curl::form_file(test_zip),
        asset = '{"name": "test-package.zip"}'
      )

    resp <- httr2::req_perform(req)
    body <- httr2::resp_body_json(resp)

    cat("✓ Alternative method worked! ID:", body$id, "\n")
  },
  error = function(e) {
    cat("✗ Error:", conditionMessage(e), "\n")
  }
)

# Method 3: Try with content_url instead of file upload
cat("\n=== Method 3: Using content_url ===\n")
cat("(This would require a publicly accessible URL)\n")

# Clean up
unlink(test_zip)
unlink(test_content)

cat("\n=== Summary ===\n")
cat("If Method 1 failed with HTTP 400, the issue might be:\n")
cat("  1. ZIP files are not accepted via asset endpoint\n")
cat("  2. The multipart structure needs adjustment\n")
cat("  3. Additional metadata is required\n")
cat("\nIf Method 1 succeeded, then we can use assets for web packages!\n")
