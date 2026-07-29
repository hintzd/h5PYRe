"""Read/write the /params group (see ../FORMAT.md)."""

import os

import h5py
import numpy as np

from .io import put


def write_params(path, params):
    """Write a dict of parameters to ``/params``.

    Creates the file if it does not exist, otherwise appends/overwrites.
    """
    mode = "r+" if os.path.exists(path) else "w"
    with h5py.File(path, mode) as f:
        g = f.require_group("params")
        for name, value in params.items():
            put(g, name, value)
    return path


def read_params(path):
    """Read ``/params`` as a dict.

    Length-1 datasets are unwrapped to Python scalars; longer ones are returned
    as numpy arrays (numeric) or lists of str (text). Empty dict if no
    ``/params`` group.
    """
    out = {}
    with h5py.File(path, "r") as f:
        if "params" not in f:
            return out
        g = f["params"]
        for name in g:
            vals = np.ravel(g[name][()])
            if vals.dtype.kind in ("S", "O"):
                vals = [v.decode() if isinstance(v, bytes) else v for v in vals]
                out[name] = vals[0] if len(vals) == 1 else vals
            else:
                out[name] = vals[0].item() if len(vals) == 1 else vals
    return out
