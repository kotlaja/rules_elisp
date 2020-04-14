;;; runner.el --- run ERT tests with Bazel      -*- lexical-binding: t; -*-

;; Copyright 2020 Google LLC
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     https://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; This library runs ERT tests under Bazel.  It provides support for the
;; --test_filter flag, as described in
;; https://docs.bazel.build/versions/3.0.0/test-encyclopedia.html#initial-conditions.

;;; Code:

(require 'bytecomp)
(require 'cl-lib)
(require 'edebug)
(require 'ert)
(require 'json)
(require 'pp)
(require 'rx)

(require 'elisp/runfiles/runfiles)

(defun elisp/ert/run-batch-and-exit ()
  "Run ERT tests in batch mode.
This is similar to ‘ert-run-tests-batch-and-exit’, but uses the
TESTBRIDGE_TEST_ONLY environmental variable as test selector.
Treat all remaining command-line arguments as names of test
source files and load them."
  (or noninteractive (error "This function works only in batch mode"))
  (let* ((attempt-stack-overflow-recovery nil)
         (attempt-orderly-shutdown-on-fatal-signal nil)
         (print-escape-newlines t)
         (pp-escape-newlines t)
         (print-circle t)
         (print-gensym t)
         (print-level 8)
         (print-length 50)
         (edebug-initial-mode 'Go-nonstop)  ; ‘step’ doesn’t work in batch mode
         (runfiles-root (getenv "TEST_SRCDIR"))
         (test-filter (getenv "TESTBRIDGE_TEST_ONLY"))
         (random-seed (or (getenv "TEST_RANDOM_SEED") ""))
         (xml-output-file (getenv "XML_OUTPUT_FILE"))
         (coverage-enabled (equal (getenv "COVERAGE") "1"))
         (coverage-dir (getenv "COVERAGE_DIR"))
         (selector (if (member test-filter '(nil "")) t (read test-filter)))
         (load-suffixes
          ;; Prefer source files when coverage is requested, as only those can
          ;; be instrumented.
          (if coverage-enabled (cons ".el" load-suffixes) load-suffixes))
         (load-buffers ())
         (load-source-file-function
          (if coverage-enabled
              (lambda (fullname file noerror _nomessage)
                ;; Similar to testcover.el, we use Edebug to collect coverage
                ;; information.  The rest of this function is similar to
                ;; ‘load-with-code-conversion’, but we ignore some edge cases.
                (cond
                 ((file-readable-p fullname)
                  (let ((buffer (generate-new-buffer (format "*%s*" file)))
                        (reporter
                         (make-progress-reporter
                          (format-message "Loading and instrumenting %s..."
                                          file)))
                        (load-in-progress t)
                        (load-file-name fullname)
                        (set-auto-coding-for-load t)
                        (inhibit-file-name-operation nil)
                        (edebug-all-defs t))
                    (with-current-buffer buffer
                      (insert-file-contents fullname :visit)
                      ;; The file buffer needs to be current for Edebug
                      ;; instrumentation to work.
                      (eval-buffer buffer nil fullname nil :do-allow-print)
                      ;; Yuck!  We have to mess with internal Edebug data here.
                      ;; Byte-compile all functions to be a bit more realistic.
                      (dolist (data edebug-form-data)
                        (byte-compile (edebug--form-data-name data))))
                    (do-after-load-evaluation fullname)
                    (push buffer load-buffers)
                    (progress-reporter-done reporter)
                    t))
                 (noerror nil)
                 (t (signal 'file-error (list "Cannot open load file" file)))))
            load-source-file-function)))
    (and coverage-enabled (member coverage-dir '(nil ""))
         (error "Coverage requested but COVERAGE_DIR not set"))
    (random random-seed)
    (mapc #'load command-line-args-left)
    (let ((tests (ert-select-tests selector t))
          (unexpected 0)
          (report `((start-time . ,(format-time-string "%FT%T.%9NZ" nil t))))
          (test-reports ())
          (start-time (current-time)))
      (or tests (error "Selector %S doesn’t match any tests" selector))
      (elisp/ert/log--message "Running %d tests" (length tests))
      (dolist (test tests)
        (elisp/ert/log--message "Running test %s" (ert-test-name test))
        (let* ((name (ert-test-name test))
               (start-time (current-time))
               (result (ert-run-test test))
               (duration (time-subtract nil start-time))
               (expected (ert-test-result-expected-p test result))
               (status (ert-string-for-test-result result expected))
               (report `((name . ,(symbol-name name))
                         (elapsed . ,(float-time duration))
                         (status . ,status)
                         (expected . ,(if expected :json-true :json-false)))))
          (elisp/ert/log--message "Test %s %s and took %d ms" name status
                                  (* (float-time duration) 1000))
          (or expected (cl-incf unexpected))
          (when (ert-test-result-with-condition-p result)
            (with-temp-buffer
              (debugger-insert-backtrace
               (ert-test-result-with-condition-backtrace result) nil)
              (goto-char (point-min))
              (while (not (eobp))
                (message "    %s"
                         (buffer-substring-no-properties
                          (point) (min (line-end-position) (+ 120 (point)))))
                (forward-line))
              (goto-char (point-min))
              (insert (format-message "  Test %s backtrace:\n" name))
              (goto-char (point-max))
              (dolist (info (ert-test-result-with-condition-infos result))
                (insert "  " (car info) (cdr info) ?\n))
              (insert (format-message "  Test %s condition:\n" name))
              (insert "    ")
              (pp (ert-test-result-with-condition-condition result)
                  (current-buffer))
              (insert ?\n)
              (let ((message (buffer-substring-no-properties (point-min)
                                                             (point-max))))
                (message "%s" message)
                (push `(message . ,message) report))))
          (push report test-reports)))
      (push `(elapsed . ,(float-time (time-subtract nil start-time))) report)
      (push `(tests . ,(nreverse test-reports)) report)
      (elisp/ert/log--message "Running %d tests finished, %d results unexpected"
                              (length tests) unexpected)
      (unless (member xml-output-file '(nil ""))
        ;; Rather than trying to write a well-formed XML file in Emacs Lisp,
        ;; write the report as a JSON file and let an external binary deal with
        ;; the conversion to XML.
        (let ((process-environment
               (append (elisp/runfiles/env-vars) process-environment))
              (converter (elisp/runfiles/rlocation
                          "phst_rules_elisp/elisp/ert/write_xml_report"))
              (json-file (make-temp-file "ert-report-" nil ".json"
                                         (json-encode (nreverse report)))))
          (unwind-protect
              (with-temp-buffer
                (unless (eq 0 (call-process (file-name-unquote converter) nil t
                                            nil "--" json-file xml-output-file))
                  (message "%s" (buffer-string))
                  (error "Writing XML output file %s failed" xml-output-file)))
            (delete-file json-file))))
      (when load-buffers
        (with-temp-buffer
          (dolist (buffer load-buffers)
            (let ((file-name (elisp/ert/sanitize--string
                              (file-relative-name (buffer-file-name buffer)
                                                  runfiles-root)))
                  (functions ())
                  (functions-hit 0)
                  (lines (make-hash-table :test #'eql)))
              (with-current-buffer buffer
                (widen)
                ;; Yuck!  More messing around with Edebug internals.
                (dolist (data edebug-form-data)
                  (let* ((name (edebug--form-data-name data))
                         (frequencies (get name 'edebug-freq-count))
                         ;; We don’t really know the number of function calls,
                         ;; so assume it’s the same as the hit count of the
                         ;; first breakpoint.
                         (calls (or (cl-find 0 frequencies :test-not #'eq) 0))
                         (stuff (get name 'edebug))
                         (begin (car stuff))
                         (offsets (caddr stuff)))
                    (cl-incf functions-hit (min calls 1))
                    (cl-assert (eq (marker-buffer begin) buffer))
                    (cl-assert (eql (length frequencies) (length offsets)))
                    (cl-loop for offset across offsets
                             and freq across frequencies
                             for position = (+ begin offset)
                             for line = (line-number-at-pos position)
                             do (cl-callf max (gethash line lines 0) freq))
                    (push (list (elisp/ert/sanitize--string (symbol-name name))
                                (line-number-at-pos begin) calls)
                          functions))))
              (cl-callf nreverse functions)
              ;; The expected format is described to some extend in the
              ;; geninfo(1) man page.
              (insert (format "SF:%s\n" file-name))
              (dolist (func functions)
                (insert (format "FN:%d,%s\n" (cadr func) (car func))))
              (dolist (func functions)
                (insert (format "FNDA:%d,%s\n" (caddr func) (car func))))
              (insert (format "FNF:%d\n" (length functions)))
              (insert (format "FNH:%d\n" functions-hit))
              (let ((list ())
                    (lines-hit 0))
                (maphash (lambda (line freq) (push (cons line freq) list))
                         lines)
                (cl-callf sort list #'car-less-than-car)
                (dolist (line list)
                  (cl-incf lines-hit (min (cdr line) 1))
                  (insert (format "DA:%d,%d\n" (car line) (cdr line))))
                (insert (format "LH:%d\nLF:%d\nend_of_record\n"
                                lines-hit (hash-table-count lines)))))
            (kill-buffer buffer))
          (write-region nil nil (expand-file-name "emacs-lisp.dat" coverage-dir)
                        nil nil nil 'excl)))
      (kill-emacs (min unexpected 1)))))

(defun elisp/ert/log--message (format &rest args)
  "Like ‘(message FORMAT ARGS…)’, but also print a timestamp."
  (message "[%s] %s"
           (format-time-string "%F %T.%3N")
           (apply #'format-message format args)))

(defun elisp/ert/sanitize--string (string)
  "Return a sanitized version of STRING for the coverage file."
  ;; The coverage file is line-based, so the string shouldn’t contain any
  ;; newlines.
  (replace-regexp-in-string (rx (not (any alnum blank punct))) "?" string))

(provide 'elisp/ert/runner)
;;; runner.el ends here
