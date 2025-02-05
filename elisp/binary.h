// Copyright 2020, 2021, 2022, 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef PHST_RULES_ELISP_ELISP_BINARY_H
#define PHST_RULES_ELISP_ELISP_BINARY_H

#if !defined __cplusplus || __cplusplus < 201402L
#error this file requires at least C++14
#endif

#include <vector>

#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpedantic"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wsign-conversion"
#pragma GCC diagnostic ignored "-Woverflow"
#endif
#ifdef _MSC_VER
#pragma warning(push, 3)
#endif
#include "absl/base/attributes.h"
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif
#ifdef _MSC_VER
#pragma warning(pop)
#endif

#include "elisp/platform.h"  // IWYU pragma: export

namespace phst_rules_elisp {

ABSL_MUST_USE_RESULT int RunBinary(const NativeString& argv0,
                                   const std::vector<NativeString>& args);

}  // namespace phst_rules_elisp

#endif
