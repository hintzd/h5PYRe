"""Low-level HDF5 read/write helpers shared by the cohort and param APIs."""

import h5py
import numpy as np

_STR_KINDS = ("U", "S", "O")


def _as_1d(value):
    """Coerce a scalar or sequence to a 1-D numpy array (scalars -> length 1)."""
    return np.atleast_1d(np.asarray(value))


def put(node, name, value):
    """Overwrite-safe write of ``value`` to dataset ``name`` under ``node``.

    Strings are stored as variable-length UTF-8 so the R side reads them as
    native character vectors. Existing links of the same name are replaced.
    """
    if name in node:
        del node[name]
    arr = _as_1d(value)
    if arr.dtype.kind in _STR_KINDS:
        dt = h5py.string_dtype(encoding="utf-8")
        node.create_dataset(name, data=arr.astype(object), dtype=dt)
    else:
        node.create_dataset(name, data=arr)
    return node


def _decode(vals):
    """Ravel a dataset value; decode byte strings to str."""
    vals = np.ravel(vals)
    if vals.dtype.kind in ("S", "O"):
        return [v.decode() if isinstance(v, bytes) else v for v in vals]
    return vals


def read_array(f, path):
    """Read a dataset as a 1-D numpy array (or list of str for text)."""
    return _decode(f[path][()])


def read_scalar(f, path):
    """Read a length-1 dataset as a single Python scalar."""
    v = _decode(f[path][()])
    v0 = v[0]
    return v0.item() if hasattr(v0, "item") else v0


def read_strings(f, path):
    """Read a (byte-)string dataset as a list of str."""
    return [s.decode() if isinstance(s, bytes) else s
            for s in np.ravel(f[path][()])]
