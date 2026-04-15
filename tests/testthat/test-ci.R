# tests/testthat/test-ci.R

test_that("parse_skilljar_fm returns NULL when skilljar key is absent", {
  fm <- list(title = "My Lesson", other_key = "foo")
  expect_null(parse_skilljar_fm(fm))
})

test_that("parse_skilljar_fm returns typed list for valid nested input", {
  fm <- list(
    title = "My Lesson",
    skilljar = list(
      course_id    = "abc123",
      lesson_order = 2L
    )
  )
  result <- parse_skilljar_fm(fm)
  expect_equal(result$course_id, "abc123")
  expect_equal(result$lesson_order, 2L)
  expect_equal(result$package_title, "")
  expect_equal(result$lesson_id, "")
  expect_true(result$display_fullscreen)  # default
})

test_that("parse_skilljar_fm aborts when course_id is missing", {
  fm <- list(skilljar = list(package_title = "Foo"))
  expect_error(parse_skilljar_fm(fm), "course_id.*required")
})

test_that("parse_skilljar_fm aborts when course_id is empty string", {
  fm <- list(skilljar = list(course_id = ""))
  expect_error(parse_skilljar_fm(fm), "course_id.*required")
})

test_that("parse_skilljar_fm aborts when course_id is numeric", {
  fm <- list(skilljar = list(course_id = 123))
  expect_error(parse_skilljar_fm(fm), "course_id.*character")
})

test_that("parse_skilljar_fm warns on unknown keys", {
  fm <- list(skilljar = list(course_id = "abc123", corse_id = "typo"))
  expect_warning(parse_skilljar_fm(fm), "Unknown key")
})

test_that("parse_skilljar_fm aborts when lesson_order is non-integer string", {
  fm <- list(skilljar = list(course_id = "abc123", lesson_order = "two"))
  expect_error(parse_skilljar_fm(fm), "lesson_order.*integer")
})

test_that("parse_skilljar_fm coerces numeric lesson_order to integer", {
  fm <- list(skilljar = list(course_id = "abc123", lesson_order = 3.0))
  result <- parse_skilljar_fm(fm)
  expect_equal(result$lesson_order, 3L)
  expect_type(result$lesson_order, "integer")
})

test_that("parse_skilljar_fm warns on non-logical display_fullscreen", {
  fm <- list(skilljar = list(course_id = "abc123", display_fullscreen = "yes"))
  expect_warning(parse_skilljar_fm(fm), "display_fullscreen")
})

test_that("parse_skilljar_fm aborts on flat keys with migration message", {
  fm <- list(
    title = "My Lesson",
    skilljar_course_id = "flat123",
    display_fullscreen = FALSE
  )
  expect_error(
    parse_skilljar_fm(fm),
    regexp = "flat.*skilljar_\\*|deprecated|migrate",
    ignore.case = TRUE
  )
})

test_that("parse_skilljar_fm returns NULL when neither nested nor flat keys present", {
  fm <- list(title = "Just a Quarto doc", format = "html")
  expect_null(parse_skilljar_fm(fm))
})

test_that("ci_write_lesson_id inserts lesson_id into nested skilljar block", {
  tmp <- tempfile(fileext = ".qmd")
  writeLines(c(
    "---",
    "title: Test",
    "skilljar:",
    "  course_id: \"abc123\"",
    "---",
    "",
    "Body text."
  ), tmp)
  withr::defer(unlink(tmp))

  result <- ci_write_lesson_id(qmd_file = tmp, lesson_id = "les_999")
  expect_true(result)

  lines <- readLines(tmp, warn = FALSE)
  # lesson_id should appear inside the skilljar block (indented with 2 spaces)
  expect_true(any(grepl("^  lesson_id: \"les_999\"", lines)))
  # and NOT as a bare top-level key
  expect_false(any(grepl("^skilljar_lesson_id:", lines)))
  expect_false(any(grepl("^lesson_id:", lines)))
})

test_that("ci_write_lesson_id is idempotent when lesson_id already present (nested)", {
  tmp <- tempfile(fileext = ".qmd")
  writeLines(c(
    "---",
    "title: Test",
    "skilljar:",
    "  course_id: \"abc123\"",
    "  lesson_id: \"les_existing\"",
    "---",
    "",
    "Body."
  ), tmp)
  withr::defer(unlink(tmp))

  result <- ci_write_lesson_id(qmd_file = tmp, lesson_id = "les_new")
  expect_false(result)  # file unchanged

  lines <- readLines(tmp, warn = FALSE)
  expect_false(any(grepl("les_new", lines)))
  expect_true(any(grepl("les_existing", lines)))
})


test_that("ci_write_lesson_id aborts when no skilljar: block present", {
  tmp <- tempfile(fileext = ".qmd")
  writeLines(c(
    "---",
    "title: Old style",
    "skilljar_course_id: \"abc123\"",
    "---",
    "",
    "Body."
  ), tmp)
  withr::defer(unlink(tmp))

  expect_error(
    ci_write_lesson_id(qmd_file = tmp, lesson_id = "les_fail"),
    regexp = "skilljar:.*block|nested|migrate",
    ignore.case = TRUE
  )
})

test_that("ci_write_lesson_id handles skilljar: block with no children", {
  # Edge case: skilljar: is the last line of front matter (no indented children).
  # seq_len(0) must return integer(0) so the for loop never executes,
  # and lesson_id is appended right after the skilljar: line.
  tmp <- tempfile(fileext = ".qmd")
  writeLines(c(
    "---",
    "title: Test",
    "skilljar:",
    "---",
    "",
    "Body."
  ), tmp)
  withr::defer(unlink(tmp))

  result <- ci_write_lesson_id(qmd_file = tmp, lesson_id = "les_edge")
  expect_true(result)

  lines <- readLines(tmp, warn = FALSE)
  expect_true(any(grepl("^  lesson_id: \"les_edge\"", lines)))
  # lesson_id must appear between the skilljar: line and the closing ---
  sj_idx     <- which(grepl("^skilljar:\\s*$", lines))
  end_idx    <- which(grepl("^---\\s*$", lines))[[2]]
  lesson_idx <- which(grepl("^  lesson_id:", lines))
  expect_true(lesson_idx > sj_idx && lesson_idx < end_idx)
})
