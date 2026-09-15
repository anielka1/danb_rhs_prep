import 'package:url_launcher/url_launcher.dart';

abstract interface class ExternalLinkLauncher {
  Future<bool> open(Uri uri);
}

typedef LaunchPage = Future<bool> Function(Uri uri, {required LaunchMode mode});

class UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher {
  const UrlLauncherExternalLinkLauncher({LaunchPage? launch})
      : _launch = launch ?? launchUrl;

  final LaunchPage _launch;

  @override
  Future<bool> open(Uri uri) async {
    for (final mode in [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ]) {
      try {
        if (await _launch(uri, mode: mode)) return true;
      } catch (_) {
        // A platform may reject the in-app mode. Still attempt the browser.
      }
    }
    return false;
  }
}
