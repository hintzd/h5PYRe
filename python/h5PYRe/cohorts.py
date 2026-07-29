"""Read/write cohorts as a dict of pandas DataFrames (see ../FORMAT.md)."""

import os

import h5py
import pandas as pd

from .io import put, _decode


def write_cohorts(path, cohorts, title=None, overwrite_file=True):
    """Write a dict of DataFrames to ``/cohorts/<name>/<column>``.

    Cohorts may have different schemas. ``overwrite_file=False`` appends to an
    existing file instead of creating it fresh.
    """
    mode = "w" if (overwrite_file or not os.path.exists(path)) else "a"
    with h5py.File(path, mode) as f:
        if title is not None:
            f.attrs["title"] = title
        g = f.require_group("cohorts")
        # Preserve cohort + column order (HDF5 iterates members by name, not by
        # insertion), so the round-trip is lossless.
        g.attrs["cohort_order"] = list(cohorts.keys())
        for name, df in cohorts.items():
            if name in g:
                del g[name]
            sub = g.create_group(name)
            for col in df.columns:
                put(sub, col, df[col].to_numpy())
            sub.attrs["column_order"] = list(df.columns)
    return path


def _order(node, attr_name, present):
    """Order `present` members by a recorded order attribute, if any."""
    recorded = node.attrs.get(attr_name)
    if recorded is None:
        return list(present)
    recorded = [x.decode() if isinstance(x, bytes) else str(x)
                for x in recorded]
    present = list(present)
    return [x for x in recorded if x in present] + \
           [x for x in present if x not in recorded]


def read_cohorts(path):
    """Read ``/cohorts`` as a ``dict[str, pandas.DataFrame]`` (empty if none)."""
    out = {}
    with h5py.File(path, "r") as f:
        if "cohorts" not in f:
            return out
        g = f["cohorts"]
        for name in _order(g, "cohort_order", g.keys()):
            sub = g[name]
            cols = _order(sub, "column_order", sub.keys())
            out[name] = pd.DataFrame({col: _decode(sub[col][()]) for col in cols})
    return out
