# Tests for generate_zip_package()
#
# Note: Previous versions of the documentation referenced non-existent functions
# (create_web_package, upload_asset, create_lesson_with_content). These were
# never implemented and have been removed from the documentation.

test_that("generate_zip_package requires .qmd extension", {
  # Create a temporary file with wrong extension
  tmp_file <- tempfile(fileext = ".txt")
  writeLines("# Test", tmp_file)

  expect_error(
    generate_zip_package(tmp_file),
    "Input file must have a .qmd extension"
  )

  unlink(tmp_file)
})

test_that("generate_zip_package checks if file exists", {
  expect_error(
    generate_zip_package("nonexistent.qmd"),
    "File not found"
  )
})

test_that("generate_zip_package creates zip file in same directory as .qmd", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  # Create a temporary .qmd file
  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_lesson.qmd")

  writeLines(c(
    "---",
    "title: Test Lesson",
    "format: html",
    "---",
    "",
    "# Introduction",
    "",
    "This is a test lesson."
  ), tmp_qmd)

  # Generate zip package
  result <- generate_zip_package(tmp_qmd, quiet = TRUE)

  # Check that zip file was created in tmp_dir
  expect_true(file.exists(result))
  expect_equal(basename(result), "test_lesson.zip")
  expect_equal(dirname(result), tmp_dir)

  # Check that staging directory was cleaned up
  expect_false(dir.exists(file.path(tmp_dir, "_test_lesson")))

  # Verify the zip contains the expected content
  temp_extract <- file.path(tmp_dir, "extract_test")
  dir.create(temp_extract)
  unzip(result, exdir = temp_extract)
  expect_true(file.exists(file.path(temp_extract, "_test_lesson", "index.html")))

  # Clean up
  unlink(result)
  unlink(temp_extract, recursive = TRUE)
  unlink(tmp_qmd)
})

test_that("generate_zip_package returns absolute zip file path invisibly", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_return.qmd")

  writeLines(c(
    "---",
    "title: Test",
    "format: html",
    "---",
    "",
    "Test content"
  ), tmp_qmd)

  # Test that result is returned invisibly
  result <- withVisible(generate_zip_package(tmp_qmd, quiet = TRUE))

  expect_false(result$visible)
  expect_equal(result$value, file.path(tmp_dir, "test_return.zip"))
  expect_true(file.exists(result$value))

  # Clean up
  unlink(file.path(tmp_dir, "test_return.zip"))
  unlink(tmp_qmd)
})

test_that("generate_zip_package respects overwrite parameter", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- tempdir()
  tmp_qmd <- file.path(tmp_dir, "test_overwrite.qmd")

  writeLines(c(
    "---",
    "title: Test",
    "format: html",
    "---",
    "",
    "Test"
  ), tmp_qmd)

  # First creation should work
  result1 <- generate_zip_package(tmp_qmd, quiet = TRUE, overwrite = TRUE)
  expect_true(file.exists(result1))

  # Second creation with overwrite = TRUE should work
  result2 <- generate_zip_package(tmp_qmd, quiet = TRUE, overwrite = TRUE)
  expect_true(file.exists(result2))

  # Third creation with overwrite = FALSE should fail
  expect_error(
    generate_zip_package(tmp_qmd, quiet = TRUE, overwrite = FALSE),
    "Zip file already exists.*overwrite = TRUE"
  )

  # Clean up
  unlink(file.path(tmp_dir, "test_overwrite.zip"))
  unlink(tmp_qmd)
})

test_that("generate_zip_package creates correct output directory name", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "my_lesson.qmd")

  writeLines(c(
    "---",
    "title: My Lesson",
    "format: html",
    "---",
    "",
    "Content"
  ), tmp_qmd)

  result <- generate_zip_package(tmp_qmd, quiet = TRUE)

  # Check that staging directory was cleaned up
  expect_false(dir.exists(file.path(tmp_dir, "_my_lesson")))

  # Check that zip file has correct name and path
  expect_equal(basename(result), "my_lesson.zip")
  expect_equal(dirname(result), tmp_dir)

  # Clean up
  unlink(file.path(tmp_dir, "my_lesson.zip"))
  unlink(tmp_qmd)
})

