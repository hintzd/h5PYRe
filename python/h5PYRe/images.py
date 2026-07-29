"""Read/write images as compressed multidimensional datasets under /images.

Canonical on-disk layout is row-major ``(H, W)`` (grayscale) or ``(H, W, C)``
(color) with ``uint8`` values 0-255 and gzip compression. This matches NumPy /
Pillow directly; the R sibling reverse-permutes so both languages see the same
orientation. See ../FORMAT.md.
"""

import os

import h5py
import numpy as np
from PIL import Image


def write_image(path, name, image, level=6):
    """Store ``image`` as a compressed dataset ``/images/<name>``.

    ``image`` may be a path to a PNG (or any Pillow-readable file) or an array.
    ``level`` is the gzip level (0-9). Existing images of the same name are
    replaced.
    """
    mode, source = "", ""
    if isinstance(image, (str, os.PathLike)):
        with Image.open(image) as im:
            mode = im.mode
            arr = np.asarray(im)
        source = os.path.basename(os.fspath(image))
    else:
        arr = np.asarray(image)
    if arr.dtype != np.uint8:
        arr = arr.astype(np.uint8)

    m = "r+" if os.path.exists(path) else "w"
    with h5py.File(path, m) as f:
        g = f.require_group("images")
        if name in g:
            del g[name]
        d = g.create_dataset(name, data=arr, compression="gzip",
                             compression_opts=level, chunks=True)
        d.attrs["format"] = "png"
        d.attrs["axis_order"] = "HWC" if arr.ndim == 3 else "HW"
        if mode:
            d.attrs["mode"] = mode
        if source:
            d.attrs["source"] = source
    return path


def read_image(path, name):
    """Return the stored image as a ``uint8`` numpy array (H, W[, C])."""
    with h5py.File(path, "r") as f:
        return np.asarray(f["images/" + name][()], dtype=np.uint8)


def export_image(path, out_dir, images=None):
    """Export stored images to ``out_dir`` as ``<name>.png``.

    By default exports every image under ``/images``; pass ``images`` (a list
    of names) to export only a subset. The directory is created if needed.
    Returns a dict mapping image name -> written file path.
    """
    names = list_images(path)
    if images is not None:
        missing = [n for n in images if n not in names]
        if missing:
            raise KeyError(f"export_image(): no such image(s): {missing}")
        names = list(images)
    os.makedirs(out_dir, exist_ok=True)
    written = {}
    for name in names:
        fp = os.path.join(out_dir, f"{name}.png")
        Image.fromarray(read_image(path, name)).save(fp)
        written[name] = fp
    return written


def list_images(path):
    """List image names stored under ``/images`` (empty list if none)."""
    with h5py.File(path, "r") as f:
        return list(f["images"].keys()) if "images" in f else []
