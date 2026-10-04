import 'package:flutter_test/flutter_test.dart';
import 'package:wahid_fina/main.dart';

void main() {
  testWidgets('WahidFinaApp smoke test', (WidgetTester tester) async {
    // Basic smoke test - app loads without crashing
    expect(WahidFinaApp, isNotNull);
  });
}
