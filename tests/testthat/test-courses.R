test_that("resolve_lesson_order_conflict returns requested order when free", {
  existing <- data.frame(
    lesson_id = c("les_a", "les_b"),
    title = c("Intro", "Install"),
    type = c("SECTION", "WEB_PACKAGE"),
    order = c(10L, 20L)
  )
  expect_equal(
    quarjar:::resolve_lesson_order_conflict(30, existing, "error", "course1"),
    30L
  )
})

test_that("resolve_lesson_order_conflict returns requested order for empty course", {
  empty <- data.frame(
    lesson_id = character(),
    title = character(),
    type = character(),
    order = integer()
  )
  expect_equal(
    quarjar:::resolve_lesson_order_conflict(0, empty, "error", "course1"),
    0L
  )
})

test_that("resolve_lesson_order_conflict errors with diagnostics on clash", {
  existing <- data.frame(
    lesson_id = "les_x",
    title = "Install Connect",
    type = "SECTION",
    order = 30L
  )
  expect_error(
    quarjar:::resolve_lesson_order_conflict(30, existing, "error", "course1"),
    "already in use"
  )
  expect_error(
    quarjar:::resolve_lesson_order_conflict(30, existing, "error", "course1"),
    "les_x"
  )
  expect_error(
    quarjar:::resolve_lesson_order_conflict(30, existing, "error", "course1"),
    "Install Connect"
  )
})

test_that("resolve_lesson_order_conflict auto places at next free order", {
  existing <- data.frame(
    lesson_id = "les_x",
    title = "Install Connect",
    type = "SECTION",
    order = 30L
  )
  expect_message(
    result <- quarjar:::resolve_lesson_order_conflict(
      30,
      existing,
      "auto",
      "course1"
    ),
    "already used"
  )
  expect_equal(result, 40L)
})
