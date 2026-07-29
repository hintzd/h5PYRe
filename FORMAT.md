# h5PYRe file format (v0.1)

The single source of truth both the R and Python packages implement. An
`h5PYRe` file is a plain HDF5 file with this layout:

```
/                      (optional root attribute `title`: string)
├─ cohorts/
│  ├─ <cohort_name>/          one group per cohort
│  │  ├─ <column>             one 1-D dataset per column
│  │  └─ ...                  all columns in a cohort share the same length
│  └─ ...                     cohorts may have DIFFERENT schemas
├─ params/
│  ├─ <param_name>            one 1-D dataset per parameter
│  └─ ...
└─ images/
   ├─ <image_name>            one N-D dataset per image (gzip-compressed)
   └─ ...
```

## Rules

- **Cohorts** live under `/cohorts/<name>/`. Each cohort is a group whose
  datasets are its columns. Cohorts are independent — they need not share
  column names or lengths. Read back as a **named list of data frames** (R) /
  **dict of DataFrames** (Python), never concatenated.
- **Params** live under `/params/`. Each is a 1-D dataset. Use params for
  small config/derived values shared across languages (thresholds, bin edges,
  palettes, name mappings).
- **Scalars** are stored as length-1 datasets. R reads them back as a length-1
  vector (idiomatic — everything is a vector); Python unwraps length-1 to a
  Python scalar. This asymmetry is by language convention, not a format
  difference.
- **Strings** are stored as variable-length UTF-8 (`H5T_STRING` /
  `h5py.string_dtype`). Both languages read them back as native text.
- **Overwrite semantics**: writing to an existing dataset path deletes then
  recreates it (`h5_put` / `put`).
- **Images** live under `/images/`. Each is a gzip-compressed, chunked N-D
  dataset of `uint8` values 0-255, in **row-major** orientation: `(H, W)` for
  grayscale or `(H, W, C)` for color (`C` = 3 RGB / 4 RGBA). Attributes record
  `format`, `axis_order` (`"HWC"`/`"HW"`), and optionally `mode`/`source`.
  Because R is column-major, the R package reverse-permutes axes on write and
  read so both languages see the same `(H, W[, C])` orientation on disk.
- **Order preservation**: HDF5 iterates group members by name, not by
  insertion order. To keep the round-trip lossless, `write_cohorts` records a
  `cohort_order` attribute on `/cohorts` and a `column_order` attribute on each
  cohort group; readers restore that order and append any unlisted members at
  the end. Files lacking these attributes read back in name-sorted order.
  Params are not order-tracked (they are an unordered name→value map).

## API parity

| Concept            | R (`h5PYRe`)      | Python (`h5PYRe`)   |
|--------------------|---------------------|-----------------------|
| overwrite-safe set | `h5_put(node,n,v)`  | `put(node,n,v)`       |
| write cohorts      | `write_cohorts()`   | `write_cohorts()`     |
| read cohorts       | `read_cohorts()`    | `read_cohorts()`      |
| write params       | `write_params()`    | `write_params()`      |
| read params        | `read_params()`     | `read_params()`       |
| write image        | `write_image()`     | `write_image()`       |
| read image         | `read_image()`      | `read_image()`        |
| export image       | `export_image()`    | `export_image()`      |
| list images        | `list_images()`     | `list_images()`       |
| export tables→Parquet | `export_parquet()` | `export_parquet()`   |
| delete the file    | `pyre()`            | `pyre()`              |
| directory view     | `print(h5)` / `h5_tree()` | `tree(path)`    |

**Concurrency:** an h5PYRe file is a *serialized* interchange — one side
writes and closes, then the other reads. HDF5 is not safe for simultaneous
writers, so treat the file as a cross-process scratchpad/handoff, **not** as
concurrent shared memory. `pyre()` is the cleanup step for that workflow.
