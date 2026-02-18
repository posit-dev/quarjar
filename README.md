# quarjar

R package for publishing Quarto-rendered HTML content to Skilljar lessons.

**quarjar** (Quarto + Jar) streamlines the workflow of publishing Quarto documents directly to Skilljar courses, making it easy to maintain training materials as code.

## Installation

Install from GitHub:

```r
# install.packages("remotes")
remotes::install_github("posit-dev/quarjar")
```

## Usage

### Important: Lesson Types

Skilljar has different lesson types. To publish HTML content items, you must use a **MODULAR** lesson type.

- **MODULAR** - Can contain multiple content items (use this for publishing HTML)
- **WEB_PACKAGE** - For SCORM packages and HTML5 web content (see Web Packages section)
- **ASSET** - Single asset (video, PDF, etc.)
- **HTML** - Single HTML content directly on lesson
- Other types: QUIZ, VILT, SECTION

### Quick Start: Create Lesson and Publish Content

The easiest way to publish HTML content is to create a MODULAR lesson and add content in one call:

```r
library(quarjar)

# Set your API credentials
api_key <- Sys.getenv("SKILLJAR_API_KEY")
course_id <- "your-course-id"

# Create MODULAR lesson and publish HTML content
result <- create_lesson_with_content(
  course_id = course_id,
  lesson_title = "Introduction to R",
  html_path = "output/lesson.html",
  content_title = "Lesson Content",
  api_key = api_key
)

cat("Lesson ID:", result$lesson$id, "\n")
cat("Content Item ID:", result$content_item$id, "\n")
```

### Publish to Existing MODULAR Lesson

If you already have a MODULAR lesson:

```r
library(quarjar)

# Set your API credentials
api_key <- Sys.getenv("SKILLJAR_API_KEY")
lesson_id <- "12345"  # Must be a MODULAR lesson

# Publish HTML content
result <- publish_html_content(
  lesson_id = lesson_id,
  html_path = "path/to/your/content.html",
  title = "My Lesson Content",
  api_key = api_key,
  order = 0  # Position in lesson (0 = first)
)

cat("Published content item ID:", result$id, "\n")
```

### Create MODULAR Lesson Only

To create a MODULAR lesson without immediately adding content:

```r
lesson <- create_lesson(
  course_id = course_id,
  title = "My Lesson",
  type = "MODULAR",
  api_key = api_key
)

# Later, add content to it
publish_html_content(
  lesson_id = lesson$id,
  html_path = "content.html",
  title = "Content",
  api_key = api_key
)
```

### Environment Variables

For convenience, you can set environment variables:

```bash
export SKILLJAR_API_KEY="your-api-key"
export SKILLJAR_LESSON_ID="your-lesson-id"
```

Then use them in R:

```r
publish_html_content(
  lesson_id = Sys.getenv("SKILLJAR_LESSON_ID"),
  html_path = "content.html",
  title = "Lesson Title",
  api_key = Sys.getenv("SKILLJAR_API_KEY")
)
```

## Generating ZIP Packages

### `generate_zip_package()`

Render a Quarto document and package it as a ZIP file for upload as a web package.

```r
# Generate ZIP from Quarto document
zip_path <- generate_zip_package("lesson.qmd")
# Creates: "lesson.zip" containing rendered HTML
```

**Parameters:**
- `qmd_path`: Path to the Quarto (.qmd) file
- `quiet`: Suppress rendering messages (default: FALSE)
- `overwrite`: Overwrite existing ZIP file (default: TRUE)

**Returns:** Path to the created ZIP file (invisibly).

**Workflow:**
1. Renders the .qmd file to HTML
2. Outputs to a temporary directory
3. Creates a ZIP package
4. Upload the ZIP to your server

## Web Packages (SCORM & HTML5)

For SCORM packages or standalone HTML5 web content, you need to host your ZIP file on a publicly accessible URL, then create the web package:

```r
library(quarjar)

# Your ZIP file must be hosted on a publicly accessible URL
# (e.g., on your own web server, CDN, or cloud storage)
pkg <- create_web_package(
  content_url = "https://example.com/my-scorm-package.zip",
  title = "Introduction to R Programming"
)

cat("Web package ID:", pkg$id, "\n")
```

### Create a Lesson with Web Package

