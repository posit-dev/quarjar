# CLAUDE.md - AI Assistant Context

This file provides context for AI assistants (like Claude) working on the quarjar package.

## Project Overview

**quarjar** is an R package for publishing Quarto-rendered HTML content to Skilljar lessons via the Skilljar API. It automates the workflow of creating lessons, uploading content, and managing course materials programmatically.

**Name origin:** Quarto + Jar (from Skilljar) = quarjar

## Architecture

### Core Components

1. **API Client** (`R/client.R`)
   - `skilljar_request()` - Base authenticated request builder
   - Uses httr2 with HTTP Basic Auth (API key as username, empty password)

2. **Publishing Functions** (`R/publish.R`)
   - `publish_html_content()` - Main function to add HTML content to MODULAR lessons
   - Reads HTML, creates content item via POST to `/v1/lessons/{id}/content-items`

3. **Lesson Management** (`R/create_lesson.R`)
   - `create_lesson()` - Creates lessons (default type: MODULAR)
   - `create_lesson_with_content()` - Convenience wrapper (recommended entry point)
   - Auto-detects next available lesson order

4. **Web Package Management** (`R/web_packages.R`)
   - `create_web_package()` - Create web package from remote ZIP URL
   - `create_lesson_with_web_package()` - Create WEB_PACKAGE lesson
   - `get_web_package()`, `list_web_packages()`, `delete_web_package()`
   - Supports SCORM packages and HTML5 web content
   - **Important:** Web packages are processed asynchronously by Skilljar

5. **Quarto Package Generation** (`R/generate_zip_package.R`)
   - `generate_zip_package()` - Render Quarto document and create ZIP package
   - Workflow: Renders .qmd → HTML → Creates timestamped ZIP file
   - Used as foundation for GitHub Actions automation
   - Returns path to created ZIP file (invisibly)

6. **Workflow Setup Helper** (`R/use_skilljar_workflow.R`)
   - `use_skilljar_workflow()` - Install GitHub Actions workflow in user's repository
   - Follows usethis package patterns for discoverability
   - Interactive prompts with `cli::cli_yesno()` for overwrite confirmation
   - Safety checks: Prevents running from quarjar package directory
   - Validates git repository before installation
   - Displays next steps and setup instructions after installation

7. **Course Helpers** (`R/courses.R`)
   - `get_course()`, `list_lessons()`, `get_next_lesson_order()`

8. **Lesson Helpers** (`R/lessons.R`)
   - `get_lesson()`, `list_content_items()`

9. **Asset Management** (`R/assets.R`)
   - `upload_asset()` - Upload files as assets (images, PDFs, videos)
   - `get_asset()`, `list_assets()`, `delete_asset()` - Manage assets
   - **Note:** Assets are separate from web packages

10. **Error Handling** (`R/utils.R`)
    - `perform_request()` - Centralized error handling with formatted API responses
    - Uses cli package for cross-platform symbols

### Key Design Decisions

1. **Lesson Types**
   - Skilljar has multiple lesson types (ASSET, HTML, QUIZ, WEB_PACKAGE, etc.)
   - Only **MODULAR** lessons support multiple content items
   - The package defaults to MODULAR for HTML publishing
   - **WEB_PACKAGE** lessons are for SCORM packages and HTML5 web content

2. **API Key Management**
   - All functions default to `Sys.getenv("SKILLJAR_API_KEY")`
   - Users set once, use everywhere

3. **Automatic Order Detection**
   - `create_lesson_with_content()` auto-detects next lesson position
   - Prevents "order already exists" errors

4. **CLI Package for Messages**
   - Uses `cli::cli_alert_success()` instead of UTF-8 characters
   - Better cross-platform compatibility (Windows, etc.)

5. **Web Package Processing**
   - Web packages are created via `create_web_package()` with pre-hosted ZIP URLs
   - Skilljar processes packages asynchronously
   - Lesson creation may fail if attempted before processing completes
   - No direct file upload - URLs must be publicly accessible

