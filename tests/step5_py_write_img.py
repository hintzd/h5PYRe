#!/usr/bin/env python3
"""Direction C, step 1: Python writes an asymmetric RGB image to h5."""
import sys

import numpy as np
from PIL import Image

import h5PYRe as h5c

tmp = sys.argv[1]
H, W = 24, 36                       # non-square so orientation errors show
arr = np.zeros((H, W, 3), np.uint8)
arr[:, :, 1] = 180                  # green background
arr[0:3, 0:3] = [255, 0, 0]         # red top-left marker
Image.fromarray(arr).save(tmp + "/c_src.png")

h5c.write_image(tmp + "/c.h5", "pic", tmp + "/c_src.png", level=9)
print(f"  Python wrote image {arr.shape} to c.h5")
