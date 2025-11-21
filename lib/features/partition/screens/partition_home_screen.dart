import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:partition_app/shared/widgets/home_calendar_widget.dart';

class PartitionHomeScreen extends StatelessWidget {
  const PartitionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 0), // 상단 여백
            SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 26),
            // 캘린더 위젯
            SizedBox(
              width: double.infinity,
              height: 382,
              child: const HomeCalendarWidget(),
            ),
            const SizedBox(height: 20), // 하단 여백 추가
          ],
        ),
      ),
    );
  }
}