6. **Assets vs Web Packages**
   - Assets are for individual files (PDFs, images, videos) within lessons
   - Web packages are standalone packaged content (SCORM, HTML5)
   - These are separate features with different use cases

7. **GitHub Actions Automation**
   - Complete CI/CD pipeline via `inst/workflows/publish-quarto-to-skilljar.yml`
   - End-to-end: Quarto render → ZIP → GitHub Pages → Skilljar web package → lesson
   - Timestamped ZIP filenames for version management
   - Stores ZIPs in `skilljar-zips/` subdirectory (coexists with pkgdown sites, etc.)
   - Automatic cleanup (keeps 5 most recent ZIPs in subdirectory)
   - URL verification with retry logic (30 attempts over 5 minutes)
   - Users install via `use_skilljar_workflow()` helper function

## API Structure

### Authentication
```r
HTTP Basic Auth:
- Username: API key
- Password: (empty)
```

### Main Endpoints Used
- `POST /v1/lessons` - Create lesson
- `GET /v1/lessons/{id}` - Get lesson details
- `GET /v1/lessons?course_id={id}` - List lessons in course
- `POST /v1/lessons/{id}/content-items` - Add content to MODULAR lesson
- `GET /v1/lessons/{id}/content-items` - List content items
- `POST /v1/web-packages` - Create web package from remote ZIP URL
- `GET /v1/web-packages` - List web packages
- `GET /v1/web-packages/{id}` - Get web package details (includes download URL)
- `DELETE /v1/web-packages/{id}` - Delete web package
- `POST /v1/assets` - Upload asset file

### Content Item Structure
```json
{
  "type": "HTML",
  "content_html": "<html>...</html>",
  "header": "Content Title",
  "order": 0
}
```

## Common Issues & Solutions

### Issue 1: "Lesson must be type=MODULAR"
**Cause:** Trying to add content items to non-MODULAR lesson
**Solution:** Only use MODULAR lessons for HTML publishing

### Issue 2: "Lesson already exists with order=X"
**Cause:** Order number already used in course
**Solution:** Use `create_lesson_with_content()` which auto-detects order

### Issue 3: API key not found
**Cause:** SKILLJAR_API_KEY environment variable not set
**Solution:** Set via `Sys.setenv(SKILLJAR_API_KEY = "key")`

### Issue 4: GitHub Actions workflow fails with "Package installation failed"
**Cause:** Using `install_local()` instead of `install_github()` in workflow
**Solution:** Workflow should use `remotes::install_github("posit-dev/quarjar")`

### Issue 5: GitHub Pages URL not accessible immediately
**Cause:** GitHub Pages deployment is asynchronous
**Solution:** Workflow includes retry logic with URL verification (30 attempts, 5 minutes max)

### Issue 6: Running `use_skilljar_workflow()` from quarjar package directory
**Cause:** Attempting to install workflow in the quarjar package itself
**Solution:** Function includes safety check and aborts with helpful message

## Development Guidelines

### Adding New Functions

1. **Follow naming conventions:**
   - `get_*()` for retrieval
   - `list_*()` for collections
   - `create_*()` for creation
   - `publish_*()` for publishing

2. **Default parameters:**
   - `api_key = Sys.getenv("SKILLJAR_API_KEY")`
   - `base_url = "https://api.skilljar.com"`

3. **Error handling:**
   - Use `perform_request()` helper for API calls
   - Provides structured error messages

4. **Documentation:**
   - Include roxygen2 comments
   - Add `@examples` section (wrapped in `\dontrun{}`)
   - Reference package as `quarjar` in docs

### Testing

```r
# Load package
devtools::load_all(".")

# Set test credentials
Sys.setenv(SKILLJAR_API_KEY = "test-key")

# Test main workflow
result <- create_lesson_with_content(
  course_id = "test-course",
  lesson_title = "Test Lesson",
  html_path = "examples/test.html",
  content_title = "Test Content"
)
```

