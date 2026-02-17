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
upload_asset <- function(file_path, api_key = Sys.getenv("SKILLJAR_API_KEY"), base_url = "https://api.skilljar.com") {
  if (!file.exists(file_path)) {
    rlang::abort(sprintf("File not found: %s", file_path))
  }

  # Get the file name to use as the asset name
  file_name <- basename(file_path)

  # The API expects multipart/form-data with:
  # - file: the binary file data
  # - asset metadata: can be sent as nested form fields (asset[name], asset[sync_completion])
  #   or as a JSON string in the asset field
  # Trying nested form field notation first (common in Django REST Framework)
  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/assets") |>
    httr2::req_body_multipart(
      file = curl::form_file(file_path),
      `asset[name]` = file_name
    )

  resp <- perform_request(req, sprintf("upload asset '%s'", file_name))
  body <- httr2::resp_body_json(resp)

  if (is.null(body$id)) {
    rlang::abort("No asset ID returned from Skilljar API")
  }

  cli::cli_alert_success("Asset uploaded with ID: {body$id}")

  body$id
}


#' List Assets
#'
#' Retrieves a paginated list of all assets in your organization.
#'
#' @param page Integer. Page number to retrieve. Default is 1.
#' @param page_size Integer. Number of results per page. Default is 20.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing:
#'   \itemize{
#'     \item count - Total number of assets
#'     \item next - URL for next page (if available)
#'     \item previous - URL for previous page (if available)
#'     \item results - List of asset summaries
#'   }
#'
#' @examples
#' \dontrun{
#' # List all assets (first page)
#' assets <- list_assets()
#'
#' # List with custom page size
#' assets <- list_assets(page = 1, page_size = 50)
#'
#' # Check asset types
#' for (asset in assets$results) {
#'   cat(asset$name, "-", asset$type, "\n")
#' }
#' }
#'
#' @export
list_assets <- function(
  page = 1,
  page_size = 20,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/assets") |>
    httr2::req_url_query(
      page = as.integer(page),
      page_size = as.integer(page_size)
    )

  resp <- perform_request(req, "list assets")
  httr2::resp_body_json(resp)
}


#' Get Asset Details
#'
#' Retrieves detailed information for a specific asset, including a signed download URL.
#'
#' @param asset_id Character. The ID of the asset to retrieve.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return A list containing the asset details including:
#'   \itemize{
#'     \item id - Asset ID
#'     \item type - Asset type (FILE, PDF, VIDEO_BOTR, etc.)
#'     \item name - Asset name/display name
#'     \item download_url - Signed URL for downloading (valid for 1 hour)
#'     \item embed_link_url - Embed link (if applicable)
#'     \item sync_completion - Whether completion is synchronized
#'   }
#'
#' @examples
#' \dontrun{
#' # Get asset details
#' asset <- get_asset(asset_id = "abc123")
#' cat("Asset type:", asset$type, "\n")
#' cat("Download URL:", asset$download_url, "\n")
#' }
#'
#' @export
get_asset <- function(
  asset_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  if (missing(asset_id) || is.null(asset_id)) {
    rlang::abort("asset_id is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/assets") |>
    httr2::req_url_path_append(as.character(asset_id))

  resp <- perform_request(req, "retrieve asset details")
  httr2::resp_body_json(resp)
}


#' Delete Asset
#'
#' Permanently deletes an asset from your organization.
#' The asset will be removed if it is not currently used in any lessons or courses.
#'
#' @param asset_id Character. The ID of the asset to delete.
#' @param api_key Character. Skilljar API key for authentication.
#'   Default reads from SKILLJAR_API_KEY environment variable.
#' @param base_url Character. Base URL for the Skilljar API.
#'   Default is "https://api.skilljar.com".
#'
#' @return Invisible NULL on success.
#'
#' @examples
#' \dontrun{
#' delete_asset(asset_id = "abc123")
#' }
#'
#' @export
delete_asset <- function(
  asset_id,
  api_key = Sys.getenv("SKILLJAR_API_KEY"),
  base_url = "https://api.skilljar.com"
) {
  if (missing(asset_id) || is.null(asset_id)) {
    rlang::abort("asset_id is required")
  }

  req <- skilljar_request(api_key = api_key, base_url = base_url) |>
    httr2::req_url_path_append("v1/assets") |>
    httr2::req_url_path_append(as.character(asset_id)) |>
    httr2::req_method("DELETE")

  perform_request(req, "delete asset")
  cli::cli_alert_success("Asset {asset_id} deleted")

  invisible(NULL)
}
