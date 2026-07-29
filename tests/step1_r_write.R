#!/usr/bin/env Rscript
# Direction A, step 1: R writes an h5PYRe file that Python will read.
suppressPackageStartupMessages(library(hdf5r))
pkg <- commandArgs(trailingOnly = TRUE)[1]  # path to h5PYRe/r
for (f in list.files(file.path(pkg, "R"), full.names = TRUE)) source(f)

out <- commandArgs(trailingOnly = TRUE)[2]

tissue <- data.frame(
  patient_id     = c("PATIENT_001", "PATIENT_002", "PATIENT_003"),
  age            = c(61L, 67L, 72L),
  tumor_fraction = c(0.12, 0.34, 0.51),
  stringsAsFactors = FALSE
)
liquid <- data.frame(  # different schema on purpose
  sample_id      = c("SAMPLE_001", "SAMPLE_002"),
  ctdna_fraction = c(0.22, 0.44),
  msi_status     = c("MSS", "MSI-H"),
  stringsAsFactors = FALSE
)

write_cohorts(out, list(Tissue = tissue, Liquid = liquid),
              title = "roundtrip A (R -> Python)")
write_params(out, list(
  tf_threshold = 0.33,
  palette_hex  = c("#00857C", "#6ECEB2"),
  seed         = 42L
))

cat("R wrote:", out, "\n")
h5_tree(out)
