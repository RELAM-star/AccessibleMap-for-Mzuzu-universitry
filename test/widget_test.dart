import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:accessmap_mzuni/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AccessMapApp());
    expect(find.text('AccessMap:Smart Map for the blind'), findsOneWidget);
  });
}
