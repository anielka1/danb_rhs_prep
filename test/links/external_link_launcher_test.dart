import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:danb_rhs_prep/links/external_link_launcher.dart';

void main() {
  final uri = Uri.parse('https://prepnovo.org/privacy-policy/');
  for (final first in ['success', 'false', 'throw']) {
    test('in-app $first and external fallback', () async {
      final modes = <LaunchMode>[];
      final launcher =
          UrlLauncherExternalLinkLauncher(launch: (url, {required mode}) async {
        expect(url, uri);
        modes.add(mode);
        if (mode == LaunchMode.externalApplication) return true;
        if (first == 'throw') throw StateError('unsupported');
        return first == 'success';
      });
      expect(await launcher.open(uri), true);
      expect(modes, [
        LaunchMode.inAppBrowserView,
        if (first != 'success') LaunchMode.externalApplication
      ]);
    });
  }
  for (final throws in [false, true]) {
    test('both modes fail (throws: $throws)', () async {
      var calls = 0;
      final launcher =
          UrlLauncherExternalLinkLauncher(launch: (_, {required mode}) async {
        calls++;
        if (throws) throw StateError('unavailable');
        return false;
      });
      expect(await launcher.open(uri), false);
      expect(calls, 2);
    });
  }
}
