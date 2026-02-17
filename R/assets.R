#' Upload Asset to Skilljar
#'
#' Uploads a file as an asset to Skilljar and returns the asset ID.
#'
#' @param file_path Character. Path to the file to upload.
#' @param api_key Character. Skilljar API key for authentication.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return Character. The asset ID of the uploaded file.
#'
#' @examples
#' \dontrun{
#' asset_id <- upload_asset(
#'   file_path = "content.html",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#' }
#'
#' @export
upload_asset <- function(file_path, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  if (!file.exists(file_path)) {
    rlang::abort(sprintf("File not found: %s", file_path))
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/assets") |>
    httr2::req_body_multipart(
      file = curl::form_file(file_path)
    )

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) != 201) {
    rlang::abort(sprintf(
      "Failed to upload asset. Status: %d, Body: %s",
      httr2::resp_status(resp),
      httr2::resp_body_string(resp)
    ))
  }

  body <- httr2::resp_body_json(resp)

  if (is.null(body$id)) {
    rlang::abort("No asset ID returned from Skilljar API")
  }

  body$id
}
