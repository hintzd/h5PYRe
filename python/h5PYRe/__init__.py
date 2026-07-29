"""h5PYRe — cross-language HDF5 cohort & parameter interchange (Python side).

See ../FORMAT.md for the shared layout the R sibling package also implements.
"""

from .io import put, read_array, read_scalar, read_strings
from .cohorts import read_cohorts, write_cohorts
from .params import read_params, write_params
from .images import write_image, read_image, export_image, list_images
from .parquet import export_parquet
from .pyre import pyre
from .tree import tree

__version__ = "0.1.0"

__all__ = [
    "put",
    "read_array",
    "read_scalar",
    "read_strings",
    "read_cohorts",
    "write_cohorts",
    "read_params",
    "write_params",
    "write_image",
    "read_image",
    "export_image",
    "list_images",
    "export_parquet",
    "pyre",
    "tree",
]
