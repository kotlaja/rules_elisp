# Copyright 2020 Google LLC
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

"""Contains workspace functions to use Emacs Lisp rules."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_elisp_dependencies():
    """Installs necessary dependencies for Emacs Lisp rules.

    Call this function in your `WORKSPACE` file.
    """
    http_archive(
        name = "gnu_emacs_stable",
        build_file = "@phst_rules_elisp//emacs:emacs.BUILD",
        sha256 = "4d90e6751ad8967822c6e092db07466b9d383ef1653feb2f95c93e7de66d3485",
        strip_prefix = "emacs-26.3/",
        urls = ["https://ftp.gnu.org/gnu/emacs/emacs-26.3.tar.xz"],
    )
    http_archive(
        name = "bazel_skylib",
        sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        ],
    )
    http_archive(
        name = "com_google_absl",
        urls = ["https://github.com/abseil/abseil-cpp/archive/0e9921b75a0fdd639a504ec8443fc1fe801becd7.zip"],
        sha256 = "8061df0ebbd3f599bcd3f5e57fb8003564d50a9b6a81a7f968fb0196b952365d",
        strip_prefix = "abseil-cpp-0e9921b75a0fdd639a504ec8443fc1fe801becd7",
    )
    http_archive(
        name = "nlohmann_json",
        urls = ["https://github.com/nlohmann/json/releases/download/v3.8.0/include.zip"],
        sha256 = "8590fbcc2346a3eefc341935765dd57598022ada1081b425678f0da9a939a3c0",
        strip_prefix = "single_include",
        build_file = "@phst_rules_elisp//:json.BUILD",
    )

def rules_elisp_toolchains():
    """Registers the default toolchains for Emacs Lisp."""
    native.register_toolchains("@phst_rules_elisp//elisp:all")
