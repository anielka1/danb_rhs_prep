/// CLI entrypoint for the DANB RHS content workbench validator.
///
/// Run from the repository root:
///   dart run tool/validate_candidate_questions.dart [--report] [--require-ready]
///
/// This file is a thin wrapper only — all behavior lives in
/// `runValidatorCli` (candidate_question_validator.dart), which is
/// unit-tested directly via injectable output/error sinks rather than only
/// through subprocess assertions. See that function's doc comment for the
/// exit-code contract.
///
/// This tool never writes to any file, never changes a candidate's status,
/// and never creates or edits a reviewer decision — it only reads and
/// reports. See docs/DANB_RHS_CONTENT_APPROVAL_WORKFLOW.md.
library;

import 'dart:io';

import 'candidate_question_validator.dart';

void main(List<String> arguments) {
  exitCode = runValidatorCli(arguments, out: stdout, err: stderr);
}