test_that("generate_zip_package creates index.html at root", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- tempdir()
  tmp_qmd <- file.path(tmp_dir, "test_index.qmd")

  writeLines(c(
    "---",
    "title: Index Test",
    "format: html",
    "---",
    "",
    "# Test Content",
    "",
    "This should be in index.html"
  ), tmp_qmd)

  result <- generate_zip_package(tmp_qmd, quiet = TRUE)

  # Unzip and check contents
  temp_extract <- file.path(tmp_dir, "extract_test")
  dir.create(temp_extract)
  unzip(result, exdir = temp_extract)

  # Check that _test_index directory contains index.html
  expect_true(file.exists(file.path(temp_extract, "_test_index", "index.html")))

  # Read the HTML and verify it contains our content
  html_content <- readLines(
    file.path(temp_extract, "_test_index", "index.html"),
    warn = FALSE  # Suppress warning about missing final newline
  )
  expect_true(any(grepl("Test Content", html_content, ignore.case = TRUE)))

  # Clean up
  unlink(result)
  unlink(temp_extract, recursive = TRUE)
  unlink(tmp_qmd)
})

test_that("generate_zip_package handles quiet mode", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- tempdir()
  tmp_qmd <- file.path(tmp_dir, "test_quiet.qmd")

  writeLines(c(
    "---",
    "title: Quiet Test",
    "format: html",
    "---",
    "",
    "Test"
  ), tmp_qmd)

  # Test that quiet mode doesn't error (but may show cli messages)
  result <- expect_no_error(
    generate_zip_package(tmp_qmd, quiet = TRUE)
  )

  expect_true(file.exists(result))

  # Clean up
  unlink(file.path(tmp_dir, "test_quiet.zip"))
  unlink(tmp_qmd)
})

test_that("generate_zip_package respects custom output_dir", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_custom.qmd")
  custom_output <- file.path(tmp_dir, "custom_output")

  writeLines(c(
    "---",
    "title: Custom Output Test",
    "format: html",
    "---",
    "",
    "Test content"
  ), tmp_qmd)

  # Generate with custom output directory
  result <- generate_zip_package(tmp_qmd, output_dir = custom_output, quiet = TRUE)

  # Check that zip file was created in custom directory
  expect_true(file.exists(result))
  expect_equal(dirname(result), normalizePath(custom_output, mustWork = TRUE))
  expect_equal(basename(result), "test_custom.zip")

  # Check that staging directory was cleaned up
  expect_false(dir.exists(file.path(custom_output, "_test_custom")))

  # Clean up
  unlink(custom_output, recursive = TRUE)
  unlink(tmp_qmd)
})

test_that("generate_zip_package creates output_dir if it doesn't exist", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_create_dir.qmd")
  new_output <- file.path(tmp_dir, "new_directory", "nested")

  # Ensure the directory doesn't exist
  if (dir.exists(new_output)) {
    unlink(new_output, recursive = TRUE)
  }

  writeLines(c(
    "---",
    "title: Create Dir Test",
    "format: html",
    "---",
    "",
    "Test"
  ), tmp_qmd)

  # Generate with non-existent output directory
  result <- generate_zip_package(tmp_qmd, output_dir = new_output, quiet = TRUE)

  # Check that directory was created
  expect_true(dir.exists(new_output))
  expect_true(file.exists(result))
  expect_equal(dirname(result), normalizePath(new_output, mustWork = TRUE))

  # Clean up
  unlink(file.path(tmp_dir, "new_directory"), recursive = TRUE)
  unlink(tmp_qmd)
})

test_that("generate_zip_package errors when zip creation fails", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_zip_fail.qmd")

  writeLines(c(
    "---",
    "title: Zip Fail Test",
    "format: html",
    "---",
    "",
    "Test"
  ), tmp_qmd)

  staging_dir <- file.path(tmp_dir, "_test_zip_fail")

  # Ensure cleanup happens even if test fails
  withr::defer(unlink(staging_dir, recursive = TRUE))
  withr::defer(unlink(tmp_qmd))

  # Mock the zip function to fail
  with_mocked_bindings(
    zip = function(...) {
      # Return non-zero status to simulate failure
      1
    },
    {
      expect_error(
        generate_zip_package(tmp_qmd, quiet = TRUE),
        "Failed to create zip file"
      )
    }
  )

  # Verify that staging directory still exists after zip failure (preserved for debugging)
  expect_true(dir.exists(staging_dir))

  # Verify the staging directory contains the rendered content
  expect_true(file.exists(file.path(staging_dir, "index.html")))
})

