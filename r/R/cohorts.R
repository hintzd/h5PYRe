#' Write a named list of cohorts to an HDF5 file
#'
#' Each element of `cohorts` becomes a group under `/cohorts/<name>/`, with one
#' dataset per column. Cohorts may have different schemas.
#'
#' @param path Output file path.
#' @param cohorts A named list of data frames.
#' @param title Optional root attribute stored on the file.
#' @param overwrite_file If `TRUE` (default) create the file fresh; if `FALSE`
#'   append to an existing file.
#' @return `path`, invisibly.
#' @export
write_cohorts <- function(path, cohorts, title = NULL, overwrite_file = TRUE) {
  stopifnot(is.list(cohorts), !is.null(names(cohorts)))
  mode <- if (overwrite_file || !file.exists(path)) "w" else "a"
  h5 <- hdf5r::H5File$new(path, mode)
  on.exit(h5$close_all(), add = TRUE)

  if (!is.null(title)) .h5_set_attr(h5, "title", title)
  g <- if (h5$exists("cohorts")) h5[["cohorts"]] else h5$create_group("cohorts")

  # Preserve cohort + column order (HDF5 iterates members by name, not by
  # insertion), so the round-trip is lossless.
  .h5_set_attr(g, "cohort_order", names(cohorts))
  for (nm in names(cohorts)) {
    if (g$exists(nm)) g$link_delete(nm)
    sub <- g$create_group(nm)
    df  <- cohorts[[nm]]
    for (col in names(df)) sub[[col]] <- df[[col]]
    .h5_set_attr(sub, "column_order", names(df))
  }
  invisible(path)
}

#' Read cohorts from an HDF5 file as a named list of data frames
#'
#' @param path Input file path.
#' @return A named list of data frames, one per cohort (empty list if the file
#'   has no `/cohorts` group).
#' @export
read_cohorts <- function(path) {
  h5 <- hdf5r::H5File$new(path, "r")
  on.exit(h5$close_all(), add = TRUE)
  if (!h5$exists("cohorts")) return(list())

  g   <- h5[["cohorts"]]
  nms <- .h5_order(g, "cohort_order", names(g))
  stats::setNames(lapply(nms, function(nm) {
    sub  <- g[[nm]]
    cols <- .h5_order(sub, "column_order", names(sub))
    as.data.frame(stats::setNames(lapply(cols, function(cc) sub[[cc]]$read()), cols),
                  stringsAsFactors = FALSE)
  }), nms)
}
