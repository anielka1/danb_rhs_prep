import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../data/exam_content_codec.dart';
import '../domain/content_package.dart';
import '../domain/content_validation.dart';

/// Release schema 1: SHA-256 of UTF-8 canonical payload JSON (see docs).
/// This is a transport checksum, NOT a reviewer approval fingerprint.
String canonicalPayloadJson(Object? value) {
  Object? normalize(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return {for (final key in keys) key: normalize(value[key])};
    }
    if (value is List) return value.map(normalize).toList();
    if (value is num) {
      if (!value.isFinite || value.abs() > 9007199254740991) {
        throw const FormatException('Unsupported JSON number.');
      }
      return value == value.truncateToDouble() ? value.toInt() : value;
    }
    if (value == null || value is bool || value is String) return value;
    throw const FormatException('Unsupported JSON value.');
  }

  return jsonEncode(normalize(value));
}

String contentPayloadSha256(Object? payload) =>
    sha256.convert(utf8.encode(canonicalPayloadJson(payload))).toString();

/// Constructible only after transport and existing domain validation pass.
class ContentRelease {
  ContentRelease._(this.examId, this.version, this.package, this.recordJson);
  final String examId;
  final int version;
  final ContentPackage package;
  final String recordJson;

  static ContentRelease validate(
    Map<String, Object?> record, {
    required String examId,
    required DateTime now,
  }) {
    int integer(String key) {
      final value = record[key];
      if (value is! int || value <= 0) {
        throw const FormatException('Invalid release integer.');
      }
      return value;
    }

    final schema = integer('schema_version');
    final version = integer('release_version');
    final count = integer('question_count');
    if (schema != 1 || record['exam_id'] != examId) {
      throw const FormatException('Unsupported release identity or schema.');
    }
    final published = record['published_at'];
    final date = published is String ? DateTime.tryParse(published) : null;
    if (date == null ||
        !date.isUtc ||
        date.isAfter(now.toUtc()) ||
        record['retired_at'] != null) {
      throw const FormatException('Release is not active and published.');
    }
    final payload = record['payload'];
    final hash = record['content_sha256'];
    if (payload is! Map<String, Object?> ||
        hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
        contentPayloadSha256(payload) != hash) {
      throw const FormatException('Invalid release payload or checksum.');
    }
    final json = canonicalPayloadJson(payload);
    // Bound persistent package size; never silently truncate a bank.
    if (utf8.encode(json).length > 20 * 1024 * 1024) {
      throw const FormatException('Release is too large.');
    }
    final package = const ExamContentCodec().decode(json);
    if (package.exam.id != examId ||
        record['content_version'] != package.contentVersion ||
        package.questions.length != count ||
        package.questions.any((question) => !question.isApproved) ||
        !const ContentValidator().validate(package).isValid) {
      throw const FormatException('Invalid or unapproved release content.');
    }
    return ContentRelease._(examId, version, package, jsonEncode(record));
  }
}