```r
# Create a WEB_PACKAGE lesson associated with your uploaded package
lesson <- create_lesson_with_web_package(
  course_id = "your-course-id",
  lesson_title = "Module 1: Introduction",
  web_package_id = pkg$id
)
```

### Complete Workflow

```r
# Create web package and lesson
# Note: Your ZIP must already be hosted at a publicly accessible URL

# Step 1: Create the web package from your hosted URL
pkg <- create_web_package(
  content_url = "https://example.com/module1.zip",
  title = "Module 1: Getting Started"
)

# Step 2: Wait briefly for processing (web packages process asynchronously)
Sys.sleep(2)

# Step 3: Create a lesson with the package
# If this fails, the package may still be processing - retry after a few moments
lesson <- create_lesson_with_web_package(
  course_id = "abc123",
  lesson_title = "Module 1: Getting Started",
  web_package_id = pkg$id
)
```

**Note:** Web packages are processed asynchronously by Skilljar. If lesson creation fails
immediately after creating the web package, wait a few moments and retry.

### Manage Web Packages

```r
# List all web packages
packages <- list_web_packages(page = 1, page_size = 20)

# Get details for a specific package (includes download URL)
pkg_details <- get_web_package(web_package_id = "pkg123")

# Delete a package (only if not associated with lessons)
delete_web_package(web_package_id = "pkg123")
```

## Functions

### HTML Content Functions

### `create_lesson_with_content()`

**Recommended** - One-step function to create a MODULAR lesson and add HTML content.

**Parameters:**
- `course_id`: The ID of the course to add the lesson to
- `lesson_title`: The title of the lesson
- `html_path`: Path to the HTML file to publish
- `content_title`: Title for the content item within the lesson
- `api_key`: Skilljar API key
- `lesson_order`: Position in course (default: 0)
- `content_order`: Position in lesson (default: 0)
- `description_html`: Lesson description (default: "")
- `base_url`: API base URL (optional)

**Returns:** List with `lesson` and `content_item` details.

### `create_lesson()`

Create a new lesson in a course.

**Parameters:**
- `course_id`: The ID of the course
- `title`: Lesson title
- `type`: Lesson type - use "MODULAR" for lessons with multiple content items
- `api_key`: Skilljar API key
- `order`: Position in course (default: 0)
- `description_html`: Lesson description (default: "")
- `optional`: Whether lesson is optional (default: FALSE)
- `base_url`: API base URL (optional)

**Returns:** List with the created lesson details.

### `publish_html_content()`

Publish HTML content to an existing MODULAR lesson. **Note:** The lesson must be type MODULAR.

**Parameters:**

- `lesson_id`: The ID of the target MODULAR lesson
- `html_path`: Path to the HTML file to publish
- `title`: Title for the content item
- `api_key`: Skilljar API key for authentication
- `order`: Position of the content item in the lesson (default: 0)
- `base_url`: Skilljar API base URL (default: "https://api.skilljar.com")

**Returns:** A list with the created content item details, including its ID.

### `get_lesson()`

Retrieve details about a lesson.

**Parameters:**
- `lesson_id`: Lesson ID
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** List with lesson details including type, title, etc.

### `list_content_items()`

List all content items in a lesson.

**Parameters:**
- `lesson_id`: Lesson ID
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** List with content items.

### `upload_asset()`

Lower-level function to upload a file as an asset.

**Parameters:**

- `file_path`: Path to the file to upload
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** The asset ID as a character string.

### Web Package Functions

### `create_web_package()`

Create a web package from a remote ZIP URL.

**Parameters:**
- `content_url`: URL to remotely hosted ZIP file
- `title`: Web package title
- `redirect_on_completion`: Redirect on completion (default: TRUE)
- `sync_on_completion`: Sync on completion (default: FALSE)
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** List with web package details including ID and type.

### `create_lesson_with_web_package()`

Create a WEB_PACKAGE type lesson with an existing web package.

**Parameters:**
- `course_id`: Course ID
- `lesson_title`: Lesson title
- `web_package_id`: ID of existing web package
- `description`: Optional lesson description
- `order`: Position in course (auto-detected if NULL)
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** List with lesson details.

### `get_web_package()`

Get details for a specific web package.

