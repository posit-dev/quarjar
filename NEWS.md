# quarjar 0.2.3

## New features

* Lesson order conflict handling: when an explicitly requested lesson order is
  already used by another lesson in the course, quarjar no longer surfaces a
  raw API error. `create_lesson_with_web_package()` (and the GitHub Actions
  workflow) now fail with diagnostics identifying the conflicting lesson and
  listing the orders in use. Set `skilljar.on_order_conflict: auto` in the
  front matter (or `ON_ORDER_CONFLICT: auto` in the workflow environment) to
  warn and place the lesson at the next free order instead.
* New `get_lesson_orders()`: returns the lesson order currently in use for a
  course (lesson ID, title, type, and order), following pagination.

## Improvements

* Auto-detected lesson orders now follow Skilljar's convention of spacing
  orders in increments of 10 (`max(order) + 10`) instead of `max(order) + 1`.
* Fixed an `api_key` validation bug that aborted functions even when the
  `SKILLJAR_API_KEY` environment variable default was valid.

# quarjar 0.2.2

## Breaking changes

* Flat `skilljar_*` front matter keys no longer emit a deprecation warning —
  they now abort with a migration error. Files using the old format will
  fail immediately with an actionable message pointing to the README.

## New features

* Workflow version check: the GitHub Actions workflow now warns (non-blocking)
  at runtime when the workflow template version does not match the installed
  `quarjar` package version.
* Post-writeback YAML validation: after the workflow commits `skilljar.lesson_id`
  back to `main`, a new step re-parses the front matter and confirms the field
  is present and the YAML is still valid.

## Workflow improvements

* The `REPO_PAT` secret is no longer required. The workflow now relies on the
  automatically-injected `GITHUB_TOKEN` for installing quarjar from GitHub,
  which is sufficient for public repositories and avoids the setup burden of
  creating and maintaining a personal access token.
* Added path triggers for `_quarto-skilljar.yml` and the workflow file itself.
  Pushing either config file now republishes all lessons, since any lesson
  could be affected.
* The `detect` job is now guarded against the lesson-ID writeback commit
  re-triggering the workflow (`github.actor != 'github-actions[bot]'`).
* Fixed `actions/checkout` version reference.
* Added `libarchive-dev` system dependency (required by `pak` on Ubuntu Noble).
* Added `knitr` and `rmarkdown` to R dependencies (required for Quarto rendering).
* Added `shinylive` as a non-blocking optional dependency (`continue-on-error: true`).

## Bug fixes / test coverage

* Added test for `ci_write_lesson_id()` when `skilljar:` is the last front
  matter line (empty block, `seq_len(0)` edge case).

# quarjar 0.2.0

## Breaking changes (with backward compatibility)

* Front matter keys are now nested under a single `skilljar:` block instead of
  using flat `skilljar_*` prefixed keys. The old flat keys continue to work but
  emit a deprecation warning. Migrate your `.qmd` files:

  **Before:**
  ```yaml
  skilljar_course_id: "abc123"
  skilljar_lesson_order: 0
  display_fullscreen: true
  ```

  **After:**
  ```yaml
  skilljar:
    course_id: "abc123"
    lesson_order: 0
    display_fullscreen: true
  ```

## New features

* Added `parse_skilljar_fm()` (internal helper) for centralised YAML front
  matter validation with type coercion and unknown-key detection.
* `display_fullscreen` is now documented as a supported front matter key under
  `skilljar.display_fullscreen`.
* `ci_write_lesson_id()` now patches the `skilljar:` block in place rather
  than appending a bare top-level key.
