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
   - `upload_web_package()` - Upload local ZIP file as web package
   - `create_lesson_with_web_package()` - Create WEB_PACKAGE lesson
   - `get_web_package()`, `list_web_packages()`, `delete_web_package()`
   - Supports SCORM packages and HTML5 web content

5. **Course Helpers** (`R/courses.R`)
   - `get_course()`, `list_lessons()`, `get_next_lesson_order()`

6. **Lesson Helpers** (`R/lessons.R`)
   - `get_lesson()`, `list_content_items()`

7. **Asset Management** (`R/assets.R`)
   - `upload_asset()` - Upload files as assets (used by web package upload)

8. **Error Handling** (`R/utils.R`)
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
│   ├── assets.R           # Asset upload (not used in main workflow)
│   ├── client.R           # API authentication
│   ├── courses.R          # Course-level functions
│   ├── create_lesson.R    # Lesson creation (main entry point)
│   ├── lessons.R          # Lesson retrieval functions
│   ├── publish.R          # Content publishing
│   ├── quarjar-package.R  # Package documentation
│   └── utils.R            # Error handling helpers
├── examples/
│   ├── test.html          # Sample HTML for testing
│   ├── publish.R          # Example usage script
│   └── README.md          # Testing documentation
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

When modifying code:
- Maintain sensible defaults (api_key from env, type="MODULAR", etc.)
- Use perform_request() for all API calls
- Add cli alerts for success feedback
- Update both function docs and examples
- Test with devtools::load_all() before committing
