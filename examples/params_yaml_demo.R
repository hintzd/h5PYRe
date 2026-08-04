#!/usr/bin/env Rscript
# Demo: the export_params / import_params YAML workflow in h5PYRe (R side).
# Run with the package sources on hand, e.g. from the repo root:
#   Rscript examples/params_yaml_demo.R r
# (arg 1 = path to the r/ package dir; defaults to ../r relative to this file)

args <- commandArgs(trailingOnly = TRUE)
rpkg <- if (length(args) >= 1) args[1] else "r"
suppressPackageStartupMessages(library(hdf5r))
for (f in list.files(file.path(rpkg, "R"), full.names = TRUE)) source(f)

work    <- tempfile("h5pyre_demo_"); dir.create(work)
h5_path <- file.path(work, "study.h5")
yaml_p  <- file.path(work, "params.yaml")

# 1. Seed a cohort + analysis params
cohort <- data.frame(
  patient_id = c("PATIENT_001", "PATIENT_002", "PATIENT_003"),
  tumor_fraction = c(0.05, 0.62, 0.33),
  stringsAsFactors = FALSE
)
write_cohorts(h5_path, list(Tissue = cohort), title = "params YAML demo")
write_params(h5_path, list(
  tf_threshold = 0.33,
  min_coverage = 500L,
  call_status  = "no",                 # a STRING "no", not a logical
  bin_edges    = c(0.0, 0.1, 0.25, 1.0),
  palette_hex  = c("#00857C", "#6ECEB2")
))
cat("1. initial params:\n"); str(read_params(h5_path))

# 2. Export to editable YAML
export_params(h5_path, yaml_p)
cat("\n2. exported YAML:\n"); cat(readLines(yaml_p), sep = "\n"); cat("\n")

# 3. Edit the YAML (bump one, add one)
txt <- readLines(yaml_p)
txt <- sub("tf_threshold: 0.33", "tf_threshold: 0.4", txt)
txt <- c(txt, "analyst: jdoe")
writeLines(txt, yaml_p)

# 4. Import back (merges by default)
import_params(h5_path, yaml_p)
p <- read_params(h5_path)
cat("\n4. params after import (merged):\n"); str(p)
stopifnot(
  abs(p$tf_threshold - 0.4) < 1e-9,
  identical(p$analyst, "jdoe"),
  identical(p$call_status, "no"),      # stayed character, not FALSE
  p$min_coverage == 500                # untouched key preserved
)

# 5. Subset export + replace-on-import
subset_y <- file.path(work, "subset.yaml")
export_params(h5_path, subset_y, params = c("tf_threshold", "palette_hex"))
fresh <- file.path(work, "fresh.h5")
import_params(fresh, subset_y, replace = TRUE)
cat("\n5. fresh file from subset (replace=TRUE):\n"); str(read_params(fresh))
stopifnot(setequal(names(read_params(fresh)), c("tf_threshold", "palette_hex")))

cat("\nOK - demo complete. Files in:", work, "\n")
