import '../../../features/content/domain/content_package.dart';
import '../content_repository.dart';

/// An in-memory [ContentRepository] backed by packages supplied up front,
/// for unit tests and previews that should not touch Flutter assets.
class InMemoryContentRepository implements ContentRepository {
  InMemoryContentRepository(Map<String, ContentPackage> packages)
      : _packages = Map.of(packages);

  final Map<String, ContentPackage> _packages;

  @override
  Future<ContentPackage> loadContentPackage(String examId) async {
    final package = _packages[examId];
    if (package == null) {
      throw StateError('No content package registered for exam "$examId".');
    }
    return package;
  }
}
