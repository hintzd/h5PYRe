# Internal helpers (not exported).

# Overwrite-safe attribute setter (hdf5r errors if the attribute exists).
.h5_set_attr <- function(node, name, value) {
  if (isTRUE(tryCatch(node$attr_exists(name), error = function(e) FALSE))) {
    node$attr_delete(name)
  }
  hdf5r::h5attr(node, name) <- value
  invisible(node)
}

# Return member names ordered by a recorded order attribute, falling back to
# `present` (the actual members) for anything not listed.
.h5_order <- function(node, attr_name, present) {
  ord <- tryCatch({
    if (node$attr_exists(attr_name)) hdf5r::h5attr(node, attr_name) else NULL
  }, error = function(e) NULL)
  if (is.null(ord)) return(present)
  ord <- as.character(ord)
  c(ord[ord %in% present], setdiff(present, ord))
}
