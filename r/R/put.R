#' Overwrite-safe write of a value into an HDF5 group or file
#'
#' Writes `value` as a dataset named `name` directly under `node`. If a link of
#' that name already exists it is deleted first, so re-running is idempotent.
#'
#' @param node An open [hdf5r::H5File] or [hdf5r::H5Group].
#' @param name Dataset name, relative to `node`.
#' @param value A vector to store.
#' @return `node`, invisibly.
#' @export
h5_put <- function(node, name, value) {
  if (node$exists(name)) node$link_delete(name)
  node[[name]] <- value
  invisible(node)
}
