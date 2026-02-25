import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/shared/widgets/frosted_panel.dart';
import 'package:partition_app/features/partition/services/calendar_service.dart';
import 'package:partition_app/features/partition/models/calendar_response_model.dart';
import 'package:partition_app/features/partition/models/daily_calendar_response_model.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';

/// 홈 화면용 캘린더 위젯
/// 글래스모피즘 효과가 적용된 커스텀 캘린더
class HomeCalendarWidget extends StatefulWidget {
  final ValueChanged<DateTime>? onDateSelected;
  final GlobalKey<HomeCalendarWidgetState>? refreshKey; // 외부에서 갱신하기 위한 키
  
  const HomeCalendarWidget({
    super.key,
    this.onDateSelected,
    this.refreshKey,
  });

  @override
  State<HomeCalendarWidget> createState() => HomeCalendarWidgetState();
}

/// HomeCalendarWidget의 State를 public으로 노출 (외부에서 refreshCalendar 호출 가능)
class HomeCalendarWidgetState extends State<HomeCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  DateTime? _detailDate;
  bool _showDetail = false;

  // API에서 가져온 캘린더 데이터 (캐싱)
  Map<String, List<_CalendarEvent>>? _cachedEvents;
  String? _cachedMonthKey;
  bool _isLoading = false;
  final CalendarService _calendarService = CalendarService();
  
  // 일간 상세 데이터 캐싱
  Map<String, List<DailyCalendarItem>>? _cachedDailyEvents;
  String? _cachedDailyDateKey;
  bool _isLoadingDaily = false;
  
  Map<String, List<_CalendarEvent>> get _events {
    return _cachedEvents ?? {};
  }

  List<DailyCalendarItem>? _getDailyEvents(String dateKey) {
    return _cachedDailyEvents?[dateKey];
  }

  /// DailyCalendarItem을 _CalendarEvent로 변환
  List<_CalendarEvent> _convertDailyItemsToEvents(List<DailyCalendarItem> items) {
    return items.map((item) {
      CalendarEventType eventType;
      String description;
      
      if (item.category.toUpperCase() == 'CHORE') {
        eventType = CalendarEventType.chore;
        // 작성자 이름을 앞에 표시
        if (item.assigneeName != null && item.assigneeName!.isNotEmpty) {
          description = '${item.assigneeName} · ${item.title}';
        } else {
          description = item.title;
        }
        if (item.isCompleted) {
          description += ' ✓';
        }
      } else if (item.category.toUpperCase() == 'SCHEDULE') {
        eventType = CalendarEventType.memo;
        // 작성자 이름을 앞에 표시
        if (item.assigneeName != null && item.assigneeName!.isNotEmpty) {
          description = '${item.assigneeName} · ${item.title}';
        } else {
          description = item.title;
        }
        if (item.isCompleted) {
          description += ' ✓';
        }
      } else {
        // 기본값 (공과금 등)
        eventType = CalendarEventType.bill;
        // 작성자 이름을 앞에 표시
        if (item.assigneeName != null && item.assigneeName!.isNotEmpty) {
          description = '${item.assigneeName} · ${item.title}';
        } else {
          description = item.title;
        }
      }
      
      return _CalendarEvent(
        eventType, 
        description,
        id: item.id,
        category: item.category,
        assigneeName: item.assigneeName,
        isOwner: item.isOwner,
      );
    }).toList();
  }

  /// 캘린더 데이터 강제 갱신 (외부에서 호출 가능)
  void refreshCalendar() {
    // 캐시 무효화
    _cachedMonthKey = null;
    _cachedEvents = null;
    _cachedDailyEvents = null; // 모든 일간 캐시 무효화
    
    // 데이터 재로드 (강제 갱신)
    _loadCalendarData(_currentMonth.year, _currentMonth.month, forceRefresh: true);
    if (_detailDate != null) {
      _loadDailyCalendarData(_detailDate!, forceRefresh: true);
    }
  }

  Future<void> _loadCalendarData(int year, int month, {bool forceRefresh = false}) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    
    // 강제 갱신이 아니고 이미 같은 월의 데이터가 캐시되어 있으면 다시 로드하지 않음
    if (!forceRefresh && _cachedMonthKey == monthKey && _cachedEvents != null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _calendarService.getMonthlyCalendar(
        year: year,
        month: month,
      );

      if (response.isSuccess && response.result != null) {
        final Map<String, List<_CalendarEvent>> events = {};
        
        // 집안일 텍스트 목록
        final choreTexts = [
          '설거지 담당',
          '빨래 담당',
          '청소 담당',
          '분리수거 담당',
        ];
        
        // 공과금 텍스트 목록
        final billTexts = [
          '전기요금 납부',
          '가스요금 납부',
          '인터넷 요금 납부',
          '수도요금 납부',
        ];
        
        // 일정 텍스트 목록
        final scheduleTexts = [
          '일정이 있습니다',
          '중요한 일정',
          '약속',
        ];

        for (final item in response.result!) {
          final date = item.date;
          final choreCount = item.choreCount;
          final scheduleCount = item.scheduleCount;
          final utilityBillsCount = item.utilityBillsCount;
          
          final List<_CalendarEvent> dayEvents = [];
          
          // 집안일 추가
          for (int i = 0; i < choreCount; i++) {
            final index = (date.hashCode + i) % choreTexts.length;
            dayEvents.add(_CalendarEvent(
              CalendarEventType.chore,
              choreTexts[index],
              isOwner: null,
            ));
          }
          
          // 공과금 추가
          for (int i = 0; i < utilityBillsCount; i++) {
            final index = (date.hashCode + i) % billTexts.length;
            dayEvents.add(_CalendarEvent(
              CalendarEventType.bill,
              billTexts[index],
              isOwner: null,
            ));
          }
          
          // 일정 추가
          for (int i = 0; i < scheduleCount; i++) {
            final index = (date.hashCode + i) % scheduleTexts.length;
            dayEvents.add(_CalendarEvent(
              CalendarEventType.memo,
              scheduleTexts[index],
              isOwner: null,
            ));
          }
          
          if (dayEvents.isNotEmpty) {
            events[date] = dayEvents;
          }
        }
        
        if (mounted) {
          setState(() {
            _cachedEvents = events;
            _cachedMonthKey = monthKey;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // 에러 발생 시 빈 데이터로 처리
      if (mounted) {
        debugPrint('캘린더 데이터 로드 실패: $e');
      }
    }
  }

  /// 일간 캘린더 상세 조회
  Future<void> _loadDailyCalendarData(DateTime date, {bool forceRefresh = false}) async {
    final dateKey = _dateKey(date);
    
    // 강제 갱신이 아니고 이미 같은 날짜의 데이터가 캐시되어 있으면 다시 로드하지 않음
    if (!forceRefresh && _cachedDailyDateKey == dateKey && _cachedDailyEvents != null && _cachedDailyEvents![dateKey] != null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingDaily = true;
    });

    try {
      final response = await _calendarService.getDailyCalendar(
        date: dateKey,
      );

      if (response.isSuccess && response.result != null) {
        if (mounted) {
          setState(() {
            _cachedDailyEvents ??= {};
            _cachedDailyEvents![dateKey] = response.result!;
            _cachedDailyDateKey = dateKey;
            _isLoadingDaily = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cachedDailyEvents ??= {};
            _cachedDailyEvents![dateKey] = [];
            _cachedDailyDateKey = dateKey;
            _isLoadingDaily = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedDailyEvents ??= {};
          _cachedDailyEvents![dateKey] = [];
          _cachedDailyDateKey = dateKey;
          _isLoadingDaily = false;
        });
      }
      // 에러 발생 시 빈 데이터로 처리
      if (mounted) {
        debugPrint('일간 캘린더 데이터 로드 실패: $e');
      }
    }
  }
  
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

  List<DateTime> _getWeekDays(DateTime centerDate) {
    // 선택한 날짜가 속한 주의 시작일 (일요일) 찾기
    final weekday = centerDate.weekday % 7; // 0 = 일요일
    final startOfWeek = centerDate.subtract(Duration(days: weekday));
    
    // 일주일 (7일) 생성
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  Widget _buildWeekView({
    required int startMonth,
    required int currentMonthIndex,
    required DateTime centerDate,
  }) {
    final weekDays = _getWeekDays(centerDate);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 고정 높이 요소들의 높이 계산
        final monthSelectorHeight = 50.0;
        final headerHeight = 40.0; // 요일 헤더
        final calendarHeight = 80.0; // 날짜 그리드 높이
        final spacing = 20.0 + 12.0 + 4.0; // SizedBox 높이들 (날짜-이벤트 간격 4로 줄임)
        final fixedHeight = monthSelectorHeight + headerHeight + calendarHeight + spacing;
        
        // 남은 공간을 이벤트 목록에 할당 (최소 200px)
        final availableHeight = constraints.maxHeight;
        final eventListHeight = availableHeight > fixedHeight 
            ? availableHeight - fixedHeight 
            : 200.0;
        
        return Column(
          key: const ValueKey('week-view'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthSelector(startMonth, currentMonthIndex),
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
            SizedBox(
              height: 80,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: false,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = weekDays[index];
                  final isToday = _isToday(date);
                  final isSelected = _detailDate != null &&
                      _detailDate!.year == date.year &&
                      _detailDate!.month == date.month &&
                      _detailDate!.day == date.day;
                  final events = _events[_dateKey(date)] ?? [];
                  // 각 타입이 하나라도 있으면 해당 색의 점 1개만 표시
                  final showBill = events.any((e) => e.type == CalendarEventType.bill);
                  final showChore = events.any((e) => e.type == CalendarEventType.chore);
                  final showMemo = events.any((e) => e.type == CalendarEventType.memo);
                  
                  return GestureDetector(
                    onTap: () => _handleDateTap(date),
                    child: CustomPaint(
                      painter: _DateHighlightPainter(
                        showOrbit: false,
                        showSelection: isSelected,
                        color: Colors.white,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // 이벤트 표시 (각 타입당 점 1개)
                          if (showBill || showChore || showMemo)
                            Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showBill)
                                    Container(
                                      width: 4.211,
                                      height: 4.211,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF4E2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (showBill && (showChore || showMemo))
                                    const SizedBox(width: 2),
                                  if (showChore)
                                    Container(
                                      width: 4.211,
                                      height: 4.211,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDBD1C2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (showChore && showMemo)
                                    const SizedBox(width: 2),
                                  if (showMemo)
                                    Container(
                                      width: 4.211,
                                      height: 4.211,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7C7C7C),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 선택된 날짜의 이벤트 목록 (스크롤 가능) - 날짜 바로 아래부터 확장
            if (_detailDate != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _isLoadingDaily
                        ? const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : Expanded(
                            child: _buildEventList(_detailDate!),
                          ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector(int startMonth, int currentMonthIndex) {
    return Row(
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
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
              icon: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 20),
              onPressed: _previousMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 20),
              onPressed: _nextMonth,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
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

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateLabel(DateTime date) {
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return '${weekdays[date.weekday % 7]} · ${date.month}/${date.day}';
  }

  /// 현재 사용자 이름 가져오기 (여러 소스 확인)
  Future<String?> _getCurrentUserName(BuildContext context, String? providerUserName) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 사용자 이름 조회 시작');
    debugPrint('  - Provider 사용자 이름: $providerUserName');
    
    // 1. Provider에서 사용자 정보 확인 (이미 전달받음)
    if (providerUserName != null && providerUserName.isNotEmpty) {
      await StorageService.setUserName(providerUserName);
      return providerUserName;
    }
    
    // 2. 로컬 스토리지에서 먼저 확인 (서버 에러가 발생할 수 있으므로)
    final localUserName = await StorageService.getUserName();
    if (localUserName != null && localUserName.isNotEmpty) {
      return localUserName;
    }
    
    // 3. 서버에서 사용자 정보 조회 시도 (로컬에 없을 때만)
    try {
      final authService = AuthService();
      final userInfo = await authService.getUserInfo();
      if (userInfo?.name != null && userInfo!.name!.isNotEmpty) {
        // 서버에서 가져온 이름을 로컬에도 저장
        await StorageService.setUserName(userInfo.name!);
        return userInfo.name;
      }
    } catch (e) {
      // 서버 에러는 무시하고 null 반환
    }
    
    return null;
  }

  /// 이벤트 목록 위젯 생성
  Widget _buildEventList(DateTime date) {
    final dateKey = _dateKey(date);
    final dailyItems = _getDailyEvents(dateKey);
    
    // 일간 상세 데이터가 있으면 사용, 없으면 월간 데이터 사용
    final events = dailyItems != null
        ? _convertDailyItemsToEvents(dailyItems)
        : (_events[dateKey] ?? []);
    
    if (events.isEmpty) {
      return const Center(
        child: Text(
          '일정이 없습니다',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }
    
    return ListView(
      shrinkWrap: false,
      padding: const EdgeInsets.only(top: 0),
      children: events.map(
        (event) {
          // SCHEDULE 카테고리이고 isOwner가 true인 경우에만 수정/삭제 가능
          final isSchedule = event.category?.toUpperCase() == 'SCHEDULE';
          final canEdit = isSchedule && (event.isOwner == true);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EventChip(
              event: event,
              // isOwner가 true인 경우에만 수정/삭제 가능
              onDelete: event.id != null && canEdit
                  ? () => _handleDeleteSchedule(event.id!, date)
                  : null,
              onEdit: event.id != null && canEdit
                  ? () => _handleEditSchedule(event.id!, event.description, date)
                  : null,
            ),
          );
        },
      ).toList(),
    );
  }

  Future<void> _handleDeleteSchedule(int scheduleId, DateTime date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 0.5,
            ),
            gradient: const RadialGradient(
              center: Alignment(-0.1212, -0.1178),
              radius: 1.6319,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.10),
                Color.fromRGBO(255, 255, 255, 0.15),
              ],
              stops: [0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '일정 삭제',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '정말 이 일정을 삭제하시겠습니까?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGlassmorphismButton(
                        text: '취소',
                        onTap: () => Navigator.of(context).pop(false),
                        width: 100,
                      ),
                      const SizedBox(width: 12),
                      _buildGlassmorphismButton(
                        text: '삭제',
                        onTap: () => Navigator.of(context).pop(true),
                        width: 100,
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

    if (confirmed != true) return;

    try {
      // DELETE /api/schedules/{scheduleId} 호출
      final response = await _calendarService.deleteSchedule(scheduleId: scheduleId);
      
      if (!mounted) return;

      // API 응답 확인 (isSuccess 체크)
      if (!response.isSuccess) {
        throw Exception(response.message ?? '일정 삭제에 실패했습니다.');
      }

      // 캐시 무효화 및 재로드
      final dateKey = _dateKey(date);
      _cachedDailyEvents?.remove(dateKey);
      await _loadDailyCalendarData(date, forceRefresh: true);

      // 월간 캘린더도 갱신
      refreshCalendar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty ? response.message : '일정이 삭제되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 삭제에 실패했습니다: ${e is ApiException ? e.message : e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleEditSchedule(int scheduleId, String currentContent, DateTime date) async {
    // 작성자 이름 제거 (형식: "작성자이름 · 제목" 또는 "제목")
    String titleOnly = currentContent;
    if (currentContent.contains(' · ')) {
      final parts = currentContent.split(' · ');
      if (parts.length > 1) {
        titleOnly = parts.sublist(1).join(' · ');
      }
    }
    // 완료 표시 제거
    titleOnly = titleOnly.replaceAll(' ✓', '').trim();
    
    final TextEditingController controller = TextEditingController(text: titleOnly);
    DateTime selectedDate = date;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              alignment: Alignment.center,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 0.5,
                  ),
                  gradient: const RadialGradient(
                    center: Alignment(-0.1212, -0.1178),
                    radius: 1.6319,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.10),
                      Color.fromRGBO(255, 255, 255, 0.15),
                    ],
                    stops: [0.0, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '일정 수정',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 입력 필드
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                            gradient: const RadialGradient(
                              center: Alignment(-0.1212, -0.1178),
                              radius: 1.6319,
                              colors: [
                                Color.fromRGBO(255, 255, 255, 0.10),
                                Color.fromRGBO(255, 255, 255, 0.15),
                              ],
                              stops: [0.0, 1.0],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: TextField(
                                controller: controller,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Pretendard Variable',
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '일정을 입력해주세요...',
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard Variable',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 날짜 선택 버튼
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDialog<DateTime>(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (context) => _GlassmorphicDatePicker(
                                initialDate: selectedDate,
                                firstDate: DateTime(2020, 1, 1), // 충분히 과거
                                lastDate: DateTime(2100, 12, 31), // 충분히 미래
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.5,
                              ),
                              gradient: const RadialGradient(
                                center: Alignment(-0.1212, -0.1178),
                                radius: 1.6319,
                                colors: [
                                  Color.fromRGBO(255, 255, 255, 0.10),
                                  Color.fromRGBO(255, 255, 255, 0.15),
                                ],
                                stops: [0.0, 1.0],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '날짜 변경: ${_formatDate(selectedDate)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Pretendard Variable',
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGlassmorphismButton(
                              text: '취소',
                              onTap: () => Navigator.of(context).pop(),
                              width: 100,
                            ),
                            const SizedBox(width: 12),
                            _buildGlassmorphismButton(
                              text: '저장',
                              onTap: () {
                                Navigator.of(context).pop({
                                  'content': controller.text.trim(),
                                  'date': selectedDate,
                                });
                              },
                              width: 100,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    final newContent = result['content'] as String;
    final newDate = result['date'] as DateTime;

    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 내용을 입력해주세요.')),
      );
      return;
    }

    try {
      final dateString = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
      await _calendarService.updateSchedule(
        scheduleId: scheduleId,
        content: newContent,
        date: dateString,
      );

      if (!mounted) return;

      // 캐시 무효화 및 재로드
      final dateKey = _dateKey(date);
      _cachedDailyEvents?.remove(dateKey);
      // 날짜가 변경된 경우 새로운 날짜도 캐시 무효화
      if (dateKey != _dateKey(newDate)) {
        _cachedDailyEvents?.remove(_dateKey(newDate));
      }
      await _loadDailyCalendarData(date);
      if (dateKey != _dateKey(newDate)) {
        await _loadDailyCalendarData(newDate);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정이 수정되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 수정에 실패했습니다: ${e is ApiException ? e.message : '알 수 없는 오류'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildGlassmorphismButton({
    required String text,
    required VoidCallback onTap,
    double width = 100,
    double height = 45.327,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 0.5,
          ),
          gradient: const RadialGradient(
            center: Alignment(-0.1212, -0.1178),
            radius: 1.6319,
            colors: [
              Color.fromRGBO(255, 255, 255, 0.10),
              Color.fromRGBO(255, 255, 255, 0.15),
            ],
            stops: [0.0, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _previousMonth() {
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });
      _loadCalendarData(_currentMonth.year, _currentMonth.month);
    }
  }

  void _nextMonth() {
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });
      _loadCalendarData(_currentMonth.year, _currentMonth.month);
    }
  }

  void _selectMonth(int monthIndex) {
    if (!mounted) return;
    if (mounted) {
      setState(() {
      final newMonth = monthIndex + 1;
      _currentMonth = DateTime(_currentMonth.year, newMonth);
      
      // 주간 달력을 보고 있는 경우, 같은 날짜로 해당 월의 주간 달력으로 이동
      if (_showDetail && _detailDate != null) {
        final currentDay = _detailDate!.day;
        final lastDayOfNewMonth = DateTime(_currentMonth.year, newMonth + 1, 0).day;
        // 새 월의 마지막 날보다 큰 날짜를 선택한 경우, 마지막 날로 조정
        final targetDay = currentDay > lastDayOfNewMonth ? lastDayOfNewMonth : currentDay;
        _detailDate = DateTime(_currentMonth.year, newMonth, targetDay);
        _selectedDate = _detailDate!;
        // 주간 달력 모드 유지
        _showDetail = true;
      }
      });
      _loadCalendarData(_currentMonth.year, _currentMonth.month);
    }
  }

  void _handleDateTap(DateTime date) {
    if (!mounted) return;
    if (mounted) {
      setState(() {
      final bool sameDetail =
          _detailDate != null && _detailDate!.year == date.year && _detailDate!.month == date.month && _detailDate!.day == date.day;
      final bool sameSelected =
          _selectedDate.year == date.year && _selectedDate.month == date.month && _selectedDate.day == date.day;
      
      // 같은 날짜를 다시 탭하면 주 뷰/월 뷰 전환
      if (_showDetail && sameDetail) {
        _showDetail = false;
      } else if (!_showDetail && sameSelected) {
        // 월 뷰에서 같은 날짜를 다시 탭하면 주 뷰로 전환
        _detailDate = date;
        _showDetail = true;
      } else {
        // 다른 날짜를 탭하면 선택만 업데이트 (월 뷰 유지)
        _selectedDate = date;
        _detailDate = date;
        // 주 뷰로 전환하지 않고 월 뷰에서 일정 표시
        _showDetail = false;
      }
      
      if (date.month != _currentMonth.month) {
        _currentMonth = DateTime(date.year, date.month);
      }
      });
      
      // 일간 상세 조회 호출
      _loadDailyCalendarData(date);
      
      // 선택된 날짜를 외부에 알림
      widget.onDateSelected?.call(date);
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendarData(_currentMonth.year, _currentMonth.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final currentMonthIndex = _currentMonth.month - 1;

    int startMonth = (currentMonthIndex ~/ 4) * 4;
    if (startMonth + 4 > 12) {
      startMonth = 12 - 4;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final Widget child = _showDetail && _detailDate != null
            ? _buildWeekView(
                startMonth: startMonth,
                currentMonthIndex: currentMonthIndex,
                centerDate: _detailDate!,
              )
            : _buildCalendarContent(
                days: days,
                startMonth: startMonth,
                currentMonthIndex: currentMonthIndex,
                useExpandedGrid: hasBoundedHeight,
                maxHeight: hasBoundedHeight ? constraints.maxHeight : null,
              );

        return FrostedPanel(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: child,
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
    double? maxHeight,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 그리드 높이 계산 (고정 높이 사용)
        final gridHeight = 6 * ((constraints.maxWidth - 6 * 8) / 7 / 1.0); // 6주, childAspectRatio 1.0 기준
        
        final gridView = GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: 42, // 6주
          itemBuilder: (context, index) {
            final date = days[index];
            final isCurrentMonth = date.month == _currentMonth.month;
            final isToday = _isToday(date);
            final isSelected = _isSelected(date);
            final events = _events[_dateKey(date)] ?? [];
            // 각 타입이 하나라도 있으면 해당 색의 점 1개만 표시
            final showBill = events.any((e) => e.type == CalendarEventType.bill);
            final showChore = events.any((e) => e.type == CalendarEventType.chore);
            final showMemo = events.any((e) => e.type == CalendarEventType.memo);
            
            return GestureDetector(
              onTap: () => _handleDateTap(date),
              child: CustomPaint(
                painter: _DateHighlightPainter(
                  showOrbit: false,
                  showSelection: isSelected,
                  color: Colors.white,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
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
                    ),
                    // 이벤트 표시 (각 타입당 점 1개)
                    if (showBill || showChore || showMemo)
                      Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showBill)
                              Container(
                                width: 4.211,
                                height: 4.211,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF4E2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (showBill && (showChore || showMemo))
                              const SizedBox(width: 2),
                            if (showChore)
                              Container(
                                width: 4.211,
                                height: 4.211,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBD1C2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (showChore && showMemo)
                              const SizedBox(width: 2),
                            if (showMemo)
                              Container(
                                width: 4.211,
                                height: 4.211,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C7C7C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );

        return Column(
          key: const ValueKey('month-view'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthSelector(startMonth, currentMonthIndex),
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
            // 날짜 그리드
            SizedBox(
              height: gridHeight,
              child: gridView,
            ),
            // 월간 뷰에서는 이벤트 목록을 표시하지 않음 (더블클릭 시 주간 뷰에서만 표시)
            if (useExpandedGrid && constraints.hasBoundedHeight)
              // 공간을 채우기 위한 Spacer
              const Spacer(),
          ],
        );
      },
    );
  }
}

class _DateHighlightPainter extends CustomPainter {
  final bool showOrbit;
  final bool showSelection;
  final Color color;

  _DateHighlightPainter({
    required this.showOrbit,
    required this.showSelection,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    if (showSelection) {
      final Paint basePaint = Paint()
        ..color = color.withOpacity(0.15);
      canvas.drawCircle(center, radius * 0.8, basePaint);
    }

    if (!showOrbit) return;

    final Paint dotPaint = Paint();
    final double orbitRadius = radius * 0.9;
    final double gap = 6.0;
    final List<double> dotDiameters = [8, 6, 4.5];
    double currentAngle = 0;

    for (int i = 0; i < dotDiameters.length; i++) {
      final double dotRadius = dotDiameters[i] / 2;
      dotPaint.color = color.withOpacity(0.9 - i * 0.25);

      final offset = Offset(
        center.dx + (orbitRadius + dotRadius) * math.cos(currentAngle),
        center.dy + (orbitRadius + dotRadius) * math.sin(currentAngle),
      );
      canvas.drawCircle(offset, dotRadius, dotPaint);
      currentAngle += (dotDiameters[i] + gap) / orbitRadius;
    }
  }

  @override
  bool shouldRepaint(covariant _DateHighlightPainter oldDelegate) {
    return oldDelegate.showOrbit != showOrbit ||
        oldDelegate.showSelection != showSelection ||
        oldDelegate.color != color;
  }
}

class _EventChip extends StatelessWidget {
  final _CalendarEvent event;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _EventChip({
    required this.event,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = _eventColor(event.type);
    return ClipRRect(
      borderRadius: BorderRadius.circular(31.369),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.27, sigmaY: 6.27),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(31.369)),
            gradient: RadialGradient(
              center: Alignment(-0.1212, -0.1178),
              radius: 1.7145,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.10),
                Color.fromRGBO(255, 255, 255, 0.15),
              ],
              stops: [0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(255, 255, 255, 0.25),
                offset: Offset(2.51, 2.51),
                blurRadius: 18.822,
              ),
            ],
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 10.038, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4.211,
                height: 4.211,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6.274),
              Flexible(
                child: Text(
                  event.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pretendard Variable',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFeatures: [
                      FontFeature.tabularFigures(),
                      FontFeature.liningFigures(),
                    ],
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 8),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 4),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _eventColor(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.bill:
        return const Color(0xFFFFF4E2); // 공과금 알림
      case CalendarEventType.chore:
        return const Color(0xFFDBD1C2); // 집안일 담당
      case CalendarEventType.memo:
        return const Color(0xFF7C7C7C); // 메모
    }
  }
}

class _CalendarEvent {
  final CalendarEventType type;
  final String description;
  final int? id;
  final String? category;
  final String? assigneeName;
  final bool? isOwner;

  const _CalendarEvent(
    this.type, 
    this.description, {
    this.id,
    this.category,
    this.assigneeName,
    this.isOwner,
  });
}

enum CalendarEventType { bill, chore, memo }

/// 글래스모피즘 효과가 적용된 날짜 선택 다이얼로그
class _GlassmorphicDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _GlassmorphicDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
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
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });
    }
  }

  void _nextMonth() {
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });
    }
  }

  bool _canGoPrevious() {
    // 제한 없음 - 항상 이전 월로 이동 가능
    return true;
  }

  bool _canGoNext() {
    // 제한 없음 - 항상 다음 월로 이동 가능
    return true;
  }

  bool _isDateSelectable(DateTime date) {
    // 제한 없음 - 모든 날짜 선택 가능
    return true;
  }

  bool _isDateSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  void _selectDate(DateTime date) {
    if (_isDateSelectable(date)) {
      if (!mounted) return;
      if (mounted) {
        setState(() {
          _selectedDate = DateTime(date.year, date.month, date.day);
        });
      }
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
          maxHeight: 360,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 8),
                  // 날짜 그리드
                  SizedBox(
                    height: 160,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.8,
                        mainAxisSpacing: 0.5,
                        crossAxisSpacing: 0.5,
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
                            margin: const EdgeInsets.all(0.25),
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
                  const SizedBox(height: 8),
                  // 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.08),
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