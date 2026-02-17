# Test to see actual API error message
library(quarjar)

# Load package
devtools::load_all(".")

# Try the upload with your actual file
result <- tryCatch(
  {
    upload_web_package(
      zip_path = "/Users/francois/tmp/test-sj-package/test-lesson.zip",
      title = "test zip file"
    )
  },
  error = function(e) {
    cat("\n=== Full Error Message ===\n")
    cat(conditionMessage(e), "\n")

    cat("\n=== Error Class ===\n")
    print(class(e))

    return(NULL)
  }
)

cat("\nResult:", !is.null(result), "\n")
