# Examples

This directory contains example files for testing the quarjar package.

## Files

- `test.html` - Sample HTML file for testing publishing
- `publish.R` - Example R script demonstrating package usage

## Testing the Package

### Prerequisites

1. Install the quarjar package:
   ```r
   remotes::install_local(".", force = TRUE)
   ```

2. Set up your environment variables:
   ```bash
   export SKILLJAR_API_KEY="your-api-key-here"
   export SKILLJAR_LESSON_ID="your-lesson-id-here"
   ```

### Interactive R Session

```r
library(quarjar)

# Load credentials
api_key <- Sys.getenv("SKILLJAR_API_KEY")
lesson_id <- Sys.getenv("SKILLJAR_LESSON_ID")

# Publish test HTML
result <- publish_html_content(
  lesson_id = lesson_id,
  html_path = "examples/test.html",
  title = "Test Content",
  api_key = api_key
)

# Check result
print(result)
```

### Using the Example Script

```bash
# From repository root
Rscript examples/publish.R
```

### Expected Output

```
Publishing HTML content to Skilljar...
Lesson ID: 12345
HTML file: examples/test.html

Uploading HTML file as asset...
Asset uploaded with ID: 67890
Creating content item in lesson...
Content item created with ID: 11111

✅ Successfully published content!
Content Item ID: 11111
Content Item Header: Test Content - Skilljar Publisher
Content Item Order: 0
```

## Troubleshooting

### Error: "SKILLJAR_API_KEY environment variable is not set"

Set your API key:
```bash
export SKILLJAR_API_KEY="your-key"
```

### Error: "File not found"

Make sure you're running from the repository root directory.

### Error: "Failed to upload asset" or "Failed to create content item"

- Verify your API key is correct
- Check that the lesson ID exists and is accessible with your credentials
- Ensure you have permission to create content in the lesson
