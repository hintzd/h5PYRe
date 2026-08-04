"""Read/write the /params group (see ../FORMAT.md)."""

import os

import h5py
import numpy as np
import yaml

from .io import put

_SCALAR_TYPES = (bool, int, float, str)


class _QuotedStrDumper(yaml.SafeDumper):
    """SafeDumper that emits every string scalar single-quoted.

    Necessary for cross-language fidelity: PyYAML's own scalar resolver does
    not treat single-letter tokens like ``n``/``y`` as booleans, so it would
    emit them bare, but R's ``yaml`` package (full YAML 1.1) reads a bare
    ``n`` as ``FALSE``. Quoting every string (keys included) keeps param names
    and values type-stable when the file is read back in either language.
    """


def _quoted_str(dumper, value):
    return dumper.represent_scalar("tag:yaml.org,2002:str", value, style="'")


_QuotedStrDumper.add_representer(str, _quoted_str)


def _normalize(value):
    """Coerce a ``read_params`` value to plain Python for YAML serialization."""
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, np.generic):
        return value.item()
    if isinstance(value, list):
        return [v.item() if isinstance(v, np.generic) else v for v in value]
    return value


def _check_param_value(name, value):
    """Reject YAML values that ``/params`` (1-D vectors of scalars) can't hold."""
    if isinstance(value, _SCALAR_TYPES):
        return
    if isinstance(value, list) and all(isinstance(v, _SCALAR_TYPES) for v in value):
        return
    raise ValueError(
        f"import_params(): param {name!r} must be a scalar or a flat list of "
        f"scalars; nested or complex values are not supported by /params"
    )


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


def export_params(path, out_file, params=None):
    """Export ``/params`` to a YAML file at ``out_file``.

    By default exports every parameter; pass ``params`` (a list of names) to
    export only a subset. Strings are emitted single-quoted so the file reads
    back with identical types in both Python and R (see ``_QuotedStrDumper``).

    YAML is a lossy-unless-quoted *external* view of the params, not part of
    the on-disk format. ``import_params`` reverses this export faithfully.
    Returns ``out_file``.
    """
    values = read_params(path)
    if params is not None:
        missing = [p for p in params if p not in values]
        if missing:
            raise KeyError(f"export_params(): no such param(s): {missing}")
        values = {p: values[p] for p in params}
    values = {name: _normalize(v) for name, v in values.items()}

    parent = os.path.dirname(out_file)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(out_file, "w", encoding="utf-8") as fh:
        yaml.dump(values, fh, Dumper=_QuotedStrDumper, default_flow_style=False,
                  sort_keys=False, allow_unicode=True)
    return out_file


def import_params(path, yaml_file, params=None, replace=False):
    """Write params from a YAML file into ``/params`` of ``path``.

    Reverses :func:`export_params`. Reads ``yaml_file`` (a mapping of param
    name -> scalar or flat list of scalars), optionally restricts to
    ``params`` (a list of names), and writes them via ``write_params`` —
    merging into any existing ``/params`` by default (per-key overwrite). Pass
    ``replace=True`` to clear ``/params`` first. Creates ``path`` if needed.

    Returns the dict of params written.
    """
    with open(yaml_file, encoding="utf-8") as fh:
        loaded = yaml.safe_load(fh)
    if loaded is None:
        loaded = {}
    if not isinstance(loaded, dict):
        raise ValueError(
            f"import_params(): {yaml_file!r} must contain a top-level mapping "
            f"of param name -> value, got {type(loaded).__name__}"
        )
    for name, value in loaded.items():
        _check_param_value(name, value)

    if params is not None:
        missing = [p for p in params if p not in loaded]
        if missing:
            raise KeyError(f"import_params(): no such param(s) in file: {missing}")
        loaded = {p: loaded[p] for p in params}

    if replace and os.path.exists(path):
        with h5py.File(path, "r+") as f:
            if "params" in f:
                del f["params"]

    write_params(path, loaded)
    return loaded
