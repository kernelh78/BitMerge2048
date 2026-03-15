import 'package:flutter_test/flutter_test.dart';
import 'package:bitmerge2048/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const BitMergeApp());
    expect(find.byType(BitMergeApp), findsOneWidget);
  });
}