**Parameters:**
- `web_package_id`: Web package ID
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** List including download URL (valid for 1 hour).

### `list_web_packages()`

List all web packages in your organization.

**Parameters:**
- `page`: Page number (default: 1)
- `page_size`: Results per page (default: 20)
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** Paginated list of web packages.

### `delete_web_package()`

Delete a web package (only if not associated with lessons).

**Parameters:**
- `web_package_id`: Web package ID
- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** NULL on success.

### Utility Functions

### `skilljar_request()`

Creates a base httr2 request object configured for Skilljar API authentication.

**Parameters:**

- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** An httr2 request object.

## GitHub Actions

This repository includes GitHub Actions for automated publishing workflows.

### Automated Quarto to Skilljar Pipeline

**📖 Full Setup Guide**: See [GITHUB_ACTION_SETUP.md](GITHUB_ACTION_SETUP.md) for complete setup instructions, troubleshooting, and advanced configuration.

The `publish-quarto-to-skilljar.yml` workflow provides an end-to-end solution:

1. ✅ Renders your Quarto document to HTML
2. ✅ Packages it as a ZIP file with timestamped filename
3. ✅ Publishes the ZIP to GitHub Pages (provides public URL)
4. ✅ Creates a Skilljar web package from the GitHub Pages URL
5. ✅ Creates a WEB_PACKAGE lesson in your course

#### Quick Start

**Required Secrets:**
- `SKILLJAR_API_KEY` - Your Skilljar API key

**Required Setup:**
1. Enable GitHub Pages (Settings → Pages → Deploy from `gh-pages` branch)
2. Add `SKILLJAR_API_KEY` secret (Settings → Secrets and variables → Actions)
3. Set repository permissions to "Read and write" (Settings → Actions → General)

**Workflow Inputs:**
- `qmd-file`: Path to your Quarto (.qmd) file
- `course-id`: Skilljar course ID
- `lesson-title`: Title for the lesson in Skilljar
- `package-title`: (optional) Title for the web package
- `base-url`: (optional) Skilljar API base URL

#### Using in Your Repository

Create `.github/workflows/publish-to-skilljar.yml`:

```yaml
name: Publish to Skilljar

on:
  workflow_dispatch:
    inputs:
      qmd-file:
        description: 'Path to Quarto file'
        required: true
        type: string
      course-id:
        description: 'Skilljar course ID'
        required: true
        type: string
      lesson-title:
        description: 'Lesson title'
        required: true
        type: string

jobs:
  publish:
    uses: posit-dev/quarjar/.github/workflows/publish-quarto-to-skilljar.yml@main
    with:
      qmd-file: ${{ inputs.qmd-file }}
      course-id: ${{ inputs.course-id }}
      lesson-title: ${{ inputs.lesson-title }}
    secrets:
      SKILLJAR_API_KEY: ${{ secrets.SKILLJAR_API_KEY }}
```

### Legacy: Direct HTML Publishing

The `publish-to-skilljar.yml` workflow publishes HTML content directly to existing MODULAR lessons.

**Action Inputs:**
- `lesson-id`: (required) Target Skilljar lesson ID
- `html-file`: (required) Path to HTML file to publish
- `title`: (required) Content item title
- `base-url`: (optional) API base URL
- `order`: (optional) Position in lesson

**Note**: For creating new lessons from Quarto documents, use the automated pipeline above.

### Old Example (Legacy)

```yaml
name: Publish Lesson

on:
  workflow_dispatch:
    inputs:
      lesson-id:
        description: 'Skilljar lesson ID'
        required: true
      html-file:
        description: 'Path to HTML file'
        required: true
      title:
        description: 'Content item title'
        required: true

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Render Quarto document
        uses: quarto-dev/quarto-actions/setup@v2
      - run: quarto render content.qmd

      - name: Trigger publish workflow
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'publish-to-skilljar.yml',
              ref: 'main',
              inputs: {
                'lesson-id': '${{ inputs.lesson-id }}',
                'html-file': '${{ inputs.html-file }}',
                'title': '${{ inputs.title }}'
              }
            })
```

## Authentication

The Skilljar API uses HTTP Basic Authentication with:
- **Username**: Your API key
- **Password**: Empty string

Get your API key from your Skilljar account settings.

## License

MIT License - see LICENSE file for details.
