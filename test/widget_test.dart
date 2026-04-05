import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partition_app/main.dart';

void main() {
  testWidgets('앱이 MaterialApp으로 빌드된다', (WidgetTester tester) async {
    await tester.pumpWidget(const PartitionApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
