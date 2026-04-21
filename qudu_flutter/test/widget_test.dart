import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziqu_reading/app.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const ZiquApp());
    expect(find.text('字趣阅读'), findsOneWidget);
  });
}
