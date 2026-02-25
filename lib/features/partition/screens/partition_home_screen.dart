import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:partition_app/shared/widgets/home_calendar_widget.dart';
import 'package:partition_app/shared/widgets/primary_button.dart';
import 'package:partition_app/shared/widgets/chore_assignment_modal.dart';
import 'package:partition_app/shared/widgets/schedule_registration_modal.dart';

class PartitionHomeScreen extends StatefulWidget {
  const PartitionHomeScreen({super.key});

  @override
  State<PartitionHomeScreen> createState() => _PartitionHomeScreenState();
}

class _PartitionHomeScreenState extends State<PartitionHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<HomeCalendarWidgetState> _calendarKey = GlobalKey<HomeCalendarWidgetState>();

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _refreshCalendar() {
    _calendarKey.currentState?.refreshCalendar();
  }

  void _showScheduleRegistrationModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ScheduleRegistrationModal(
        selectedDate: _selectedDate,
        onSuccess: _refreshCalendar, // 등록 성공 시 캘린더 갱신
      ),
    );
  }

  void _showChoreAssignmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ChoreAssignmentModal(
        onSuccess: _refreshCalendar, // 배정 성공 시 캘린더 갱신
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth - 32; // 좌우 패딩 16 * 2 = 32
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: HomeCalendarWidget(
                key: _calendarKey,
                onDateSelected: _onDateSelected,
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: '일정 등록하기',
              width: buttonWidth,
              onPressed: () => _showScheduleRegistrationModal(context),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: '집안일 자동 배정',
              width: buttonWidth,
              onPressed: () => _showChoreAssignmentModal(context),
            ),
            const SizedBox(height: 20), // 하단 여백 추가
          ],
        ),
      ),
    );
  }
}