### Code Style

- Use `|>` pipe operator (base R)
- Use `httr2` for HTTP requests
- Use `cli` for user-facing messages
- Use `rlang::abort()` for errors
- Follow tidyverse style guide

## File Structure

```
quarjar/
├── R/
│   ├── assets.R                # Asset upload (not used in main workflow)
│   ├── client.R                # API authentication
│   ├── courses.R               # Course-level functions
│   ├── create_lesson.R         # Lesson creation (main entry point)
│   ├── generate_zip_package.R  # Quarto rendering and ZIP packaging
│   ├── lessons.R               # Lesson retrieval functions
│   ├── publish.R               # Content publishing
│   ├── quarjar-package.R       # Package documentation
│   ├── use_skilljar_workflow.R # GitHub Actions workflow installer
│   ├── utils.R                 # Error handling helpers
│   └── web_packages.R          # Web package management
├── inst/
│   └── workflows/
│       └── publish-quarto-to-skilljar.yml  # Reusable GitHub Actions workflow
├── examples/
│   ├── test.html              # Sample HTML for testing
│   ├── publish.R              # Example usage script
│   ├── GITHUB_ACTION_SETUP.md # Complete GitHub Actions setup guide
│   └── README.md              # Testing documentation
├── docs/
│   └── skilljar_api.yml   # Skilljar API OpenAPI spec
├── DESCRIPTION            # Package metadata
├── NAMESPACE              # Exported functions
├── README.md              # User documentation
└── CLAUDE.md              # This file
```

## Dependencies

**Required:**
- httr2 (>= 1.0.0) - HTTP client
- rlang (>= 1.0.0) - Error handling
- jsonlite - JSON parsing
- curl - File uploads
- cli - Cross-platform messages

**Development:**
- devtools - Package development
- roxygen2 - Documentation generation
- testthat - Testing (future)

## GitHub Actions Workflow Details

### Pipeline Architecture

The automated workflow (`inst/workflows/publish-quarto-to-skilljar.yml`) implements a complete end-to-end publishing pipeline:

**Pipeline Steps:**
1. **Render** - Uses Quarto to render .qmd to HTML
2. **Package** - Creates timestamped ZIP file (e.g., `lesson-20260218-143022.zip`)
3. **Publish** - Deploys ZIP to GitHub Pages via `gh-pages` branch in `skilljar-zips/` subdirectory
4. **Verify** - Actively checks URL accessibility with retry logic
5. **Create** - Makes Skilljar web package from public URL
6. **Lesson** - Creates WEB_PACKAGE lesson in specified course

**Key Features:**
- **Dual triggers**: Runs on `push` to `main` (auto-detects changed `.qmd` files) or manually via `workflow_dispatch`
- **Matrix fan-out**: One `render-and-publish` job per changed `.qmd` file; `fail-fast: false` so one failure doesn't cancel others
- **Front matter routing**: On push, course ID and title are read from `.qmd` YAML front matter (`skilljar-course-id`, `title`, optional `skilljar-package-title`)
- **Subdirectory isolation**: Stores ZIPs in `skilljar-zips/` subdirectory, coexists with other GitHub Pages content (pkgdown, etc.)
- **Timestamped filenames**: Unique names prevent conflicts, enable versioning
- **Automatic cleanup**: Keeps only 5 most recent ZIP files in subdirectory
- **Retry logic**: 30 attempts over 5 minutes to verify GitHub Pages deployment
- **URL verification**: Uses curl to actively check accessibility before proceeding
- **Non-destructive**: Uses regular push (not `--force`), preserves other gh-pages content
- **Serialized gh-pages pushes**: `max-parallel: 1` prevents concurrent matrix jobs from conflicting on the `gh-pages` branch

**Front matter fields for push trigger:**
```yaml
---
title: "My Lesson Title"          # used as lesson title
skilljar-course-id: "abc123"      # required for push trigger
skilljar-package-title: "..."     # optional; defaults to title
---
```
Files without `skilljar-course-id` are silently skipped.

