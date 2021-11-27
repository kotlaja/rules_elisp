# Copyright 2020, 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@bazel_gazelle//:def.bzl", "gazelle")
load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    extra_args = [
        "--allow-unsafe",  # for setuptools
    ],
    requirements_in = "requirements.in",
    requirements_txt = ":requirements_txt",
    tags = [
        # Don’t try to run Pylint or Pytype.  This target doesn’t contain any of
        # our source files.
        "nolint",
        "notype",
    ],
)

alias(
    name = "requirements_txt",
    actual = select({
        "//constraints:linux": "linux-requirements.txt",
        "//constraints:macos": "macos-requirements.txt",
        "//constraints:windows": "windows-requirements.txt",
    }),
)

py_binary(
    name = "run_pylint",
    srcs = ["run_pylint.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    visibility = ["//:__subpackages__"],
    deps = [requirement("pylint")],
)

py_binary(
    name = "run_pytype",
    srcs = ["run_pytype.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # Pytype doesn’t work on Windows, so don’t build it when running
    # “bazel build //...”.
    target_compatible_with = select({
        "@platforms//os:linux": [],
        "@platforms//os:macos": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    visibility = ["//:__subpackages__"],
    deps = [
        requirement("pytype"),
        ":run_pylint",
    ],
)

exports_files(
    [".pylintrc"],
    visibility = ["//:__subpackages__"],
)

# gazelle:prefix github.com/phst/rules_elisp
gazelle(name = "gazelle")
