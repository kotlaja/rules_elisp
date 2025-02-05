# Copyright 2020, 2021, 2022, 2023 Google LLC
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

"""Internal-only workspace functions.

These definitions are internal and subject to change without notice."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def non_module_deps():
    """Installs dependencies that are not available as modules."""
    maybe(
        http_archive,
        name = "gnu_emacs_28.1",
        build_file = Label("//:emacs.BUILD"),
        sha256 = "28b1b3d099037a088f0a4ca251d7e7262eab5ea1677aabffa6c4426961ad75e1",
        strip_prefix = "emacs-28.1/",
        urls = [
            "https://ftpmirror.gnu.org/emacs/emacs-28.1.tar.xz",
            "https://ftp.gnu.org/gnu/emacs/emacs-28.1.tar.xz",
        ],
    )
    maybe(
        http_archive,
        name = "gnu_emacs_28.2",
        build_file = Label("//:emacs.BUILD"),
        sha256 = "ee21182233ef3232dc97b486af2d86e14042dbb65bbc535df562c3a858232488",
        strip_prefix = "emacs-28.2/",
        urls = [
            "https://ftpmirror.gnu.org/emacs/emacs-28.2.tar.xz",
            "https://ftp.gnu.org/gnu/emacs/emacs-28.2.tar.xz",
        ],
    )
    maybe(
        http_archive,
        name = "gnu_emacs_29.1",
        build_file = Label("//:emacs.BUILD"),
        sha256 = "d2f881a5cc231e2f5a03e86f4584b0438f83edd7598a09d24a21bd8d003e2e01",
        strip_prefix = "emacs-29.1/",
        urls = [
            "https://ftpmirror.gnu.org/emacs/emacs-29.1.tar.xz",
            "https://ftp.gnu.org/gnu/emacs/emacs-29.1.tar.xz",
        ],
    )
    _toolchains(name = "phst_rules_elisp_toolchains")

def non_module_dev_deps():
    """Installs development dependencies that are not available as modules."""
    maybe(
        http_archive,
        name = "junit_xsd",
        build_file = "@//:junit_xsd.BUILD",
        sha256 = "ba809d0fedfb392cc604ad38aff7db7d750b77eaf5fed977a51360fa4a6dffdf",
        strip_prefix = "JUnit-Schema-1.0.0/",
        urls = [
            "https://github.com/windyroad/JUnit-Schema/archive/refs/tags/1.0.0.tar.gz",  # 2022-04-09
        ],
    )
    maybe(
        http_archive,
        name = "hedron_compile_commands",
        sha256 = "22979f20e569219ce80031a0ee051230826390a8d9ccb587529a33003ec1e259",
        strip_prefix = "bazel-compile-commands-extractor-b33a4b05c2287372c8e932c55ff4d3a37e6761ed/",
        urls = [
            "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/b33a4b05c2287372c8e932c55ff4d3a37e6761ed.zip",  # 2023-04-16
        ],
    )

def _toolchains_impl(repository_ctx):
    windows = repository_ctx.os.name.startswith("windows")
    target = Label("//elisp:windows-toolchains.BUILD" if windows else "//elisp:unix-toolchains.BUILD")
    repository_ctx.symlink(target, "BUILD")

_toolchains = repository_rule(
    implementation = _toolchains_impl,
)
