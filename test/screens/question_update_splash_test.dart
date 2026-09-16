import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:danb_rhs_prep/bootstrap/app_bootstrap_service.dart';
import 'package:danb_rhs_prep/domain/repositories/content_repository.dart';
import 'package:danb_rhs_prep/domain/repositories/fakes/in_memory_bootstrap_local_store.dart';
import 'package:danb_rhs_prep/features/content/domain/content_package.dart';
import 'package:danb_rhs_prep/screens/splash_screen.dart';
import 'package:danb_rhs_prep/theme/app_theme.dart';

class PendingContent implements ContentRepository {
  @override
  Future<ContentPackage> loadContentPackage(String examId) =>
      Completer<ContentPackage>().future;
}

void main() {
  testWidgets('splash announces only an actual question update',
      (tester) async {
    final updating = ValueNotifier(false);
    final store = InMemoryBootstrapLocalStore();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: SplashScreen(
            localStore: store,
            updatingQuestions: updating,
            bootstrapService: AppBootstrapService(
                localStore: store, contentRepository: PendingContent()))));
    await tester.pump();
    expect(find.text('Updating questions…'), findsNothing);
    updating.value = true;
    await tester.pump();
    expect(find.text('Updating questions…'), findsOneWidget);
    updating.value = false;
    await tester.pump();
    expect(find.text('Updating questions…'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    updating.dispose();
  });
}
