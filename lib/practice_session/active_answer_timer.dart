/// Foreground answering only. Reading explanations is estimated separately by
/// the planner, never added to persisted historical answer durations.
class ActiveAnswerTimer {
  ActiveAnswerTimer({required this.now});
  final DateTime Function() now;
  static const idleLimit = Duration(minutes: 2);
  DateTime? _since;
  Duration _accumulated = Duration.zero;
  Duration get _segment {
    final start = _since;
    if (start == null) return Duration.zero;
    final delta = now().difference(start);
    if (delta.isNegative) return Duration.zero;
    return delta > idleLimit ? idleLimit : delta;
  }

  Duration get elapsed => _accumulated + _segment;
  void start() => _since ??= now();
  void stop() {
    _accumulated = elapsed;
    _since = null;
  }

  void reset() {
    _accumulated = Duration.zero;
    if (_since != null) _since = now();
  }

  void interaction() {
    if (_since == null) return;
    _accumulated = elapsed;
    _since = now();
  }
}
