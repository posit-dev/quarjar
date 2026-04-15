# tests/testthat/test-ci.R

test_that("parse_skilljar_fm returns NULL when skilljar key is absent", {
  fm <- list(title = "My Lesson", other_key = "foo")
  expect_null(parse_skilljar_fm(fm))
})
