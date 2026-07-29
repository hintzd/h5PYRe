"""Export the cohort tables in an h5PYRe file to a Parquet dataset directory."""

import os

from .cohorts import read_cohorts


def export_parquet(path, out_dir, tables=None):
    """Write cohorts in ``path`` to ``out_dir/<cohort>.parquet``.

    By default exports every cohort; pass ``tables`` (a list of cohort names)
    to export only a subset. Each cohort becomes its own Parquet file (cohorts
    may have different schemas, so they are not merged into a single
    partitioned dataset). The directory is created if needed.

    Returns a dict mapping cohort name -> written file path.
    """
    cohorts = read_cohorts(path)
    if tables is not None:
        missing = [t for t in tables if t not in cohorts]
        if missing:
            raise KeyError(f"export_parquet(): no such table(s): {missing}")
        cohorts = {t: cohorts[t] for t in tables}
    os.makedirs(out_dir, exist_ok=True)
    written = {}
    for name, df in cohorts.items():
        fp = os.path.join(out_dir, f"{name}.parquet")
        df.to_parquet(fp, index=False)
        written[name] = fp
    return written
