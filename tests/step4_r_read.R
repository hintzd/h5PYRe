#!/usr/bin/env Rscript
# Direction B, step 2: R reads the Python-written file and asserts.
suppressPackageStartupMessages(library(hdf5r))
pkg <- commandArgs(trailingOnly = TRUE)[1]
for (f in list.files(file.path(pkg, "R"), full.names = TRUE)) source(f)

path <- commandArgs(trailingOnly = TRUE)[2]

cohorts <- read_cohorts(path)
params  <- read_params(path)

cat("R read cohorts:\n"); print(lapply(cohorts, names))
cat("R read params:\n");  print(params)

stopifnot(
  setequal(names(cohorts), c("Tissue", "Liquid")),
  identical(names(cohorts$Tissue), c("patient_id", "age", "tumor_fraction")),
  identical(names(cohorts$Liquid), c("sample_id", "ctdna_fraction", "msi_status")),
  nrow(cohorts$Tissue) == 2, nrow(cohorts$Liquid) == 3,
  identical(cohorts$Liquid$msi_status, c("MSI-H", "MSS", "MSS")),
  abs(params$tf_threshold - 0.31) < 1e-9,
  identical(params$palette_hex, c("#00857C", "#6ECEB2")),
  params$seed == 7
)

cat("\n[PASS] Direction B: Python -> R round-trip\n")
