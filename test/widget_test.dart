import 'package:flutter_test/flutter_test.dart';

import 'package:floppy_bird/main.dart';

void main() {
  testWidgets('Game screen displays without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FloppyBirdApp());
    // The app should render without throwing
    expect(tester.takeException(), isNull);
  });
}