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
- **ASSET** - Single asset (video, PDF, etc.)
- **HTML** - Single HTML content directly on lesson
- Other types: QUIZ, WEB_PACKAGE, VILT, SECTION

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

## Functions

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

### `skilljar_request()`

Creates a base httr2 request object configured for Skilljar API authentication.

**Parameters:**

- `api_key`: Skilljar API key
- `base_url`: API base URL (optional)

**Returns:** An httr2 request object.

## GitHub Action

This repository includes a GitHub Action for automated publishing. See `.github/workflows/publish-to-skilljar.yml` for the workflow definition.

### Action Inputs

- `lesson-id`: (required) Target Skilljar lesson ID
- `html-file`: (required) Path to HTML file to publish
- `title`: (required) Content item title
- `base-url`: (optional) API base URL
- `order`: (optional) Position in lesson

**Note**: The workflow reads the API key from the `SKILLJAR_API_KEY` secret automatically. You must configure this secret in your repository settings.

### Example Workflow Usage

To trigger the workflow manually:

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
