"""Delete an h5PYRe file — light the pyre.

The h5PYRe file is a *serialized* cross-language interchange (write, close,
then the other side reads), NOT concurrent shared memory: HDF5 is unsafe for
simultaneous writers. ``pyre`` is the scratch cleanup step for that workflow.
"""

import os
import warnings

_HDF5_MAGIC = b"\x89HDF\r\n\x1a\n"  # HDF5 superblock signature (offset 0)


def _is_hdf5(path):
    try:
        with open(path, "rb") as f:
            return f.read(8) == _HDF5_MAGIC
    except OSError:
        return False


def pyre(path, require_h5=True):
    """Delete the file at ``path``.

    By default refuses to delete anything that is not an HDF5 file (guards
    against a typo wiping the wrong file); pass ``require_h5=False`` to force.
    A missing file is a no-op with a warning. Returns ``path``.
    """
    path = os.fspath(path)
    if not os.path.exists(path):
        warnings.warn(f"pyre(): no file at {path!r} - nothing to delete")
        return path
    if require_h5 and not _is_hdf5(path):
        raise ValueError(
            f"pyre(): {path!r} is not an HDF5 file; pass require_h5=False to override"
        )
    os.remove(path)
    return path
