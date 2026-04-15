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
