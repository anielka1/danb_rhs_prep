import 'dart:math';

/// Generates stable, unique v4 (random) UUIDs for append-only records
/// (`AnswerAttempt`, `MockAttempt`, `ReadinessSnapshot`, ...) — "stable"
/// meaning each record gets exactly one identity for its lifetime, never
/// derived from mutable/repeatable inputs (e.g. `sessionId-questionId`,
/// which collides the moment the same question is answered twice in the
/// same session — see `PracticeSessionController`'s history for why that
/// pattern was replaced with this).
///
/// A hand-rolled ~20-line generator over `dart:math`'s `Random.secure()`
/// (a cryptographically-secure source, so collisions are astronomically
/// unlikely — RFC 4122 v4's whole design) rather than adding the `uuid`
/// package: this is the entire API surface this app needs, and every
/// dependency this app has added has been justified against exactly this
/// bar (see `pubspec.yaml`'s comment on `drift`/`sqlite3`).
class IdGenerator {
  const IdGenerator();

  static final Random _random = Random.secure();

  /// A new RFC 4122 version 4 (random) UUID, e.g.
  /// `f47ac10b-58cc-4372-a567-0e02b2c3d479`.
  String generate() {
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Version 4: the 4 most-significant bits of byte 6 are 0100.
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    // Variant 1 (RFC 4122): the 2 most-significant bits of byte 8 are 10.
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
