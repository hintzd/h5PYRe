#' Export cohort tables to a Parquet dataset directory
#'
#' By default writes every cohort in `path` to `out_dir/<cohort>.parquet`; pass
#' `tables` (a character vector of cohort names) to export only a subset. Each
#' cohort becomes its own Parquet file (cohorts may have different schemas, so
#' they are not merged into a single partitioned dataset). The directory is
#' created if needed.
#'
#' @param path HDF5 file path.
#' @param out_dir Output directory for the Parquet files.
#' @param tables Optional character vector of cohort names (default: all).
#' @return A named character vector mapping cohort name -> written file path,
#'   invisibly.
#' @export
export_parquet <- function(path, out_dir, tables = NULL) {
  cohorts <- read_cohorts(path)
  if (!is.null(tables)) {
    missing <- setdiff(tables, names(cohorts))
    if (length(missing)) {
      stop(sprintf("export_parquet(): no such table(s): %s",
                   paste(missing, collapse = ", ")))
    }
    cohorts <- cohorts[tables]
  }
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  written <- character(0)
  for (nm in names(cohorts)) {
    fp <- file.path(out_dir, paste0(nm, ".parquet"))
    arrow::write_parquet(cohorts[[nm]], fp)
    written[nm] <- fp
  }
  invisible(written)
}
