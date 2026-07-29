# Delete an h5PYRe file -- light the pyre.
#
# The h5PYRe file is a *serialized* cross-language interchange (write, close,
# then the other side reads), NOT concurrent shared memory: HDF5 is unsafe for
# simultaneous writers. pyre() is the scratch cleanup step for that workflow.

.is_hdf5 <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  sig <- readBin(con, "raw", n = 8L)
  identical(sig, as.raw(c(0x89, 0x48, 0x44, 0x46, 0x0d, 0x0a, 0x1a, 0x0a)))
}

#' Delete an h5PYRe file
#'
#' By default refuses to delete anything that is not an HDF5 file (guards
#' against a typo wiping the wrong file); set `require_h5 = FALSE` to force.
#' A missing file is a no-op with a warning.
#'
#' @param path File path to delete.
#' @param require_h5 If `TRUE` (default), only delete files with an HDF5
#'   signature.
#' @return `path`, invisibly.
#' @export
pyre <- function(path, require_h5 = TRUE) {
  if (!file.exists(path)) {
    warning(sprintf("pyre(): no file at '%s' -- nothing to delete", path))
    return(invisible(path))
  }
  if (require_h5 && !.is_hdf5(path)) {
    stop(sprintf(
      "pyre(): '%s' is not an HDF5 file; set require_h5 = FALSE to override",
      path))
  }
  unlink(path, force = TRUE)
  invisible(path)
}