test_that("generate_zip_package error message includes specific exit codes", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_exit_codes.qmd")

  writeLines(c(
    "---",
    "title: Exit Code Test",
    "format: html",
    "---",
    "",
    "Test"
  ), tmp_qmd)

  staging_dir <- file.path(tmp_dir, "_test_exit_codes")
  expected_zip <- file.path(tmp_dir, "test_exit_codes.zip")

  # Ensure cleanup happens even if test fails
  withr::defer({
    if (dir.exists(staging_dir)) {
      unlink(staging_dir, recursive = TRUE)
    }
    unlink(tmp_qmd)
  })

  # Test multiple exit codes
  exit_codes <- c(2, 127)
  for (code in exit_codes) {
    with_mocked_bindings(
      zip = function(...) { code },
      {
        error <- expect_error(
          generate_zip_package(tmp_qmd, quiet = TRUE),
          "Failed to create zip file"
        )

        # Verify error message structure
        error_msg <- conditionMessage(error)
        expect_match(error_msg, paste0("Exit code: ", code))
        expect_match(error_msg, "Zip file:")

        # Verify staging directory is preserved for debugging
        expect_true(dir.exists(staging_dir))
        expect_true(file.exists(file.path(staging_dir, "index.html")))
      }
    )

    # Clean up staging directory between tests
    if (dir.exists(staging_dir)) {
      unlink(staging_dir, recursive = TRUE)
    }
  }
})

test_that("generate_zip_package handles rendering failure gracefully", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_render_fail.qmd")

  # Create a Quarto document with invalid YAML that will fail to render
  writeLines(c(
    "---",
    "title: Render Fail Test",
    "format: this_is_not_a_valid_format_xyz123",
    "---",
    "",
    "Content"
  ), tmp_qmd)

  # Expect an error when rendering fails
  expect_error(
    generate_zip_package(tmp_qmd, quiet = TRUE)
  )

  # Verify that staging directory was cleaned up even after error
  staging_dir <- file.path(tmp_dir, "_test_render_fail")
  expect_false(dir.exists(staging_dir))

  # Clean up
  unlink(tmp_qmd)
})

test_that("generate_zip_package cleans up staging dir when quarto_render fails", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  original_wd <- getwd()

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  tmp_qmd <- file.path(tmp_dir, "test_render_mock_fail.qmd")

  writeLines(c(
    "---",
    "title: Mock Render Fail Test",
    "format: html",
    "---",
    "",
    "Test content"
  ), tmp_qmd)

  staging_dir <- file.path(tmp_dir, "_test_render_mock_fail")

  # Ensure cleanup happens even if test fails
  withr::defer(unlink(tmp_qmd))

  # Mock quarto_render to create staging directory then fail
  with_mocked_bindings(
    quarto_render = function(...) {
      # Create staging directory to simulate partial rendering
      dir.create(staging_dir, recursive = TRUE)
      stop("Mocked rendering failure")
    },
    .package = "quarto",
    {
      expect_error(
        generate_zip_package(tmp_qmd, quiet = TRUE),
        "Mocked rendering failure"
      )
    }
  )

  # Verify working directory was restored
  expect_equal(getwd(), original_wd)

  # Verify staging directory was cleaned up after rendering failure
  expect_false(dir.exists(staging_dir))
})

test_that("generate_zip_package handles filenames with spaces", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  # Create a filename with spaces
  tmp_qmd <- file.path(tmp_dir, "test file with spaces.qmd")

  writeLines(c(
    "---",
    "title: Test Spaces",
    "format: html",
    "---",
    "",
    "# Content",
    "",
    "Testing filenames with spaces."
  ), tmp_qmd)

  # Generate zip package
  result <- generate_zip_package(tmp_qmd, quiet = TRUE)

  # Check that zip file was created with correct name
  expect_true(file.exists(result))
  expect_equal(basename(result), "test file with spaces.zip")
  expect_equal(dirname(result), tmp_dir)

  # Check that staging directory was cleaned up
  expect_false(dir.exists(file.path(tmp_dir, "_test file with spaces")))

  # Verify the zip contains the expected content
  temp_extract <- file.path(tmp_dir, "extract_spaces_test")
  dir.create(temp_extract)
  unzip(result, exdir = temp_extract)
  expect_true(file.exists(file.path(temp_extract, "_test file with spaces", "index.html")))

  # Clean up
  unlink(result)
  unlink(temp_extract, recursive = TRUE)
  unlink(tmp_qmd)
})

