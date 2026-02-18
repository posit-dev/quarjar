# Setting Up Automated Quarto to Skilljar Publishing

This guide shows you how to set up the automated workflow to publish Quarto documents from your repository to Skilljar using GitHub Actions and GitHub Pages.

## Overview

The workflow automatically:
1. Renders your Quarto document to HTML
2. Packages it as a ZIP file with a timestamped filename
3. Publishes the ZIP to GitHub Pages (provides a public URL)
4. Creates a Skilljar web package from the GitHub Pages URL
5. Creates a WEB_PACKAGE lesson in your Skilljar course

## Prerequisites

- A GitHub repository containing your Quarto documents
- A Skilljar account with API access
- Skilljar API key (see [Getting Your API Key](#getting-your-skilljar-api-key))

## Setup Steps

### 1. Enable GitHub Pages

GitHub Pages is used to host your ZIP files publicly so Skilljar can access them.

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Source**, select:
   - **Deploy from a branch**
   - Branch: `gh-pages`
   - Folder: `/ (root)`
4. Click **Save**

**Note**: The `gh-pages` branch will be created automatically when you first run the workflow.

### 2. Configure Repository Secrets

Add your Skilljar API key as a repository secret:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:

| Name | Description | Example |
|------|-------------|---------|
| `SKILLJAR_API_KEY` | Your Skilljar API key | `sk_live_abc123def456...` |

#### Getting Your Skilljar API Key

1. Log in to your Skilljar account
2. Navigate to **Settings** → **API Keys**
3. Create a new API key or copy an existing one
4. The API key should have permissions to:
   - Create web packages
   - Create lessons
   - Access courses

### 3. Add the Workflow to Your Repository

**Option A: Use the helper function (Recommended)**

If you have the `quarjar` package installed:

```r
# Install if needed
remotes::install_github("posit-dev/quarjar")

# Add the workflow to your repository
quarjar::use_skilljar_workflow()
```

This will:
- Create `.github/workflows/publish-quarto-to-skilljar.yml`
- Show you the next setup steps
- Provide a link to this guide

**Option B: Copy the workflow file manually**

1. Create the directory `.github/workflows/` in your repository
2. Copy the workflow file from this repository:
   - Source: [`inst/workflows/publish-quarto-to-skilljar.yml`](inst/workflows/publish-quarto-to-skilljar.yml)
   - Destination: `.github/workflows/publish-quarto-to-skilljar.yml` in your repo

**Option C: Create a reusable workflow reference**

Create `.github/workflows/publish-to-skilljar.yml` in your repository:

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
      package-title:
        description: 'Package title (optional)'
        required: false
        type: string

jobs:
  publish:
    uses: posit-dev/quarjar/.github/workflows/publish-quarto-to-skilljar.yml@main
    with:
      qmd-file: ${{ inputs.qmd-file }}
      course-id: ${{ inputs.course-id }}
      lesson-title: ${{ inputs.lesson-title }}
      package-title: ${{ inputs.package-title }}
    secrets:
      SKILLJAR_API_KEY: ${{ secrets.SKILLJAR_API_KEY }}
```

### 4. Set Up Repository Permissions

Ensure the GitHub Actions workflow has necessary permissions:

1. Go to **Settings** → **Actions** → **General**
2. Under **Workflow permissions**, select:
   - ✅ **Read and write permissions**
3. Click **Save**

This allows the workflow to push to the `gh-pages` branch.

## Usage

### Running the Workflow

1. Go to the **Actions** tab in your GitHub repository
2. Select **Publish Quarto to Skilljar via GitHub Pages** (or your workflow name)
3. Click **Run workflow**
4. Fill in the required inputs:

| Input | Description | Required | Example |
|-------|-------------|----------|---------|
| `qmd-file` | Path to your Quarto document | Yes | `lessons/module1.qmd` |
| `course-id` | Skilljar course ID | Yes | `abc123` |
| `lesson-title` | Title for the lesson in Skilljar | Yes | `Module 1: Introduction to R` |
| `package-title` | Title for the web package (defaults to lesson title) | No | `Intro to R - Web Package` |
| `base-url` | Skilljar API base URL | No | `https://api.skilljar.com` (default) |

5. Click **Run workflow**

### Finding Your Skilljar Course ID

1. Log in to your Skilljar account
2. Navigate to the course you want to publish to
3. The course ID is in the URL:
   ```
   https://your-domain.skilljar.com/admin/courses/abc123/edit
                                                    ^^^^^^^ (this is your course ID)
   ```

### Example Repository Structure

```
my-training-repo/
├── .github/
│   └── workflows/
│       └── publish-quarto-to-skilljar.yml
├── lessons/
│   ├── module1.qmd
│   ├── module2.qmd
│   └── module3.qmd
└── README.md
```

### Workflow Output

After successful execution, the workflow provides:

- **ZIP Filename**: Timestamped ZIP file (e.g., `module1-20260218-143022.zip`)
- **GitHub Pages URL**: Public URL where the ZIP is hosted
- **Web Package ID**: Skilljar web package ID
- **Lesson ID**: Created Skilljar lesson ID

## Advanced Configuration

### Automatic Publishing on Push

To automatically publish when you push changes to a specific Quarto file:

```yaml
name: Publish to Skilljar

on:
  push:
    branches: [main]
    paths:
      - 'lessons/module1.qmd'
  workflow_dispatch:
    # ... (keep the manual trigger inputs)

jobs:
  publish:
    uses: posit-dev/quarjar/.github/workflows/publish-quarto-to-skilljar.yml@main
    with:
      qmd-file: 'lessons/module1.qmd'
      course-id: 'abc123'
      lesson-title: 'Module 1: Introduction'
    secrets:
      SKILLJAR_API_KEY: ${{ secrets.SKILLJAR_API_KEY }}
```

### Multiple Environments

Use different secrets for staging and production:

```yaml
jobs:
  publish-staging:
    uses: posit-dev/quarjar/.github/workflows/publish-quarto-to-skilljar.yml@main
    with:
      qmd-file: ${{ inputs.qmd-file }}
      course-id: ${{ secrets.STAGING_COURSE_ID }}
      lesson-title: ${{ inputs.lesson-title }}
      base-url: 'https://staging-api.skilljar.com'
    secrets:
      SKILLJAR_API_KEY: ${{ secrets.STAGING_SKILLJAR_API_KEY }}

  publish-production:
    needs: publish-staging
    uses: posit-dev/quarjar/.github/workflows/publish-quarto-to-skilljar.yml@main
    with:
      qmd-file: ${{ inputs.qmd-file }}
      course-id: ${{ secrets.PROD_COURSE_ID }}
      lesson-title: ${{ inputs.lesson-title }}
    secrets:
      SKILLJAR_API_KEY: ${{ secrets.PROD_SKILLJAR_API_KEY }}
```

## Troubleshooting

### GitHub Pages Not Accessible

**Error**: `GitHub Pages deployment verification timed out`

**Solutions**:
- Verify GitHub Pages is enabled (Settings → Pages)
- Check that the `gh-pages` branch exists
- Ensure workflow has write permissions (Settings → Actions → General)
- GitHub Pages can take a few minutes on first setup

### Skilljar API Errors

**Error**: `api_key is required`

**Solution**: Verify `SKILLJAR_API_KEY` secret is set correctly in repository settings

**Error**: `Failed to create web package`

**Solutions**:
- Verify your API key has permission to create web packages
- Check that the GitHub Pages URL is publicly accessible
- Ensure the ZIP file was successfully uploaded to GitHub Pages

### Lesson Creation Fails

**Error**: `Failed to create lesson`

**Solutions**:
- Verify the course ID is correct
- Check that your API key has permission to create lessons in this course
- Ensure the web package finished processing (workflow waits up to 2 minutes)

## ZIP File Management

The workflow automatically manages ZIP files on GitHub Pages:

- **Timestamped filenames**: Each ZIP has a unique timestamp (e.g., `lesson-20260218-143022.zip`)
- **Automatic cleanup**: Keeps only the 5 most recent ZIP files
- **Version history**: You can see previous versions on the `gh-pages` branch

## Security Considerations

- ✅ **API keys**: Stored securely in GitHub Secrets (never in code)
- ✅ **Public ZIPs**: Your rendered content is publicly accessible via GitHub Pages
- ⚠️ **Sensitive content**: Don't publish confidential material through this workflow
- ✅ **Branch protection**: Consider protecting your `main` branch to control when content is published

## Support

For issues with:
- **The quarjar package**: [Open an issue](https://github.com/posit-dev/quarjar/issues)
- **Skilljar API**: Contact Skilljar support
- **GitHub Actions**: Check [GitHub Actions documentation](https://docs.github.com/en/actions)

## Related Documentation

- [quarjar Package README](README.md)
- [Quarto Documentation](https://quarto.org)
- [Skilljar API Documentation](https://api.skilljar.com/docs)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
