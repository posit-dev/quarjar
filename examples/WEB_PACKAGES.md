# Web Packages in quarjar

## Overview

Web packages allow you to upload SCORM packages, HTML5 web content, and other packaged learning materials to Skilljar. Unlike MODULAR lessons that embed HTML directly, web packages are uploaded as ZIP files and hosted by Skilljar.

## Supported Content Types

- **SCORM 1.2 packages**
- **SCORM 2004 packages**
- **HTML5 web content** (self-contained web applications)
- **xAPI/Tin Can packages**

## Quick Start

### 1. Host Your ZIP File

**Important:** Your ZIP file must be hosted on a publicly accessible URL. This could be:
- Your own web server
- A CDN
- Cloud storage with public access enabled

### 2. Create Web Package

```r
library(quarjar)

pkg <- create_web_package(
  content_url = "https://example.com/my-scorm-package.zip",
  title = "Introduction to R Programming"
)
```

### 3. Create a Lesson

Associate the web package with a lesson:

```r
lesson <- create_lesson_with_web_package(
  course_id = "your-course-id",
  lesson_title = "Module 1: Introduction",
  web_package_id = pkg$id
)
```

## Complete Workflow

```r
library(quarjar)

# Set API key
Sys.setenv(SKILLJAR_API_KEY = "your-key-here")

# Step 1: Upload the package
pkg <- upload_web_package(
  zip_path = "scorm-packages/module1.zip",
  title = "Module 1: Getting Started with R",
  redirect_on_completion = TRUE,
  sync_on_completion = FALSE
)

cat("Package uploaded with ID:", pkg$id, "\n")
cat("Package type:", pkg$type, "\n")

# Step 2: Wait for processing (optional)
# Skilljar processes the package asynchronously
# You can check status:
pkg_details <- get_web_package(web_package_id = pkg$id)
cat("Processing state:", pkg_details$state, "\n")

# Step 3: Create lesson with the package
lesson <- create_lesson_with_web_package(
  course_id = "abc123",
  lesson_title = "Module 1: Getting Started with R",
  web_package_id = pkg$id,
  description = "<p>Complete this interactive module to learn R basics.</p>"
)

cat("Lesson created with ID:", lesson$id, "\n")
```

## Managing Web Packages

### List All Packages

```r
packages <- list_web_packages(page = 1, page_size = 20)

cat("Total packages:", packages$count, "\n")

for (pkg in packages$results) {
  cat("  -", pkg$title, "(", pkg$type, ")\n")
}
```

### Get Package Details

```r
pkg <- get_web_package(web_package_id = "pkg123")

cat("Title:", pkg$title, "\n")
cat("Type:", pkg$type, "\n")
cat("Download URL:", pkg$download_url, "\n")
cat("(Download URL valid for 1 hour)\n")
```

### Delete Package

```r
# Only works if package is not associated with any lessons
delete_web_package(web_package_id = "pkg123")
```

## Package Settings

### redirect_on_completion

When `TRUE` (default), users are redirected after completing the package. Set to `FALSE` if you want users to stay on the completion screen.

```r
pkg <- create_web_package(
  content_url = "https://example.com/package.zip",
  title = "My Package",
  redirect_on_completion = FALSE  # Stay on completion screen
)
```

### sync_on_completion

When `TRUE`, completion status is synchronized. Default is `FALSE`.

```r
pkg <- create_web_package(
  content_url = "https://example.com/package.zip",
  title = "My Package",
  sync_on_completion = TRUE  # Sync completion status
)
```

## Best Practices

### 1. Use Remote URLs for Production

For production workflows, upload your ZIP files to cloud storage (S3, GCS, Azure Blob) and use `create_web_package()` with the signed URL:

```r
# Upload to S3 first (using your preferred method)
s3_url <- upload_to_s3("local-file.zip")

# Then create web package
pkg <- create_web_package(
  content_url = s3_url,
  title = "My Course"
)
```

### 2. Validate ZIP Structure

Ensure your ZIP file contains:
- `imsmanifest.xml` (for SCORM)
- Entry point file (e.g., `index.html`)
- All referenced assets (images, CSS, JS)

### 3. Check Processing Status

Web packages are processed asynchronously. The `type` field is only available after processing:

```r
pkg <- upload_web_package(zip_path = "package.zip", title = "My Course")

# Immediately after upload, type might be NULL
cat("Type:", pkg$type, "\n")  # May be NULL

# Wait a moment and check again
Sys.sleep(5)
pkg_updated <- get_web_package(web_package_id = pkg$id)
cat("Type:", pkg_updated$type, "\n")  # Should show SCORM or HTML5
```

### 4. Reuse Web Packages

A single web package can be associated with multiple lessons:

```r
# Upload once
pkg <- upload_web_package(zip_path = "package.zip", title = "Shared Module")

# Use in multiple courses
lesson1 <- create_lesson_with_web_package(
  course_id = "course-1",
  lesson_title = "Introduction",
  web_package_id = pkg$id
)

lesson2 <- create_lesson_with_web_package(
  course_id = "course-2",
  lesson_title = "Introduction",
  web_package_id = pkg$id
)
```

## Troubleshooting

### "Cannot delete web package"

This means the package is associated with one or more lessons. Remove the lesson associations first, then delete the package.

### "Processing failed"

Check your ZIP file structure. Common issues:
- Missing `imsmanifest.xml` (for SCORM)
- Invalid manifest structure
- Missing entry point file
- File size too large

### "URL not accessible"

When using `create_web_package()` with a URL:
- Ensure the URL is publicly accessible
- For S3, generate a presigned URL with sufficient expiration time
- Check that the URL returns `application/zip` content type

## Examples

See `examples/web_package_example.R` for more complete examples.

## API Reference

Full documentation:
- `?create_web_package`
- `?upload_web_package`
- `?create_lesson_with_web_package`
- `?get_web_package`
- `?list_web_packages`
- `?delete_web_package`
