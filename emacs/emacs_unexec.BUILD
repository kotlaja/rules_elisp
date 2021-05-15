# Copyright 2021 Google LLC
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

load("@phst_rules_elisp//emacs:defs.bzl", "emacs_binary")

emacs_binary(
    name = "emacs",
    srcs = glob(["**"]),
    dump_mode = "unexec",
    readme = "README",
    target_compatible_with = select({
        "@phst_rules_elisp//emacs:always_supported": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    visibility = ["@phst_rules_elisp//emacs:__pkg__"],
)

# Local Variables:
# mode: bazel-build
# End:
