# Read/write images as compressed multidimensional datasets under /images.
#
# Canonical on-disk layout is row-major (H, W[, C]) with 0-255 integer values
# and gzip compression, matching NumPy/Pillow. hdf5r reverses axis order
# relative to h5py, so we reverse-permute on write and read; R users always
# work with natural (H, W[, C]) arrays. See ../FORMAT.md.

#' Store an image as a compressed dataset under `/images/<name>`
#'
#' @param path HDF5 file path.
#' @param name Image name.
#' @param image Either a path to a PNG file or a numeric/integer array
#'   (`(H, W)` grayscale or `(H, W, C)` color, values 0-255 or 0-1).
#' @param level gzip compression level (0-9).
#' @return `path`, invisibly.
#' @export
write_image <- function(path, name, image, level = 6L) {
  source <- ""
  if (is.character(image) && length(image) == 1L && file.exists(image)) {
    arr    <- png::readPNG(image)        # (H,W) or (H,W,C), values in [0, 1]
    arr    <- round(arr * 255)
    source <- basename(image)
  } else {
    arr <- image
    if (max(arr, na.rm = TRUE) <= 1) arr <- round(arr * 255)  # accept [0,1]
  }
  storage.mode(arr) <- "integer"

  # Canonical disk layout is row-major (H,W[,C]); hdf5r reverses axes, so
  # pre-reverse here to land on that layout for the Python side.
  disk <- aperm(arr, rev(seq_along(dim(arr))))

  h5 <- hdf5r::H5File$new(path, if (file.exists(path)) "r+" else "w")
  on.exit(h5$close_all(), add = TRUE)
  g <- if (h5$exists("images")) h5[["images"]] else h5$create_group("images")
  if (g$exists(name)) g$link_delete(name)
  d <- g$create_dataset(name, robj = disk,
                        gzip_level = as.integer(level),
                        chunk_dims = dim(disk))
  .h5_set_attr(d, "format", "png")
  .h5_set_attr(d, "axis_order", if (length(dim(arr)) == 3L) "HWC" else "HW")
  if (nzchar(source)) .h5_set_attr(d, "source", source)
  invisible(path)
}

#' Read a stored image as an integer array (H, W[, C]), values 0-255
#'
#' @param path HDF5 file path.
#' @param name Image name.
#' @return An integer array in natural `(H, W[, C])` orientation.
#' @export
read_image <- function(path, name) {
  h5 <- hdf5r::H5File$new(path, "r")
  on.exit(h5$close_all(), add = TRUE)
  raw <- h5[[paste0("images/", name)]]$read()
  aperm(raw, rev(seq_along(dim(raw))))   # restore natural orientation
}

#' Export a stored image back to disk as a PNG
#'
#' @param path HDF5 file path.
#' @param name Image name.
#' @param out_path Output PNG path.
#' @return `out_path`, invisibly.
#' @export
export_image <- function(path, name, out_path) {
  arr <- read_image(path, name)          # 0-255 integer, (H, W[, C])
  png::writePNG(arr / 255, out_path)
  invisible(out_path)
}

#' List image names stored under `/images`
#'
#' @param path HDF5 file path.
#' @return A character vector of image names (empty if none).
#' @export
list_images <- function(path) {
  h5 <- hdf5r::H5File$new(path, "r")
  on.exit(h5$close_all(), add = TRUE)
  if (!h5$exists("images")) return(character(0))
  names(h5[["images"]])
}
