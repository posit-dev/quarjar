# quarjar

**quarjar** (Quarto + SkillJar) is an R package for publishing Quarto documents as SCORM/web packages to Skilljar courses. It automates the full workflow: render → package → host → publish.

> **Disclaimer:** quarjar is an independent open-source project and is not affiliated with, endorsed by, or supported by SkillJar, Inc.

## Installation

```r
# install.packages("remotes")
remotes::install_github("posit-dev/quarjar")
```

## Automated Pipeline via GitHub Actions

The primary use case is a push-triggered GitHub Actions pipeline. Every time you push a change to a `.qmd` file, the workflow renders it, packages it, and publishes or updates the corresponding Skilljar lesson — no manual steps required.

### Setup

**1. Add the workflow to your repository:**

```r
quarjar::use_skilljar_workflow()
```

**2. Configure your `.qmd` front matter:**

```yaml
---
title: "My Lesson Title"
skilljar:
  course_id: "abc123"       # required — files without this are skipped
  package_title: "..."      # optional; defaults to title
  lesson_order: 3           # optional; explicit position in course (first publish only)
---
```

**3. Complete one-time repository setup:**

- Enable GitHub Pages: Settings → Pages → Deploy from `gh-pages` branch
- Add secret `SKILLJAR_API_KEY` (Settings → Secrets and variables → Actions)
- Add secret `REPO_PAT` — a fine-grained PAT with Contents and Pages read/write
- Set workflow permissions to "Read and write" (Settings → Actions → General)

See [GITHUB_ACTION_SETUP.md](examples/GITHUB_ACTION_SETUP.md) for detailed instructions.

### How it works

**First publish** (no `skilljar.lesson_id` in front matter):

1. Renders the `.qmd` to HTML
2. Creates a timestamped ZIP and publishes it to GitHub Pages under `skilljar-zips/`
3. Creates a Skilljar web package from the GitHub Pages URL
4. Creates a WEB_PACKAGE lesson in your course
5. Commits `skilljar.lesson_id` back to `main` (tagged `[skip ci]`)

**Subsequent pushes** (after `skilljar.lesson_id` is present):

Steps 1–3 run identically, then the existing lesson is updated with the new web package and the old one is deleted.

`skilljar.lesson_id` is never set manually — the workflow writes it back after the first successful publish. The `skilljar-zips/` subdirectory means this workflow coexists with other GitHub Pages content (pkgdown sites, etc.) without conflict.

To re-trigger a failed run, make a trivial change to the `.qmd` file (an empty commit won't work — the `paths` filter requires at least one `.qmd` among the changed files):

```bash
echo "" >> my-lesson.qmd
git add my-lesson.qmd
git commit -m "re-trigger: republish to Skilljar"
git push
```

## Manual R Usage

For one-off publishing or scripted workflows outside GitHub Actions:

```r
library(quarjar)

# Step 1: Render a .qmd and create a ZIP package
zip_path <- generate_zip_package("lessons/module1.qmd")

# Step 2: Host the ZIP at a publicly accessible URL, then create a web package
pkg <- create_web_package(
  content_url = "https://example.com/skilljar-zips/module1.zip",
  title = "Module 1: Getting Started"
)

# Note: Skilljar processes web packages asynchronously.
# If lesson creation fails immediately, wait a moment and retry.

# Step 3: Create a lesson in your course
lesson <- create_lesson_with_web_package(
  course_id = "abc123",
  lesson_title = "Module 1: Getting Started",
  web_package_id = pkg$id
)
```

Lesson order is auto-detected (new lesson appended at end of course) unless you pass an explicit `order` integer. Subsequent content updates use `update_lesson()`, which replaces only the web package and leaves everything else — title, position, settings — unchanged.

## Configuration

**API key** — set once as an environment variable; all functions pick it up automatically:

```r
Sys.setenv(SKILLJAR_API_KEY = "your-api-key")
```

**Base URL** — defaults to `https://api.skilljar.com`; override per session if needed:

```r
options(quarjar.base_url = "https://api.skilljar.com")
```

## Other Capabilities

- **MODULAR lesson management** — `create_lesson_with_content()`, `publish_html_content()`: publish inline HTML content to MODULAR-type lessons (multiple content items per lesson)
- **Web package management** — `list_web_packages()`, `get_web_package()`, `delete_web_package()`: inspect and clean up web packages
- **Course and lesson inspection** — `get_course()`, `list_lessons()`, `get_lesson()`, `list_content_items()`
- **Asset upload** — `upload_asset()`: upload individual files (PDFs, images, videos) as assets

## License

MIT License — see LICENSE file for details.
