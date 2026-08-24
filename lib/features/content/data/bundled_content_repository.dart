import '../../../domain/repositories/content_repository.dart';
import '../domain/content_package.dart';
import 'bundled_exam_content_loader.dart';

/// The production [ContentRepository]: delegates to [BundledExamContentLoader],
/// which is the only thing in this dependency chain that touches
/// `package:flutter/services.dart`/`rootBundle`. Callers that must stay
/// plain-Dart (notably `AppBootstrapService`) depend on [ContentRepository]
/// instead of this class or [BundledExamContentLoader] directly, so Flutter's
/// asset APIs stay confined to this data/infrastructure layer.
class BundledContentRepository implements ContentRepository {
  BundledContentRepository({ExamContentLoader? loader})
      : _loader = loader ?? BundledExamContentLoader();

  final ExamContentLoader _loader;

  @override
  Future<ContentPackage> loadContentPackage(String examId) =>
      _loader.load(examId);
}
