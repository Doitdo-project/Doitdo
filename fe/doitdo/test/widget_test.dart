import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/app.dart';

void main() {
  testWidgets('앱이 정상적으로 시동된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoitdoApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
