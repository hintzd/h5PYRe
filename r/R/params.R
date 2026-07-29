#' Write parameters to the `/params` group of an HDF5 file
#'
#' Creates the file if needed, otherwise appends/overwrites into it. Each
#' element of `params` is stored as a dataset under `/params/`.
#'
#' @param path Output file path.
#' @param params A named list of vectors (scalars stored as length-1).
#' @return `path`, invisibly.
#' @export
write_params <- function(path, params) {
  stopifnot(is.list(params), !is.null(names(params)))
  h5 <- hdf5r::H5File$new(path, if (file.exists(path)) "r+" else "w")
  on.exit(h5$close_all(), add = TRUE)

  g <- if (h5$exists("params")) h5[["params"]] else h5$create_group("params")
  for (nm in names(params)) h5_put(g, nm, params[[nm]])
  invisible(path)
}

#' Read the `/params` group as a named list
#'
#' @param path Input file path.
#' @return A named list of parameter vectors (empty list if no `/params`).
#' @export
read_params <- function(path) {
  h5 <- hdf5r::H5File$new(path, "r")
  on.exit(h5$close_all(), add = TRUE)
  if (!h5$exists("params")) return(list())

  g   <- h5[["params"]]
  nms <- names(g)
  stats::setNames(lapply(nms, function(nm) g[[nm]]$read()), nms)
}
