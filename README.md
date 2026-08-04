# h5PYRe

A cross-language HDF5 interchange for cohorts (tables - a named list in R / dict in Python of data frames)
and parameters (small shared config/derived values). Files written
by the R package are read natively by the Python package and vice versa —
there is no runtime bridge, only a shared on-disk contract.

- **[`FORMAT.md`](FORMAT.md)** — the file-format contract, the single source of
  truth both sides implement.
- **[`r/`](r/)** — R package (`hdf5r`).
- **[`python/`](python/)** — Python package (`h5py` / `numpy` / `pandas`).
- **[`tests/`](tests/)** — cross-language round-trip test (write in one
  language, read + assert in the other, both directions).

## Why h5PYRe - the scratchpad model

Data-science work is mostly *exploratory*. A real analysis cycle spins off far
more than its final deliverable: intermediate cohort tables, one-off diagnostic
plots, derived thresholds, palettes and other config - most of which never make
it into the finished product but clutter the working directory as loose `.csv`,
`.png` and `.yml` files while you iterate.

h5PYRe treats a single `.h5` file as that **scratchpad**. For the bulk of a
workflow *everything* lives inside one file - cohorts, parameters and rendered
images together - instead of scattered across the filesystem. You write and
overwrite freely as the analysis evolves, in either R or Python, each reading
the other's outputs through the shared `FORMAT.md` contract.

When the analysis settles, you **export only the outputs you actually need**
(e.g. the final cohort tables to Parquet, the figures you're keeping), point 
a final report or notebook - Quarto (.qmd), R Markdown (.Rmd), or Jupyter (.ipynb)
- at those exports, and then throw the scratchpad away - pyre() deletes the .h5
file. The clutter never reaches the deliverable; the report depends only on the
handful of exported artifacts.

The lifecycle, end to end:

1. **Write** cohorts, params and images into `my-project.h5` as you explore
   (R and/or Python).
2. **Read** them back across languages - no re-run, no bridge, just the file.
3. **Export** the keepers (Parquet tables, images) for the final report.
4. **Tear down** with `pyre("my-project.h5")` once you're done.

## Why two packages

R and Python cannot share one installable, so "one package" is really two
sibling packages that agree on `FORMAT.md`. The value is the *convention*
(layout, string/scalar rules, order preservation), not shared code.

## Install

### If cloning

```bash
# Python
pip install ./python

# R
R CMD INSTALL r        # or: Rscript -e 'roxygen2::roxygenise("r")' first to regen docs
```

### Otherwise (install directly from GitHub)

```bash
# Python
pip install "git+https://github.com/hintzd/h5PYRe.git#subdirectory=python"

# R
Rscript -e "devtools::install_github('hintzd/h5PYRe', subdir = 'r')"
```

## Use

```r
library(h5PYRe)
write_cohorts("my-project.h5", list(Tissue = df1, Liquid = df2), title = "demo")
write_params("my-project.h5", list(tf_threshold = 0.33, palette_hex = c("#00857C", "#6ECEB2")))
cohorts <- read_cohorts("my-project.h5")   # named list of data frames
params  <- read_params("my-project.h5")    # named list
h5_tree("my-project.h5")                    # directory-tree view
```

```python
import h5PYRe as h5c
h5c.write_cohorts("my-project.h5", {"Tissue": df1, "Liquid": df2}, title="demo")
h5c.write_params("my-project.h5", {"tf_threshold": 0.33, "palette_hex": ["#00857C", "#6ECEB2"]})
cohorts = h5c.read_cohorts("my-project.h5")   # dict[str, DataFrame]
params  = h5c.read_params("my-project.h5")    # dict
h5c.tree("my-project.h5")                      # directory-tree view
```

## Test

```bash
bash tests/roundtrip.sh          # PYTHON=/path/to/python to override interpreter
```

The suite writes a file in each language and asserts the other reads it back
losslessly — same cohorts, schemas, column order, and parameter values.
