# Test Error Handling for Web Packages
# =====================================

library(quarjar)

# This script demonstrates the improved error handling

# Set your API key
Sys.setenv(SKILLJAR_API_KEY = "your-api-key-here")

# Test 1: Try to upload a web package
# ------------------------------------
# This will now show detailed error messages from the API
cat("\n=== Test 1: Attempting web package upload ===\n")

tryCatch(
  {
    pkg <- upload_web_package(
      zip_path = "/path/to/your/package.zip",
      title = "Test Package"
    )
    cat("Success! Package ID:", pkg$id, "\n")
  },
  error = function(e) {
    cat("\nError occurred:\n")
    cat(conditionMessage(e), "\n")
  }
)


# Test 2: Recommended approach with cloud storage
# -----------------------------------------------
cat("\n\n=== Test 2: Recommended cloud storage approach ===\n")

# Example with a publicly accessible URL
# (Replace with your actual URL)
cat("
Recommended workflow:

1. Upload your ZIP to cloud storage:
   - AWS S3: Use aws.s3::put_object()
   - GCS: Use googleCloudStorageR::gcs_upload()
   - Azure: Use AzureStor::storage_upload()

2. Get the public/presigned URL:
   s3_url <- 'https://my-bucket.s3.amazonaws.com/package.zip'

3. Create web package from URL:
   pkg <- create_web_package(
     content_url = s3_url,
     title = 'My Package'
   )

This approach is more reliable and works with all cloud providers.
")


# Test 3: Check if asset upload works for non-ZIP files
# -----------------------------------------------------
cat("\n\n=== Test 3: Testing asset upload (non-ZIP) ===\n")

# Create a test file
test_file <- tempfile(fileext = ".txt")
writeLines("Test content", test_file)

tryCatch(
  {
    asset_id <- upload_asset(file_path = test_file, api_key = Sys.getenv("SKILLJAR_API_KEY"))
    cat("Asset uploaded successfully! ID:", asset_id, "\n")
  },
  error = function(e) {
    cat("\nAsset upload error:\n")
    cat(conditionMessage(e), "\n")
  }
)

# Clean up
unlink(test_file)
