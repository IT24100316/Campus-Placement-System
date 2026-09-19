import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlacementApp());
    expect(find.byType(PlacementApp), findsOneWidget);
  });
}
