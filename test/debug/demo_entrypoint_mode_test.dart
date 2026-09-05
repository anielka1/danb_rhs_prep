import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:danb_rhs_prep/main_demo.dart' as demo;

void main() {
  test('non-debug demo entrypoint refuses to start before runApp', () {
    expect(demo.main, throwsUnsupportedError);
    expect(demo.createDebugDemoApp, throwsUnsupportedError);
  },
      skip: kDebugMode
          ? 'CI runs this test with product/profile VM constants.'
          : false);
}
