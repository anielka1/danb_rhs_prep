import 'dart:convert';
import 'dart:io';

import 'package:danb_rhs_prep/features/content/sync/content_release.dart';

/// Read-only publisher aid; never validates human approval or publishes content.
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
        'Usage: dart run tool/content_release_checksum.dart <payload.json>');
    exitCode = 1;
    return;
  }
  try {
    final payload = jsonDecode(File(arguments.single).readAsStringSync());
    if (payload is! Map<String, Object?>) {
      throw const FormatException('Payload must be an object.');
    }
    stdout.writeln(contentPayloadSha256(payload));
  } on Object {
    // Do not print payload contents or raw filesystem errors.
    stderr.writeln(
        'Unable to checksum payload: unreadable file or unsupported JSON.');
    exitCode = 1;
  }
}