### Installation Methods

**Recommended: Helper Function**
```r
# Users install workflow in their repository
quarjar::use_skilljar_workflow()
```

**Manual: Copy from inst/**
```bash
# Copy workflow file to user's repository
cp inst/workflows/publish-quarto-to-skilljar.yml .github/workflows/
```

**Reusable: Reference quarjar workflow**
```yaml
# In user's repository
jobs:
  publish:
    uses: posit-dev/quarjar/.github/workflows/publish-quarto-to-skilljar.yml@main
```

### Setup Requirements

Users must configure:
1. GitHub Pages (Settings → Pages → Deploy from `gh-pages` branch)
2. Repository secret `SKILLJAR_API_KEY`
3. Repository permissions to "Read and write" (Settings → Actions → General)

See examples/GITHUB_ACTION_SETUP.md for complete setup instructions.

## Future Enhancements (Not Implemented)

Potential additions if needed:

1. **Update/Delete Operations**
   - `update_content_item()`
   - `delete_content_item()`
   - `update_lesson()`

2. **Batch Operations**
   - `publish_multiple_lessons()` - Bulk publishing
   - Process entire directories

3. **Course Management**
   - `create_course()`
   - `list_courses()`

4. **Asset Management**
   - Currently `upload_asset()` exists but isn't used
   - Could support non-HTML content types

5. **Testing Suite**
   - Unit tests with testthat
   - Mock API responses

6. **Lesson Navigation**
   - Functions to construct lesson URLs
   - Cross-lesson linking helpers

## Useful Commands

```r
# Build documentation
devtools::document()

# Check package
devtools::check()

# Install locally
devtools::install()

# Run examples
devtools::run_examples()

# Load package for testing
devtools::load_all(".")
```

## API Documentation

Full Skilljar API specification: `docs/skilljar_api.yml`

Key resources:
- API Base URL: https://api.skilljar.com
- Authentication: HTTP Basic (API key)
- Rate limiting: (check current Skilljar docs)

## Contact & Support

**Package Maintainer:** François Michonneau (francois.michonneau@posit.co)

**Related Resources:**
- Skilljar API Docs: https://api.skilljar.com/docs/
- Quarto: https://quarto.org/
- httr2: https://httr2.r-lib.org/

## Notes for AI Assistants

1. **Function naming** uses `skilljar_*` internally (references API provider) but package is named `quarjar`
2. **Environment variable** remains `SKILLJAR_API_KEY` (not QUARJAR_API_KEY)
3. **Default lesson type** is MODULAR - most common use case
4. **Auto-order detection** prevents common user errors
5. **cli package** used instead of UTF-8 for cross-platform compatibility
6. **Invisible returns** on main functions - they succeed silently, use cli alerts for feedback
7. **GitHub Actions workflow** lives in `inst/workflows/` (not `.github/workflows/`) because it's for users to install in their repos
8. **Timestamped ZIPs** enable version tracking and prevent conflicts on GitHub Pages
9. **URL verification** critical - GitHub Pages deployment is asynchronous, must actively check accessibility

When modifying code:
- Maintain sensible defaults (api_key from env, type="MODULAR", etc.)
- Use perform_request() for all API calls
- Add cli alerts for success feedback
- Update both function docs and examples
- Test with devtools::load_all() before committing

When modifying GitHub Actions workflow:
- Always use `remotes::install_github()` not `install_local()` (must work from any repo)
- Keep timestamped filenames for version management
- Maintain retry logic for URL verification (GitHub Pages is async)
- Keep cleanup logic (retain 5 most recent ZIPs in skilljar-zips/ subdirectory)
- Use subdirectory isolation (skilljar-zips/) to coexist with other GitHub Pages content
- Don't use `--force` push - preserve other gh-pages content
- Update documentation if changing requirements
