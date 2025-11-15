import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partition_app/main.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PartitionApp());

    // Verify that login screen is shown
    expect(find.text('Partition App'), findsOneWidget);
  });
}

