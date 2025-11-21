import 'package:flutter/material.dart';

class PartitionSharedExpenseScreen extends StatelessWidget {
  const PartitionSharedExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              '공용소비 화면',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '공용소비 내역을 확인하고 관리할 수 있습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

