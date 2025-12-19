import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/services/chore_service.dart';
import 'package:partition_app/shared/widgets/glassmorphism_widget.dart';

/// 집안일 자동 배정 모달
class ChoreAssignmentModal extends StatefulWidget {
  final VoidCallback? onSuccess; // 배정 성공 시 호출될 콜백
  
  const ChoreAssignmentModal({
    super.key,
    this.onSuccess,
  });

  @override
  State<ChoreAssignmentModal> createState() => _ChoreAssignmentModalState();
}

class _ChoreAssignmentModalState extends State<ChoreAssignmentModal> {
  final Set<String> _selectedChores = {};
  final Set<String> _tempSelectedChores = {};
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isDropdownOpen = false;
  final ChoreService _choreService = ChoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  final List<String> _allChores = [
    '설거지',
    '요리',
    '빨래',
    '음식물 쓰레기 버리기',
    '분리수거',
    '청소기 돌리기',
    '바닥 닦기',
    '창문, 창틀 닦기',
    '화장실 청소',
    '냉장고 청소',
  ];
  
  /// 집안일 이름을 서버가 기대하는 형식으로 변환
  /// 이미지의 API 명세에 따르면 서버는 집안일 이름을 받을 수 있음
  /// 예: "설거지" -> "설거지 하기" 또는 그대로 "설거지"
  List<String> _convertChoreNamesForApi(List<String> choreNames) {
    // 집안일 이름 매핑 (프론트엔드 이름 -> 서버가 기대하는 이름)
    final nameMapping = {
      '설거지': '설거지 하기',
      '요리': '요리 하기',
      '빨래': '빨래 하기',
      '음식물 쓰레기 버리기': '음식물 쓰레기 버리기',
      '분리수거': '재활용 쓰레기 버리기',
      '청소기 돌리기': '청소기 돌리기',
      '바닥 닦기': '바닥 닦기',
      '창문, 창틀 닦기': '창문, 창틀 닦기',
      '화장실 청소': '화장실 청소하기',
      '냉장고 청소': '냉장고 청소하기',
    };
    
    return choreNames.map((name) => nameMapping[name] ?? name).toList();
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAutoAssign() async {
    if (_isLoading) return;

    // 선택된 집안일이 없으면 경고
    if (_selectedChores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배정할 집안일을 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final start = _formatDateForApi(_startDate);
      final end = _formatDateForApi(_endDate);
      final selectedChoresList = _selectedChores.toList();
      
      // 집안일 이름을 서버가 기대하는 형식으로 변환
      final convertedChoreNames = _convertChoreNamesForApi(selectedChoresList);
      
      // 디버깅: 선택된 집안일 확인
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🏠 집안일 자동 배정 요청');
      debugPrint('  - 시작일: $start');
      debugPrint('  - 종료일: $end');
      debugPrint('  - 선택된 집안일 개수: ${selectedChoresList.length}');
      debugPrint('  - 선택된 집안일 목록 (원본): $selectedChoresList');
      debugPrint('  - 변환된 집안일 목록 (API 전송용): $convertedChoreNames');
      debugPrint('  - 전체 집안일 목록: $_allChores');
      debugPrint('═══════════════════════════════════════════════════════');

      await _choreService.autoAssignChores(
        startDate: start,
        endDate: end,
        selectedChores: convertedChoreNames, // 변환된 집안일 목록 전달
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      
      // 콜백 호출하여 캘린더 갱신
      widget.onSuccess?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('집안일 자동 배정이 완료되었어요.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message = '집안일 자동 배정에 실패했어요.';
      if (e is ApiException && e.message != null) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openDropdown() {
    setState(() {
      _isDropdownOpen = true;
      _tempSelectedChores.clear();
      _tempSelectedChores.addAll(_selectedChores);
    });
  }

  void _closeDropdown() {
    setState(() {
      _isDropdownOpen = false;
    });
  }

  void _confirmSelection() {
    setState(() {
      _selectedChores.clear();
      _selectedChores.addAll(_tempSelectedChores);
      _isDropdownOpen = false;
    });
  }

  void _toggleTempChore(String chore) {
    setState(() {
      if (_tempSelectedChores.contains(chore)) {
        _tempSelectedChores.remove(chore);
      } else {
        _tempSelectedChores.add(chore);
      }
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 14)); // 2주 후까지

    // initialDate가 firstDate보다 이전이면 today를 사용
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

    if (picked != null) {
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
    return GestureDetector(
      onTap: () {
        if (_isDropdownOpen) {
          _closeDropdown();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () {}, // 내부 클릭은 전파 방지
          child: Container(
            width: 350,
            height: 323,
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 제목
                            const Text(
                              '집안일 자동 배정',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white, // #FFF
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard Variable',
                                height: 0.7, // line-height: 14px / 20px = 70%
                              ),
                            ),
                          const SizedBox(height: 8),
                          // 부제목
                          const Text(
                            '자동 배정할 집안일을 선택하세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard Variable',
                              height: 1.07692, // line-height: 14px / 13px = 1.07692
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 카테고리 선택 칸
                          GestureDetector(
                            onTap: () {
                              if (_isDropdownOpen) {
                                _closeDropdown();
                              } else {
                                _openDropdown();
                              }
                            },
                            child: SizedBox(
                              width: 259.331,
                              height: 43,
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
                                          Color.fromRGBO(255, 255, 255, 0.15),
                                          Color.fromRGBO(255, 255, 255, 0.30),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isDropdownOpen
                                              ? Icons.arrow_drop_up
                                              : Icons.arrow_drop_down,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _selectedChores.isEmpty
                                              ? Text(
                                                  '집안일 선택',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Pretendard Variable',
                                                  ),
                                                )
                                              : Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: _selectedChores.map((chore) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(12),
                                                        color: Colors.white.withOpacity(0.2),
                                                      ),
                                                      child: Text(
                                                        chore,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w400,
                                                          fontFamily: 'Pretendard Variable',
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // 집안일 선택과 날짜 사이 간격 축소
                          // 날짜 범위 선택
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _selectDate(true),
                                child: GlassmorphismWidget(
                                  width: 108.217,
                                  height: 43,
                                  borderRadius: BorderRadius.circular(20),
                                  backgroundOpacity: 0.1,
                                  borderColor: Colors.white.withOpacity(0.5),
                                  strokeGradient: const RadialGradient(
                                    center: Alignment(-0.1212, -0.1178),
                                    radius: 1.7145,
                                    colors: [
                                      Color.fromRGBO(255, 255, 255, 0.10),
                                      Color.fromRGBO(255, 255, 255, 0.15),
                                    ],
                                    stops: [0.0, 1.0],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatDate(_startDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '~',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _selectDate(false),
                                child: GlassmorphismWidget(
                                  width: 108.217,
                                  height: 43,
                                  borderRadius: BorderRadius.circular(20),
                                  backgroundOpacity: 0.1,
                                  borderColor: Colors.white.withOpacity(0.5),
                                  strokeGradient: const RadialGradient(
                                    center: Alignment(-0.1212, -0.1178),
                                    radius: 1.7145,
                                    colors: [
                                      Color.fromRGBO(255, 255, 255, 0.10),
                                      Color.fromRGBO(255, 255, 255, 0.15),
                                    ],
                                    stops: [0.0, 1.0],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatDate(_endDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 자동 배정 버튼
                          SizedBox(
                            width: 266,
                            height: 45.327,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleAutoAssign,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
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
                                    child: const Center(
                                      child: Text(
                                        '자동 배정',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Pretendard Variable',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 드롭다운 메뉴 - 최상위 레이어
                if (_isDropdownOpen)
                  Positioned(
                    top: 24 + 20 + 8 + 13 + 8 + 24 + 43, // 패딩 + 제목 + 여백 + 부제목 + 여백 + 카테고리 선택 칸 위치
                    left: 24 + (350 - 259.331 - 48) / 2, // 모달 패딩 + 중앙 정렬
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // 드롭다운 내부 클릭은 전파 방지
                      child: Container(
                        width: 259.331,
                        constraints: const BoxConstraints(maxHeight: 200),
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
                                    Color.fromRGBO(255, 255, 255, 0.15),
                                    Color.fromRGBO(255, 255, 255, 0.30),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: _allChores.map((chore) {
                                          final isSelected =
                                              _tempSelectedChores.contains(chore);
                                          return GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _toggleTempChore(chore),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.5,
                                                      ),
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.transparent,
                                                    ),
                                                    child: isSelected
                                                        ? const Icon(
                                                            Icons.check,
                                                            size: 14,
                                                            color: Colors.black,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      chore,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w400,
                                                        fontFamily:
                                                            'Pretendard Variable',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.3),
                                    height: 1,
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _confirmSelection,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: const Center(
                                        child: Text(
                                          '선택 완료',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Pretendard Variable',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 글래스모피즘 효과가 적용된 날짜 선택 다이얼로그
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

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 280,
          maxHeight: 360, // 전체 다이얼로그 높이 제한 (320 → 360)
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 패딩 증가 (horizontal: 12→16, vertical: 8→16)
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
                        width: 24,
                        height: 24,
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
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _getMonthYearText(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  Opacity(
                    opacity: _canGoNext() ? 1 : 0.3,
                    child: GestureDetector(
                      onTap: _canGoNext() ? _nextMonth : null,
                      child: Container(
                        width: 24,
                        height: 24,
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
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // 간격 증가 (6 → 10)
              // 요일 헤더
              Row(
                children: weekdays.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8), // 간격 증가 (4 → 8)
              // 날짜 그리드
              SizedBox(
                height: 160, // GridView 높이 명시적으로 제한 (180 → 160)
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.8, // 셀을 더 넓고 낮게 만들어 캘린더 높이 감소 (1.4 → 1.8)
                  mainAxisSpacing: 0.5, // 간격 더 줄임 (1 → 0.5)
                  crossAxisSpacing: 0.5, // 간격 더 줄임 (1 → 0.5)
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
                      margin: const EdgeInsets.all(0.25), // 마진 줄임 (0.5 → 0.25)
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Pretendard Variable',
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: isToday
                                    ? Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 0.8,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isCurrentMonth && isSelectable
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.white.withOpacity(0.4),
                                    fontSize: 11,
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
              const SizedBox(height: 8), // 간격 증가 (4 → 8)
              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 위아래 패딩 줄임 (5 → 4)
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_selectedDate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 위아래 패딩 줄임 (5 → 4)
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.08), // 더 투명하게 (0.1 → 0.08)
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 11,
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

