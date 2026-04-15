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

test_that("parse_skilljar_fm warns and promotes flat keys (compat shim)", {
  fm <- list(
    title = "My Lesson",
    skilljar_course_id = "flat123",
    display_fullscreen = FALSE
  )
  result <- withCallingHandlers(
    parse_skilljar_fm(fm),
    warning = function(w) invokeRestart("muffleWarning")
  )
  expect_warning(parse_skilljar_fm(fm), "deprecated")
  expect_equal(result$course_id, "flat123")
  expect_false(result$display_fullscreen)
})

test_that("parse_skilljar_fm returns NULL when neither nested nor flat keys present", {
  fm <- list(title = "Just a Quarto doc", format = "html")
  expect_null(parse_skilljar_fm(fm))
})
