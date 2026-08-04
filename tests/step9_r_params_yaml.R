#!/usr/bin/env Rscript
# Direction D, step 2: R imports the Python-written params YAML, asserts the
# ambiguous tokens survived as the right types, then re-exports a YAML for
# Python to check in step 10.
suppressPackageStartupMessages(library(hdf5r))
pkg <- commandArgs(trailingOnly = TRUE)[1]
for (f in list.files(file.path(pkg, "R"), full.names = TRUE)) source(f)

out_dir  <- commandArgs(trailingOnly = TRUE)[2]
py_yaml  <- file.path(out_dir, "fromPy_params.yaml")
r_h5     <- file.path(out_dir, "fromR_params.h5")
r_yaml   <- file.path(out_dir, "fromR_params.yaml")
if (file.exists(r_h5)) file.remove(r_h5)

import_params(r_h5, py_yaml)
p <- read_params(r_h5)
cat("R read params from Python YAML:\n"); print(p)

stopifnot(
  identical(p$flag_no, "no"),          # not FALSE
  identical(p$single_n, "n"),          # not FALSE
  identical(p$code, "007"),            # not integer 7
  abs(p$tf_threshold - 0.31) < 1e-9,
  p$seed == 7,
  identical(as.integer(p$bins), c(1L, 2L, 3L)),
  identical(p$palette_hex, c("#00857C", "#6ECEB2")),
  identical(p$labels, c("a", "no", "on"))
)

export_params(r_h5, r_yaml)
cat("\n[PASS] Direction D step 2: R imported Python YAML, re-exported ->", r_yaml, "\n")
