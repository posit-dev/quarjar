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

Add the required secrets to your repository:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Name | Description | Example |
|------|-------------|---------|
| `SKILLJAR_API_KEY` | Your Skilljar API key | `sk_live_abc123def456...` |
| `REPO_PAT` | Fine-grained PAT for installing the quarjar package from GitHub | (see below) |

#### Creating the `REPO_PAT`

Create a fine-grained personal access token at **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens** with the following permissions on your repository:

| Permission | Level |
|---|---|
| Contents | Read and write |
| Pages | Read and write |
| Metadata | Read (mandatory) |

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

### 4. Set Up Repository Permissions

Ensure the GitHub Actions workflow has necessary permissions:

1. Go to **Settings** → **Actions** → **General**
2. Under **Workflow permissions**, select:
   - ✅ **Read and write permissions**
3. Click **Save**

This allows the workflow to push to both the `gh-pages` branch and `main`.

## Usage

### Triggering the Workflow

The workflow runs automatically on every push to `main` that modifies a `.qmd` file containing a `skilljar.course_id` in its front matter. There is no manual trigger — to re-run a failed job, make a trivial change to the relevant `.qmd` file (an empty commit will not work because the `paths` filter requires at least one `.qmd` among the changed files):

```bash
echo "" >> module1.qmd
git add module1.qmd
git commit -m "re-trigger: republish to Skilljar"
git push
```

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
├── _quarto.yml              # optional base project config
├── _quarto-skilljar.yml     # optional Skilljar-specific overrides
├── module1.qmd              # .qmd files must be at the root, not in sub-folders
├── module2.qmd
├── module3.qmd
└── images/                  # assets can live in sub-folders
    └── diagram.png
```

### Workflow Output

After successful execution, the workflow provides:

- **ZIP Filename**: Timestamped ZIP file (e.g., `module1-20260218-143022.zip`)
- **GitHub Pages URL**: Public URL where the ZIP is hosted
- **Web Package ID**: Skilljar web package ID
- **Lesson ID**: Created Skilljar lesson ID

## Advanced Configuration

### Limiting Which Files Trigger the Workflow

By default the workflow runs for any changed `.qmd` file. If you want to restrict it to a specific directory, edit the `paths` filter in the workflow file after installing it:

```yaml
on:
  push:
    branches: [main]
    paths: ["lessons/**/*.qmd"]   # only files under lessons/
```

Files that lack a `skilljar_course_id` in their front matter are always silently skipped regardless of the `paths` filter.

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
- ⚠️ **Branch protection**: The workflow commits `skilljar_lesson_id` directly to `main` — branch protection rules that require PRs will block this step

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
