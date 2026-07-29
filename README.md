# h5cohort

A cross-language HDF5 interchange for **cohorts** (a named list / dict of data
frames) and **parameters** (small shared config/derived values). Files written
by the R package are read natively by the Python package and vice versa —
there is no runtime bridge, only a shared on-disk contract.

- **[`FORMAT.md`](FORMAT.md)** — the file-format contract, the single source of
  truth both sides implement.
- **[`r/`](r/)** — R package (`hdf5r`).
- **[`python/`](python/)** — Python package (`h5py` / `numpy` / `pandas`).
- **[`tests/`](tests/)** — cross-language round-trip test (write in one
  language, read + assert in the other, both directions).

## Why two packages

R and Python cannot share one installable, so "one package" is really two
sibling packages that agree on `FORMAT.md`. The value is the *convention*
(layout, string/scalar rules, order preservation), not shared code.

## Install

```bash
# Python
pip install ./python

# R
R CMD INSTALL r        # or: Rscript -e 'roxygen2::roxygenise("r")' first to regen docs
```

## Use

```r
library(h5cohort)
write_cohorts("cohort.h5", list(Tissue = df1, Liquid = df2), title = "demo")
write_params("cohort.h5", list(tf_threshold = 0.33, palette_hex = c("#00857C", "#6ECEB2")))
cohorts <- read_cohorts("cohort.h5")   # named list of data frames
params  <- read_params("cohort.h5")    # named list
h5_tree("cohort.h5")                    # directory-tree view
```

```python
import h5cohort as h5c
h5c.write_cohorts("cohort.h5", {"Tissue": df1, "Liquid": df2}, title="demo")
h5c.write_params("cohort.h5", {"tf_threshold": 0.33, "palette_hex": ["#00857C", "#6ECEB2"]})
cohorts = h5c.read_cohorts("cohort.h5")   # dict[str, DataFrame]
params  = h5c.read_params("cohort.h5")    # dict
h5c.tree("cohort.h5")                      # directory-tree view
```

## Test

```bash
bash tests/roundtrip.sh          # PYTHON=/path/to/python to override interpreter
```

The suite writes a file in each language and asserts the other reads it back
losslessly — same cohorts, schemas, column order, and parameter values.
