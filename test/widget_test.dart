import 'package:flutter_test/flutter_test.dart';

import 'package:transitables/main.dart';

void main() {
  testWidgets('shows the first empty screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TransitablesApp());

    expect(find.text('Screen 1'), findsOneWidget);
    expect(find.text('No tables on this screen yet'), findsOneWidget);
  });
}
