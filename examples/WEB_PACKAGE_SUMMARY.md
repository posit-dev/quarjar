# Web Package Summary

## What Was Implemented

The quarjar package now supports creating web packages (SCORM, HTML5, xAPI) in Skilljar.

## Key Functions

### `create_web_package()`
Create a web package from a publicly accessible ZIP URL.

```r
pkg <- create_web_package(
  content_url = "https://example.com/package.zip",
  title = "My Package"
)
```

### `create_lesson_with_web_package()`
Create a WEB_PACKAGE type lesson associated with a web package.

```r
lesson <- create_lesson_with_web_package(
  course_id = "abc123",
  lesson_title = "Module 1",
  web_package_id = pkg$id
)
```

### Management Functions
- `get_web_package(web_package_id)` - Get package details
- `list_web_packages()` - List all packages
- `delete_web_package(web_package_id)` - Delete a package

## Important Requirements

**Your ZIP file must be hosted on a publicly accessible URL.**

The Skilljar API does not support direct file uploads for web packages. You must:
1. Host your ZIP file on a web server, CDN, or cloud storage
2. Ensure the URL is publicly accessible
3. Use that URL with `create_web_package()`

## Complete Workflow

```r
library(quarjar)

# 1. Create web package (your ZIP must already be hosted)
pkg <- create_web_package(
  content_url = "https://your-server.com/scorm-package.zip",
  title = "Module 1: Introduction"
)

# 2. Create lesson
lesson <- create_lesson_with_web_package(
  course_id = "your-course-id",
  lesson_title = "Module 1: Introduction",
  web_package_id = pkg$id
)

cat("Lesson created:", lesson$id, "\n")
```

## Asset Functions (Separate Feature)

Assets are for PDFs, images, videos used within lessons - not for web packages.

Available functions:
- `upload_asset(file_path)` - Upload an asset file
- `get_asset(asset_id)` - Get asset details
- `list_assets()` - List all assets
- `delete_asset(asset_id)` - Delete an asset

## What Was Removed

- `upload_web_package()` - This function was removed because it cannot work. The Skilljar API requires pre-hosted URLs for web packages.

## Examples

See:
- `examples/web_package_example.R` - Complete examples
- `examples/WEB_PACKAGES.md` - Detailed documentation
