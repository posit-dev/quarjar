#' Get the Skilljar API base URL
#'
#' Returns the value of the \code{quarjar.base_url} option, falling back to
#' \code{"https://api.skilljar.com"} when the option is not set.  Set the
#' option once per session to avoid passing \code{base_url} to every function:
#'
#' \preformatted{
#' options(quarjar.base_url = "https://api.skilljar.com")
#' }
#'
#' @return Character. The Skilljar API base URL.
#' @keywords internal
quarjar_base_url <- function() {
  getOption("quarjar.base_url", default = "https://api.skilljar.com")
}


#' Perform HTTP Request with Better Error Handling
#'
#' Internal helper to perform HTTP requests with improved error messages.
#'
#' @param req An httr2 request object
#' @param operation Character. Description of the operation for error messages
#'
#' @return The response object
#' @keywords internal
perform_request <- function(req, operation = "API request") {
  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      # If it's an HTTP error, try to extract the response
      if (inherits(e, "httr2_http")) {
        return(e$resp)
      }
      # Otherwise re-throw
      rlang::abort(sprintf(
        "Failed to perform %s: %s",
        operation,
        conditionMessage(e)
      ))
    }
  )

  # Check if we got an error response
  status <- httr2::resp_status(resp)
  if (status >= 400) {
    body <- httr2::resp_body_string(resp)

    # Try to parse as JSON for better error messages
    error_detail <- tryCatch(
      {
        json_body <- jsonlite::fromJSON(body, simplifyVector = FALSE)
        if (is.list(json_body) && length(json_body) > 0) {
          # Format error details nicely with cli
          errors <- lapply(names(json_body), function(field) {
            msgs <- json_body[[field]]
            if (is.list(msgs)) msgs <- unlist(msgs)
            sprintf(
              "  %s %s: %s",
              cli::symbol$bullet,
              field,
              paste(msgs, collapse = ", ")
            )
          })
          paste(errors, collapse = "\n")
        } else {
          body
        }
      },
      error = function(e) body
    )

    rlang::abort(sprintf(
      "Failed to %s (HTTP %d):\n%s",
      operation,
      status,
      error_detail
    ))
  }

  resp
}
