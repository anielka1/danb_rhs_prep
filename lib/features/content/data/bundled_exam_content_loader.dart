import 'package:flutter/services.dart';

import '../domain/content_package.dart';
import 'exam_content_codec.dart';

abstract interface class ExamContentLoader {
  Future<ContentPackage> load(String examId);
}

class BundledExamContentLoader implements ExamContentLoader {
  BundledExamContentLoader({
    AssetBundle? bundle,
    this.codec = const ExamContentCodec(),
  }) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;
  final ExamContentCodec codec;

  @override
  Future<ContentPackage> load(String examId) async {
    final source = await bundle.loadString('assets/content/$examId/content.json');
    return codec.decode(source);
  }
}
