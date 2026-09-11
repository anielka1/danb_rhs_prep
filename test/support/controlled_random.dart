import 'dart:math';

/// Fisher-Yates identity / left rotation, with no probability assertions.
class ControlledRandom implements Random {
  ControlledRandom({this.rotate = false, this.forbid = false});
  final bool rotate;
  final bool forbid;
  int calls = 0;
  @override
  int nextInt(int max) {
    if (forbid) throw StateError('Randomness must not be consumed on resume');
    calls++;
    return rotate ? 0 : max - 1;
  }

  @override
  bool nextBool() => throw UnsupportedError('nextBool');
  @override
  double nextDouble() => throw UnsupportedError('nextDouble');
}
