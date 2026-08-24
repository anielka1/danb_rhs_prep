import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// `flutter test` renders every font (including Flutter's own bundled
/// Roboto — this app's actual default, since no custom `fontFamily` is
/// set anywhere) with a synthetic fallback where every glyph is exactly
/// as wide as the font size, rather than real proportional metrics. That
/// makes any width-based layout decision measured in a test (e.g. "does
/// this label fit in this column?") artificially pessimistic compared to
/// what a real device actually renders — a "Practice"-length word reads
/// as far wider than it truly is.
///
/// Loading the real Roboto files (vendored in `test/fonts/`, Apache
/// License 2.0 — see `test/fonts/LICENSE.txt` — copied from the Flutter
/// SDK's own bundled `material_fonts`, i.e. exactly what this app already
/// renders on-device) under the family name `'Roboto'` before any test
/// runs makes text measurement in tests match real-device rendering.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Roboto', 'test/fonts/Roboto-Regular.ttf');
  await _loadFont('Roboto', 'test/fonts/Roboto-Medium.ttf');
  await _loadFont('Roboto', 'test/fonts/Roboto-Bold.ttf');

  // shared_preferences' platform channel has no real implementation in
  // `flutter test` (there is no device/emulator behind it), so
  // `SharedPreferencesAsync()` throws unless a platform instance is
  // registered first. An in-memory one here is what lets
  // `SharedPreferencesBootstrapLocalStore` — and anything else that
  // constructs a bare `SharedPreferencesAsync()` without a test
  // explicitly injecting a fake — work at all in tests, including
  // `test/widget_test.dart`, which constructs `DanbRhsPrepApp()` with no
  // injection whatsoever. This one instance is shared across every test
  // in a given file (`testExecutable` runs once per file, not once per
  // test); a test that needs a guaranteed-clean store between its own
  // cases should inject `InMemoryBootstrapLocalStore` directly instead
  // of relying on this fallback.
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();

  await testMain();
}

Future<void> _loadFont(String family, String path) async {
  final Uint8List bytes = await File(path).readAsBytes();
  final ByteData data = bytes.buffer.asByteData();
  final FontLoader loader = FontLoader(family)..addFont(Future.value(data));
  await loader.load();
}
