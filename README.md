# BLE Provisioning

A template repository for creating a Toit package.

## Toit package
Use `toit.pkg describe` or `toit pkg describe` (depending on which Toit
variant you use) to see how https://pkg.toit.io will extract package
information from your repo when you publish the package.

## Structure
Code that should be used by other developers must live in the `src` folder.

Examples should live in `examples`. For bigger examples, or examples that
use more packages, create a subfolder.

Tests live in the `tests` folder.

## Copyright
Don't forget to update the copyright holder in the license files.
There are (up to) three license files:
- `LICENSE`: usually MIT
- `examples/EXAMPLES_LICENSE`: usually BSD0
- `tests/TESTS_LICENSE`: usually BSD0

We recommend to use the following Copyright header in `src` files (with your
copyright):

```
// Copyright (C) 2022 Jane/John Doe
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.
```

Similarly, you can use the following header for tests and examples:
```
// Copyright (C) 2022 Jane/John Doe
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/TESTS_LICENSE file.
```
and
```
// Copyright (C) 2022 Jane/John Doe
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the examples/EXAMPLES_LICENSE file.
```

## Publish
Make sure to run `toit.pkg describe` to verify that the data is correct.

This repository comes with a `.github/workflows/publish.xml` file which automatically
publishes the Toit package for every release. You can just draft a new release on
Github.
It is important that the release has a semver tag (like `v1.2.3`).

Alternatively, a package can be published by hand:
0. Ensure that everything looks good (`toit.pkg describe`).
1. Add a semver tag (like `v1.0.0`).
2. Go to https://pkg.toit.io/publish and submit your package.
