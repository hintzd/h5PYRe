"""Directory-tree view of an HDF5 file (mirror of R's print.H5File)."""

import os

import h5py
import numpy as np

_KIND_LABEL = {"i": "int", "u": "int", "f": "dbl",
               "S": "str", "O": "str", "U": "str", "b": "bool"}


def _type_label(dset):
    return _KIND_LABEL.get(dset.dtype.kind, str(dset.dtype))


def _fmt_attr(v):
    if isinstance(v, bytes):
        v = v.decode()
    arr = np.ravel(v)
    parts = [f'"{x.decode() if isinstance(x, bytes) else x}"'
             if isinstance(x, (str, bytes)) else str(x) for x in arr]
    if len(parts) > 3:
        parts = parts[:3] + ["..."]
    return ", ".join(parts)


def _walk(node, prefix, lines):
    keys = list(node.keys())
    for i, k in enumerate(keys):
        last = i == len(keys) - 1
        conn = "└─ " if last else "├─ "
        pad = "   " if last else "│  "
        item = node[k]
        if isinstance(item, h5py.Group):
            lines.append(f"{prefix}{conn}{k}/")
            for ak, av in item.attrs.items():
                lines.append(f"{prefix}{pad}@ {ak} = {_fmt_attr(av)}")
            _walk(item, prefix + pad, lines)
        else:
            dims = "x".join(str(d) for d in item.shape) or "scalar"
            lines.append(f"{prefix}{conn}{k:<18} {_type_label(item):<4} [{dims}]")


def tree(path):
    """Return (and print) a directory-tree string for the HDF5 file at ``path``."""
    lines = [f"{os.path.basename(path)}  <HDF5 file>"]
    with h5py.File(path, "r") as f:
        for ak, av in f.attrs.items():
            lines.append(f"  @ {ak} = {_fmt_attr(av)}")
        _walk(f, "", lines)
    s = "\n".join(lines)
    print(s)
    return s
