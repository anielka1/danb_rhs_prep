import '../../features/content/domain/content_package.dart';

/// Provides the active, validated exam content package for study.
///
/// Implementations may load content from a bundled asset today and from a
/// managed content-distribution channel later; this interface describes
/// only what the application needs, not where the content comes from.
abstract interface class ContentRepository {
  Future<ContentPackage> loadContentPackage(String examId);
}
