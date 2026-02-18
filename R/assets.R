#' Upload Asset to Skilljar
#'
#' Uploads a file as an asset to Skilljar and returns the asset ID.
#' This is a utility function for uploading non-HTML content types or files
#' that need to be referenced from within HTML content (images, PDFs, etc.).
#'
#' Note: For publishing HTML lesson content, use `publish_html_content()` instead,
#' which directly embeds the HTML in a content item. This function is intended for
#' uploading supporting assets or non-HTML file types.
#'
#' @param file_path Character. Path to the file to upload.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return Character. The asset ID of the uploaded file.
#'
#' @examples
#' \dontrun{
#' # Upload an image asset
#' asset_id <- upload_asset(
#'   file_path = "images/diagram.png",
#'   api_key = Sys.getenv("SKILLJAR_API_KEY")
#' )
#'
#' # Upload a PDF document
#' pdf_id <- upload_asset(
#'   file_path = "resources/reference.pdf"
#' )
#' }
#'
#' @export
upload_asset <- function(
  file_path,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
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
