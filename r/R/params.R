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

#' Export the `/params` group to a YAML file
#'
#' By default exports every parameter; pass `params` (a character vector of
#' names) to export only a subset. YAML is a lossy-unless-quoted *external*
#' view of the params (not part of the on-disk format); `import_params()`
#' reverses this export faithfully. R's `yaml` emitter already quotes the
#' YAML-1.1 ambiguous tokens (e.g. `no`, `n`, `on`), so files it writes read
#' back with identical types in both R and Python.
#'
#' @param path Input h5PYRe file.
#' @param out_file Output YAML file path.
#' @param params Optional character vector of parameter names to export.
#' @return `out_file`, invisibly.
#' @export
export_params <- function(path, out_file, params = NULL) {
  values <- read_params(path)
  if (!is.null(params)) {
    missing <- setdiff(params, names(values))
    if (length(missing))
      stop("export_params(): no such param(s): ", paste(missing, collapse = ", "))
    values <- values[params]
  }
  parent <- dirname(out_file)
  if (nzchar(parent) && !dir.exists(parent))
    dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(values, out_file)
  invisible(out_file)
}

#' Write params from a YAML file into the `/params` group
#'
#' Reverses [export_params()]. Reads `yaml_file` (a mapping of param name to a
#' scalar or flat vector of scalars), optionally restricts to `params`, and
#' writes them via [write_params()] — merging into any existing `/params` by
#' default (per-key overwrite). Pass `replace = TRUE` to clear `/params`
#' first. Creates `path` if needed.
#'
#' @param path Output h5PYRe file.
#' @param yaml_file Input YAML file path.
#' @param params Optional character vector of parameter names to import.
#' @param replace If `TRUE`, delete the existing `/params` group before writing.
#' @return The named list of params written, invisibly.
#' @export
import_params <- function(path, yaml_file, params = NULL, replace = FALSE) {
  loaded <- yaml::read_yaml(yaml_file)
  if (is.null(loaded)) loaded <- list()
  if (!is.list(loaded) || is.null(names(loaded)) || any(!nzchar(names(loaded))))
    stop("import_params(): '", yaml_file,
         "' must contain a top-level mapping of param name -> value")
  for (nm in names(loaded)) {
    v <- loaded[[nm]]
    if (is.list(v) || !is.atomic(v))
      stop("import_params(): param '", nm, "' must be a scalar or a flat ",
           "vector of scalars; nested or complex values are not supported")
  }
  if (!is.null(params)) {
    missing <- setdiff(params, names(loaded))
    if (length(missing))
      stop("import_params(): no such param(s) in file: ",
           paste(missing, collapse = ", "))
    loaded <- loaded[params]
  }
  if (replace && file.exists(path)) {
    h5 <- hdf5r::H5File$new(path, "r+")
    if (h5$exists("params")) h5$link_delete("params")
    h5$close_all()
  }
  write_params(path, loaded)
  invisible(loaded)
}
