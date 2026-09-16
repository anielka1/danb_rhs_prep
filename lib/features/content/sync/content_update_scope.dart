import 'package:flutter/widgets.dart';
import 'content_update_controller.dart';

class ContentUpdateScope extends InheritedNotifier<ContentUpdateController> {
  const ContentUpdateScope(
      {super.key,
      required ContentUpdateController controller,
      required super.child})
      : super(notifier: controller);

  static ContentUpdateController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ContentUpdateScope>()
      ?.notifier;
}

/// Route changes only schedule a safe-point check; they never swap content.
class ContentNavigationObserver extends NavigatorObserver {
  ContentNavigationObserver(this.onChanged);
  final VoidCallback onChanged;
  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    onChanged();
  }
}