test_that("generate_zip_package handles directory paths with spaces", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- normalizePath(tempdir(), mustWork = TRUE)
  # Create a subdirectory with spaces
  dir_with_spaces <- file.path(tmp_dir, "test dir with spaces")
  if (!dir.exists(dir_with_spaces)) {
    dir.create(dir_with_spaces)
  }
  withr::defer(unlink(dir_with_spaces, recursive = TRUE))

  tmp_qmd <- file.path(dir_with_spaces, "test_lesson.qmd")

  writeLines(c(
    "---",
    "title: Test Spaces in Path",
    "format: html",
    "---",
    "",
    "# Content",
    "",
    "Testing directory paths with spaces."
  ), tmp_qmd)

  # Generate zip package
  result <- generate_zip_package(tmp_qmd, quiet = TRUE)

  # Check that zip file was created
  expect_true(file.exists(result))
  expect_equal(basename(result), "test_lesson.zip")
  expect_equal(dirname(result), normalizePath(dir_with_spaces, mustWork = TRUE))

  # Check that staging directory was cleaned up
  expect_false(dir.exists(file.path(dir_with_spaces, "_test_lesson")))

  # Verify the zip contains the expected content
  temp_extract <- file.path(tmp_dir, "extract_spaces_dir_test")
  dir.create(temp_extract)
  unzip(result, exdir = temp_extract)
  expect_true(file.exists(file.path(temp_extract, "_test_lesson", "index.html")))

  # Verify HTML content is correct
  html_content <- readLines(
    file.path(temp_extract, "_test_lesson", "index.html"),
    warn = FALSE
  )
  expect_true(any(grepl(
    "Testing directory paths with spaces",
    html_content,
    ignore.case = TRUE
  )))

  # Clean up
  unlink(result)
  unlink(temp_extract, recursive = TRUE)
})

test_that("generate_zip_package restores working directory after success", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- tempdir()
  tmp_qmd <- file.path(tmp_dir, "test_wd_restore.qmd")

  writeLines(c(
    "---",
    "title: Working Directory Test",
    "format: html",
    "---",
    "",
    "Test content"
  ), tmp_qmd)

  withr::defer({
    unlink(file.path(tmp_dir, "test_wd_restore.zip"))
    unlink(tmp_qmd)
  })

  # Capture working directory before function call
  original_wd <- getwd()

  # Call function
  result <- generate_zip_package(tmp_qmd, quiet = TRUE)

  # Verify working directory was restored
  expect_equal(getwd(), original_wd)

  # Verify zip was created successfully
  expect_true(file.exists(result))
})

test_that("generate_zip_package restores working directory after render failure", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- tempdir()
  tmp_qmd <- file.path(tmp_dir, "test_wd_render_fail.qmd")

  writeLines(c(
    "---",
    "title: Working Directory Render Fail Test",
    "format: html",
    "---",
    "",
    "Test content"
  ), tmp_qmd)

  withr::defer(unlink(tmp_qmd))

  # Capture working directory before function call
  original_wd <- getwd()

  # Mock quarto_render to fail
  with_mocked_bindings(
    quarto_render = function(...) stop("Rendering failed"),
    .package = "quarto",
    {
      # Expect error from render failure
      expect_error(
        generate_zip_package(tmp_qmd, quiet = TRUE),
        "Rendering failed"
      )
    }
  )

  # Verify working directory was restored even after error
  expect_equal(getwd(), original_wd)
})

test_that("generate_zip_package restores working directory after zip failure", {
  skip_if_not_installed("quarto")
  skip_if(quarto::quarto_path() == "", "Quarto CLI not installed")

  tmp_dir <- tempdir()
  tmp_qmd <- file.path(tmp_dir, "test_wd_error.qmd")

  writeLines(c(
    "---",
    "title: Working Directory Error Test",
    "format: html",
    "---",
    "",
    "Test content"
  ), tmp_qmd)

  staging_dir <- file.path(tmp_dir, "_test_wd_error")
  withr::defer({
    # Clean up staging directory (zip file was never created due to mocked failure)
    unlink(staging_dir, recursive = TRUE)
    unlink(tmp_qmd)
  })

  # Capture working directory before function call
  original_wd <- getwd()

  # Mock the zip function to fail inside withr::with_dir()
  with_mocked_bindings(
    zip = function(...) {
      # Return non-zero status to simulate failure
      1
    },
    {
      # Expect error from zip failure
      expect_error(
        generate_zip_package(tmp_qmd, quiet = TRUE),
        "Failed to create zip file"
      )
    }
  )

  # Verify working directory was restored even after error
  expect_equal(getwd(), original_wd)

  # Verify that staging directory was preserved for debugging (per documented behavior)
  expect_true(dir.exists(staging_dir))
})
