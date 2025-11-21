import 'package:flutter/material.dart';
import 'package:partition_app/shared/widgets/glassmorphism_widget.dart';

/// 홈 화면용 캘린더 위젯
/// 글래스모피즘 효과가 적용된 커스텀 캘린더
class HomeCalendarWidget extends StatefulWidget {
  const HomeCalendarWidget({super.key});

  @override
  State<HomeCalendarWidget> createState() => _HomeCalendarWidgetState();
}

class _HomeCalendarWidgetState extends State<HomeCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  
  final List<String> _monthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == _selectedDate.year &&
           date.month == _selectedDate.month &&
           date.day == _selectedDate.day;
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // 첫 번째 날의 요일 (0 = 일요일, 6 = 토요일)
    final firstWeekday = firstDay.weekday % 7;
    
    List<DateTime> days = [];
    
    // 이전 달의 마지막 날들 추가
    final prevMonthLastDay = DateTime(_currentMonth.year, _currentMonth.month, 0);
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month - 1, prevMonthLastDay.day - i));
    }
    
    // 현재 달의 날들 추가
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    
    // 다음 달의 첫 날들 추가 (캘린더를 6주로 채우기 위해)
    final remainingDays = 42 - days.length; // 6주 * 7일 = 42일
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month + 1, i));
    }
    
    return days;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _selectMonth(int monthIndex) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, monthIndex + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final currentMonthIndex = _currentMonth.month - 1;
    
    // 현재 월 주변의 4개 월 표시
    int startMonth = (currentMonthIndex ~/ 4) * 4;
    if (startMonth + 4 > 12) {
      startMonth = 12 - 4;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        return GlassmorphismWidget(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          backgroundOpacity: 0.0,
          showStroke: true,
          borderColor: const Color.fromRGBO(255, 255, 255, 0.25),
          strokeGradient: const RadialGradient(
            center: Alignment(0.2535, -0.6739),
            radius: 2.6345,
            colors: [
              Color.fromRGBO(255, 255, 255, 0.12),
              Color.fromRGBO(255, 255, 255, 0.0),
            ],
            stops: [0.0, 1.0],
          ),
          child: hasBoundedHeight
              ? SizedBox(
                  height: constraints.maxHeight,
                  child: _buildCalendarContent(
                    days: days,
                    startMonth: startMonth,
                    currentMonthIndex: currentMonthIndex,
                    useExpandedGrid: true,
                  ),
                )
              : _buildCalendarContent(
                  days: days,
                  startMonth: startMonth,
                  currentMonthIndex: currentMonthIndex,
                  useExpandedGrid: false,
                ),
        );
      },
    );
  }

  Widget _buildCalendarContent({
    required List<DateTime> days,
    required int startMonth,
    required int currentMonthIndex,
    required bool useExpandedGrid,
  }) {
    final gridView = GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: !useExpandedGrid,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: useExpandedGrid ? 1.3 : 1.0,
      ),
      itemCount: 42, // 6주
      itemBuilder: (context, index) {
        final date = days[index];
        final isCurrentMonth = date.month == _currentMonth.month;
        final isToday = _isToday(date);
        final isSelected = _isSelected(date);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
              if (date.month != _currentMonth.month) {
                _currentMonth = DateTime(date.year, date.month);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
              border: isToday
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isCurrentMonth
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    fontSize: 14,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isToday)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
              ],
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  final monthIndex = startMonth + index;
                  if (monthIndex >= 12) return const SizedBox.shrink();
                  final isSelected = monthIndex == currentMonthIndex;
                  return GestureDetector(
                    onTap: () => _selectMonth(monthIndex),
                    child: Column(
                      children: [
                        Text(
                          _monthNames[monthIndex],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: 30,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                  onPressed: _previousMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  onPressed: _nextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => SizedBox(
                    width: 40,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        if (useExpandedGrid)
          Expanded(child: gridView)
        else
          gridView,
      ],
    );
  }
}

