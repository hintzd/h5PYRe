#!/usr/bin/env Rscript
# Direction C, step 2: R reads the Python-written image, checks orientation,
# and exports it back to disk.
suppressPackageStartupMessages({ library(hdf5r); library(png) })
pkg <- commandArgs(trailingOnly = TRUE)[1]
tmp <- commandArgs(trailingOnly = TRUE)[2]
for (f in list.files(file.path(pkg, "R"), full.names = TRUE)) source(f)

im <- read_image(file.path(tmp, "c.h5"), "pic")
stopifnot(
  identical(dim(im), c(24L, 36L, 3L)),   # (H, W, C) preserved, not transposed
  all(im[1, 1, ] == c(255, 0, 0)),       # red marker in the top-left
  all(im[24, 36, ] == c(0, 180, 0))      # green background far corner
)
export_image(file.path(tmp, "c.h5"), tmp, images = "pic")  # writes tmp/pic.png
cat("  R read", paste(dim(im), collapse = "x"), "and exported pic.png\n")
