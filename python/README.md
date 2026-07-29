# h5PYRe (Python)

Python side of the cross-language `h5PYRe` HDF5 interchange. See
`../FORMAT.md` for the shared file-format contract that the R sibling package
implements identically.

```python
import h5PYRe as h5c
import pandas as pd

h5c.write_cohorts("cohort.h5", {"Tissue": df1, "Liquid": df2}, title="demo")
h5c.write_params("cohort.h5", {"tf_threshold": 0.33, "palette": ["#00857C"]})

cohorts = h5c.read_cohorts("cohort.h5")   # dict[str, pd.DataFrame]
params  = h5c.read_params("cohort.h5")    # dict
print(h5c.tree("cohort.h5"))              # directory-tree view
```
