import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:partition_app/shared/widgets/frosted_panel.dart';
import 'package:partition_app/shared/widgets/primary_button.dart';
import 'package:partition_app/features/partition/widgets/shared_expense_filter_chip.dart';

class PartitionSharedExpenseScreen extends StatefulWidget {
  const PartitionSharedExpenseScreen({super.key});

  @override
  State<PartitionSharedExpenseScreen> createState() =>
      _PartitionSharedExpenseScreenState();
}

class _PartitionSharedExpenseScreenState
    extends State<PartitionSharedExpenseScreen> {
  // Constants
  static const double _headerHeight = 125.0;
  static const double _headerTextOffset = 25.0;
  static const double _headerTextWidth = 177.0;
  static const double _headerTextHeight = 37.0;
  static const double _contentPaddingTop = 28.0;
  static const double _contentPaddingHorizontal = 16.0;
  static const double _contentPaddingBottom = 16.0;
  static const double _mainCardHeightRatio = 0.45;
  static const double _spacingSmall = 10.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 20.0;
  static const double _borderRadiusSmall = 24.0;
  static const double _borderRadiusMedium = 28.0;
  static const double _borderRadiusLarge = 32.0;
  static const double _borderOpacity = 0.25;
  static const double _blurSigma = 10.0;

  int _filterIndex = 0; // 0: 물품, 1: 공과금
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 4);
    _endDate = DateTime(now.year, now.month, 4);
  }

  Future<void> _selectDate(bool isStartDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 365)); // 1년 후까지

    final selectedDate = isStartDate ? _startDate : _endDate;
    final initialDate = selectedDate.isBefore(today) ? today : selectedDate;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _GlassmorphicDatePicker(
        initialDate: initialDate,
        firstDate: today,
        lastDate: maxDate,
        isStartDate: isStartDate,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        final selectedDate = DateTime(picked.year, picked.month, picked.day);
        if (isStartDate) {
          _startDate = selectedDate;
          // 시작일이 종료일보다 늦으면 종료일도 같이 변경
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = selectedDate;
          // 종료일이 시작일보다 이전이면 시작일도 같이 변경
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}.';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              _contentPaddingHorizontal,
              _contentPaddingTop,
              _contentPaddingHorizontal,
              _contentPaddingBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterChips(),
                const SizedBox(height: _spacingSmall),
                _buildMainCard(screenHeight),
                const SizedBox(height: _spacingSmall),
                ..._buildActionButtons(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: _headerHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(_borderOpacity),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // 하단바(0.4)보다 투명하지만 현재보다 불투명
            ),
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, _headerTextOffset),
                child: const SizedBox(
                  width: _headerTextWidth,
                  height: _headerTextHeight,
                  child: Center(
                    child: Text(
                      '공용소비',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Pretendard Variable',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 0.7, // line-height: 14px / 20px = 0.7
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SharedExpenseFilterChip(
          label: '물품',
          selected: _filterIndex == 0,
          onTap: () => setState(() => _filterIndex = 0),
        ),
        const SizedBox(width: 12),
        SharedExpenseFilterChip(
          label: '공과금',
          selected: _filterIndex == 1,
          onTap: () => setState(() => _filterIndex = 1),
          horizontalPadding: 20, // 공과금 패딩 줄임 (28 → 20)
        ),
      ],
    );
  }

  Widget _buildMainCard(double screenHeight) {
    final isUtility = _filterIndex == 1;
    
    return SizedBox(
      height: screenHeight * _mainCardHeightRatio,
      child: FrostedPanel(
        borderRadius: BorderRadius.circular(_borderRadiusLarge),
        backgroundOpacity: 0.0,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                isUtility ? '공과금 관리' : '공용 소비 물품 관리',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: _spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateChip('시작일', _formatDate(_startDate), true),
                const SizedBox(width: 12),
                _buildDateChip('종료일', _formatDate(_endDate), false),
              ],
            ),
            if (isUtility) ...[
              const SizedBox(height: _spacingLarge),
              PrimaryButton(
                label: '이번 달 공과금 보기',
                onPressed: () {
                  // TODO: 이번 달 공과금 보기 기능 구현
                },
              ),
            ],
                  const SizedBox(height: _spacingLarge),
                  Expanded(
                    child: FrostedPanel(
                      borderRadius: BorderRadius.circular(20),
                      backgroundOpacity: 0.0,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTableHeader(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: _SharedExpenseTableBody(
                          filterIndex: _filterIndex,
                          onTextTap: _showFullTextPopup,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPageControl(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildActionButtons() {
    final isUtility = _filterIndex == 1;
    
    if (isUtility) {
      return [
        PrimaryButton(
          label: '공과금 추가하기',
          onPressed: () {
            // TODO: 공과금 추가 기능 구현
          },
        ),
        const SizedBox(height: _spacingSmall),
        PrimaryButton(
          label: '공과금 정산하기',
          onPressed: () {
            // TODO: 공과금 정산 기능 구현
          },
        ),
      ];
    } else {
      return [
        PrimaryButton(
          label: '공용 소비 물품 추가하기',
          onPressed: () {
            // TODO: 공용 소비 물품 추가 기능 구현
          },
        ),
        const SizedBox(height: _spacingSmall),
        PrimaryButton(
          label: '파티션 AI 영수증 인식',
          onPressed: () {
            // TODO: AI 영수증 인식 기능 구현
          },
        ),
        const SizedBox(height: _spacingSmall),
        PrimaryButton(
          label: '공용 소비 정산하기',
          onPressed: () {
            // TODO: 공용 소비 정산 기능 구현
          },
        ),
      ];
    }
  }

  Widget _buildDateChip(String label, String date, bool isStartDate) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectDate(isStartDate),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(_borderRadiusSmall),
          backgroundOpacity: 0.0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    
    final isUtility = _filterIndex == 1;

    if (isUtility) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text('내용', style: headerStyle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text('날짜', style: headerStyle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text('금액', style: headerStyle),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text('내용', style: headerStyle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text('날짜', style: headerStyle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text('금액', style: headerStyle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Center(
                  child: Text(
                    '수량',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPageControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleArrow(Icons.chevron_left),
        const SizedBox(width: 16),
        _buildCircleArrow(Icons.chevron_right),
      ],
    );
  }

  Widget _buildCircleArrow(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.14),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  void _showFullTextPopup(BuildContext context, RenderBox renderBox, String fullText) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _AnimatedTextOverlay(
          renderBox: renderBox,
          fullText: fullText,
          onAnimationComplete: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }
}

class _AnimatedTextOverlay extends StatefulWidget {
  final RenderBox renderBox;
  final String fullText;
  final VoidCallback onAnimationComplete;

  const _AnimatedTextOverlay({
    required this.renderBox,
    required this.fullText,
    required this.onAnimationComplete,
  });

  @override
  State<_AnimatedTextOverlay> createState() => _AnimatedTextOverlayState();
}

class _AnimatedTextOverlayState extends State<_AnimatedTextOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750), // 전체 애니메이션 시간 (0.5초 표시 + 0.25초 페이드)
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.67, 1.0, curve: Curves.easeOut), // 마지막 0.25초 동안 페이드 아웃
      ),
    );

    // 0.5초 후 페이드 아웃 시작
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.renderBox.localToGlobal(Offset.zero);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: FrostedPanel(
            borderRadius: BorderRadius.circular(12),
            backgroundOpacity: 0.4,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              widget.fullText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedExpenseTableBody extends StatelessWidget {
  final int filterIndex;
  final Function(BuildContext, RenderBox, String) onTextTap;
  
  const _SharedExpenseTableBody({
    required this.filterIndex,
    required this.onTextTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUtility = filterIndex == 1;
    
    final items = isUtility
        ? [
            _SharedExpenseItem('월세', '6일 뒤', '60만원', null),
            _SharedExpenseItem('수도세', '10일 뒤', '알 수 없음', null),
            _SharedExpenseItem('전기세', '15일 뒤', '45,000원', null),
            _SharedExpenseItem('가스세', '20일 뒤', '30,000원', null),
          ]
        : [
            _SharedExpenseItem('콘푸라이트 500g', '25.05.04.', '5,980원', '3개'),
            _SharedExpenseItem('두루마리 휴지', '25.05.05.', '8,000원', '3개'),
            _SharedExpenseItem('10W 충전기', '25.05.14.', '9,000원', '3개'),
            _SharedExpenseItem('그래놀라 450g', '25.05.16.', '12,000원', '3개'),
            _SharedExpenseItem('인덕션용 냄비', '25.05.17.', '20,000원', '3개'),
          ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        final shouldTruncate = item.name.length > 5;
        final displayText = shouldTruncate 
            ? '${item.name.substring(0, 5)}...' 
            : item.name;
        
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: shouldTruncate
                  ? Builder(
                      builder: (context) {
                        final key = GlobalKey();
                        return GestureDetector(
                          onTap: () {
                            final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              onTextTap(context, renderBox, item.name);
                            }
                          },
                          child: Text(
                            displayText,
                            key: key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    )
                  : Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Text(
                item.date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: Text(
                item.amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            if (!isUtility) ...[
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Text(
                  item.quantity ?? '',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SharedExpenseItem {
  final String name;
  final String date;
  final String amount;
  final String? quantity;

  _SharedExpenseItem(this.name, this.date, this.amount, this.quantity);
}

// Glassmorphic Date Picker (from chore_assignment_modal.dart)
class _GlassmorphicDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool isStartDate;

  const _GlassmorphicDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.isStartDate,
  });

  @override
  State<_GlassmorphicDatePicker> createState() => _GlassmorphicDatePickerState();
}

class _GlassmorphicDatePickerState extends State<_GlassmorphicDatePicker> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _previousMonth() {
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    if (!prevMonth.isBefore(firstMonth)) {
      setState(() {
        _currentMonth = prevMonth;
      });
    }
  }

  void _nextMonth() {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (!nextMonth.isAfter(lastMonth)) {
      setState(() {
        _currentMonth = nextMonth;
      });
    }
  }

  bool _canGoPrevious() {
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    return !prevMonth.isBefore(firstMonth);
  }

  bool _canGoNext() {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !nextMonth.isAfter(lastMonth);
  }

  bool _isDateSelectable(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final firstDateOnly = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final lastDateOnly = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !dateOnly.isBefore(firstDateOnly) && !dateOnly.isAfter(lastDateOnly);
  }

  bool _isDateSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  void _selectDate(DateTime date) {
    if (_isDateSelectable(date)) {
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day);
      });
    }
  }

  String _getMonthYearText() {
    final months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return '${_currentMonth.year}년 ${months[_currentMonth.month - 1]}';
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // 0 = 일요일, 6 = 토요일

    final days = <DateTime>[];
    
    // 이전 달의 마지막 날들
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(firstDay.subtract(Duration(days: i + 1)));
    }

    // 현재 달의 날들
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // 다음 달의 첫 날들 (35개 셀을 채우기 위해 - 5주)
    final remainingDays = 35 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month + 1, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth - 32,
          maxHeight: screenHeight * 0.45, // 공용 소비 물품 관리 컴포넌트와 동일한 높이
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white,
                  width: 0.5,
                ),
                gradient: const RadialGradient(
                  center: Alignment(-0.1212, -0.1178),
                  radius: 1.7145,
                  colors: [
                    Color.fromRGBO(255, 255, 255, 0.10),
                    Color.fromRGBO(255, 255, 255, 0.15),
                  ],
                  stops: [0.0, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(255, 255, 255, 0.25),
                    offset: Offset(4, 4),
                    blurRadius: 30,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Opacity(
                        opacity: _canGoPrevious() ? 1 : 0.3,
                        child: GestureDetector(
                          onTap: _canGoPrevious() ? _previousMonth : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.white.withOpacity(0.95),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        _getMonthYearText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17, // 14 * 1.5 = 21
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      Opacity(
                        opacity: _canGoNext() ? 1 : 0.3,
                        child: GestureDetector(
                          onTap: _canGoNext() ? _nextMonth : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.white.withOpacity(0.95),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 요일 헤더
                  Row(
                    children: weekdays.map((day) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard Variable',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // 날짜 그리드
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.2,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: 35,
                      itemBuilder: (context, index) {
                        final date = days[index];
                        final isCurrentMonth = date.month == _currentMonth.month;
                        final isSelectable = _isDateSelectable(date);
                        final isSelected = _isDateSelected(date);
                        final isToday = date.year == DateTime.now().year &&
                            date.month == DateTime.now().month &&
                            date.day == DateTime.now().day;

                        return GestureDetector(
                          onTap: () => _selectDate(date),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            child: isSelected
                                ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${date.day}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: isToday
                                          ? Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          color: isCurrentMonth && isSelectable
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.4),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard Variable',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(_selectedDate),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard Variable',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
