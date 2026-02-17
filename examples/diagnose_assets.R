# Diagnostic Script for Asset Upload Issues
# ===========================================

library(quarjar)

# Set your API key
api_key <- Sys.getenv("SKILLJAR_API_KEY")
if (api_key == "") {
  stop("Please set SKILLJAR_API_KEY environment variable")
}

cat("=== Asset Diagnostics ===\n\n")

# Step 1: List existing assets to see the format
cat("1. Listing existing assets...\n")
tryCatch(
  {
    assets <- list_assets(page = 1, page_size = 5)
    cat("   Total assets:", assets$count, "\n")

    if (length(assets$results) > 0) {
      cat("\n   Sample assets:\n")
      for (i in seq_along(assets$results)) {
        asset <- assets$results[[i]]
        cat("   ", i, ". Name:", asset$name, "\n")
        cat("      Type:", asset$type, "\n")
        cat("      ID:", asset$id, "\n")
        if (!is.null(asset$embed_link_url) && asset$embed_link_url != "") {
          cat("      Embed URL:", substr(asset$embed_link_url, 1, 60), "...\n")
        }
        cat("\n")
      }

      # Get details for first asset to see full structure
      if (length(assets$results) > 0) {
        first_id <- assets$results[[1]]$id
        cat("2. Getting detailed info for first asset (", first_id, ")...\n")
        asset_detail <- get_asset(first_id)
        cat("   Full structure:\n")
        str(asset_detail, max.level = 1)
        cat("\n")

        if (!is.null(asset_detail$download_url) && asset_detail$download_url != "") {
          cat("   Download URL available: YES\n")
          cat("   Download URL (first 80 chars):", substr(asset_detail$download_url, 1, 80), "...\n")
        } else {
          cat("   Download URL available: NO\n")
        }
      }
    } else {
      cat("   No assets found in your organization\n")
    }
  },
  error = function(e) {
    cat("   ERROR listing assets:", conditionMessage(e), "\n")
  }
)

cat("\n")

# Step 2: Try to upload a test file
cat("3. Testing file upload...\n")

# Create a small test file (not a ZIP, just a simple file)
test_file <- tempfile(fileext = ".txt")
writeLines(c("Test file for asset upload", "Line 2", "Line 3"), test_file)
cat("   Created test file:", test_file, "\n")
cat("   File size:", file.size(test_file), "bytes\n")

test_asset_id <- NULL
tryCatch(
  {
    test_asset_id <- upload_asset(test_file)
    cat("   ✓ Upload successful! Asset ID:", test_asset_id, "\n")

    # Get the asset details
    cat("\n4. Getting uploaded asset details...\n")
    uploaded_asset <- get_asset(test_asset_id)
    cat("   Asset name:", uploaded_asset$name, "\n")
    cat("   Asset type:", uploaded_asset$type, "\n")

    if (!is.null(uploaded_asset$download_url) && uploaded_asset$download_url != "") {
      cat("   Download URL available: YES\n")
      cat("   Download URL (first 80 chars):", substr(uploaded_asset$download_url, 1, 80), "...\n")
    } else {
      cat("   Download URL available: NO (may still be processing)\n")
    }
  },
  error = function(e) {
    cat("   ✗ Upload failed with error:\n")
    cat("   ", conditionMessage(e), "\n")
  }
)

cat("\n")

# Step 3: Try with a ZIP file
cat("5. Testing ZIP file upload...\n")

# Create a simple ZIP file
zip_content <- tempfile(fileext = ".html")
writeLines("<html><body>Test</body></html>", zip_content)
test_zip <- tempfile(fileext = ".zip")
zip(test_zip, zip_content, flags = "-j", extras = "-q")

cat("   Created test ZIP:", test_zip, "\n")
cat("   ZIP size:", file.size(test_zip), "bytes\n")

zip_asset_id <- NULL
tryCatch(
  {
    zip_asset_id <- upload_asset(test_zip)
    cat("   ✓ ZIP upload successful! Asset ID:", zip_asset_id, "\n")

    # Get the asset details
    zip_uploaded <- get_asset(zip_asset_id)
    cat("   Asset name:", zip_uploaded$name, "\n")
    cat("   Asset type:", zip_uploaded$type, "\n")

    if (!is.null(zip_uploaded$download_url) && zip_uploaded$download_url != "") {
      cat("   Download URL available: YES\n")
      cat("   This URL can be used for web packages!\n")
    } else {
      cat("   Download URL available: NO (may still be processing)\n")
    }
  },
  error = function(e) {
    cat("   ✗ ZIP upload failed with error:\n")
    cat("   ", conditionMessage(e), "\n")
  }
)

# Clean up
unlink(test_file)
unlink(zip_content)
unlink(test_zip)

# Clean up uploaded test assets
if (!is.null(test_asset_id)) {
  cat("\n6. Cleaning up test asset...\n")
  tryCatch(
    {
      delete_asset(test_asset_id)
      cat("   ✓ Test text file deleted\n")
    },
    error = function(e) {
      cat("   Note: Could not delete test asset:", conditionMessage(e), "\n")
    }
  )
}

if (!is.null(zip_asset_id)) {
  tryCatch(
    {
      delete_asset(zip_asset_id)
      cat("   ✓ Test ZIP file deleted\n")
    },
    error = function(e) {
      cat("   Note: Could not delete ZIP asset:", conditionMessage(e), "\n")
    }
  )
}

cat("\n=== Summary ===\n")
cat("If ZIP upload worked, you can use upload_web_package() successfully!\n")
cat("If it failed, check the error message above for details.\n")
