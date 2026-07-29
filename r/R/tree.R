# Directory-tree view of an HDF5 file.
#
# `print.H5File` is an S3 method; H5File's class is
# c("H5File", "H5RefClass", "R6"), so it takes precedence over R6's default
# printer via normal S3 dispatch. `h5_tree()` is a convenience wrapper that
# opens a path read-only and prints it.

# Map HDF5 type classes to short, friendly labels.
.h5_type_label <- function(type_class) {
  switch(as.character(type_class),
         H5T_INTEGER  = "int",
         H5T_FLOAT    = "dbl",
         H5T_STRING   = "str",
         H5T_ENUM     = "enum",
         H5T_COMPOUND = "compound",
         sub("^H5T_", "", tolower(as.character(type_class))))
}

.h5_fmt_attr <- function(v) {
  if (is.character(v)) v <- shQuote(v, type = "cmd")
  v <- as.character(v)
  if (length(v) > 3) v <- c(v[1:3], "...")
  paste(v, collapse = ", ")
}

.h5_print_attrs <- function(node, line_prefix) {
  attrs <- tryCatch(hdf5r::h5attributes(node), error = function(e) list())
  for (nm in names(attrs)) {
    cat(sprintf("%s@ %s = %s\n", line_prefix, nm, .h5_fmt_attr(attrs[[nm]])))
  }
}

.h5_walk <- function(node, prefix) {
  entries <- node$ls()
  n <- nrow(entries)
  if (n == 0) return(invisible(NULL))
  for (i in seq_len(n)) {
    last      <- i == n
    connector <- if (last) "└─ " else "├─ "  # last / mid
    child_pad <- if (last) "   " else "│  "
    row       <- entries[i, ]

    if (row$obj_type == "H5I_GROUP") {
      cat(sprintf("%s%s%s/\n", prefix, connector, row$name))
      sub <- node[[row$name]]
      .h5_print_attrs(sub, paste0(prefix, child_pad))
      .h5_walk(sub, paste0(prefix, child_pad))
    } else {
      # hdf5r reports dims in R (column-major) order, reversed from the
      # on-disk/HDF5 order. Reverse for display so N-D shapes read the same as
      # they do from Python/h5py (e.g. an image shows H x W x C, not C x W x H).
      dims <- strsplit(as.character(row$dataset.dims), " x ", fixed = TRUE)[[1]]
      cat(sprintf("%s%s%-18s %-4s [%s]\n",
                  prefix, connector, row$name,
                  .h5_type_label(row$dataset.type_class),
                  paste(rev(dims), collapse = " x ")))
    }
  }
  invisible(NULL)
}

#' Print an HDF5 file as a directory tree
#'
#' @param x An open [hdf5r::H5File].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.H5File <- function(x, ...) {
  fname <- tryCatch(basename(x$get_filename()), error = function(e) "<H5File>")
  cat(sprintf("%s  <HDF5 file>\n", fname))
  .h5_print_attrs(x, "  ")
  .h5_walk(x, "")
  invisible(x)
}

#' Open an HDF5 file read-only and print its tree
#'
#' @param path File path.
#' @return `path`, invisibly. (The file is opened read-only and closed on exit;
#'   the closed handle is deliberately not returned.)
#' @export
h5_tree <- function(path) {
  h5 <- hdf5r::H5File$new(path, "r")
  on.exit(h5$close_all(), add = TRUE)
  print(h5)
  invisible(path)
}
