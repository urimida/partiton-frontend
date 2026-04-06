import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:partition_app/features/partition/widgets/shared_expense_filter_chip.dart';
import 'package:partition_app/shared/widgets/frosted_panel.dart';
import 'package:partition_app/shared/widgets/glassmorphic_date_picker.dart';
import 'package:partition_app/shared/widgets/primary_button.dart';

class _BoardReservationRow {
  final String content;
  final String start;
  final String end;
  final String person;

  const _BoardReservationRow(this.content, this.start, this.end, this.person);
}

class _BoardChallengeRow {
  final String content;
  final String start;
  final String complete;
  final bool achieved;

  const _BoardChallengeRow(
    this.content,
    this.start,
    this.complete,
    this.achieved,
  );
}

List<List<T>> _paginateRows<T>(List<T> items, int pageSize) {
  if (items.isEmpty) {
    return [[]];
  }
  final pages = <List<T>>[];
  for (var i = 0; i < items.length; i += pageSize) {
    final end = i + pageSize > items.length ? items.length : i + pageSize;
    pages.add(items.sublist(i, end));
  }
  return pages;
}

/// 공용소비와 동일한 글래스·칩·표 패턴의 게시판 (예약 / 챌린지)
class PartitionBoardScreen extends StatefulWidget {
  const PartitionBoardScreen({super.key});

  @override
  State<PartitionBoardScreen> createState() => _PartitionBoardScreenState();
}

class _PartitionBoardScreenState extends State<PartitionBoardScreen> {
  static const double _headerHeight = 87.5;
  static const double _contentPaddingHorizontal = 16.0;
  static const double _contentPaddingBottom = 16.0;
  static const double _scrollBottomInsetForTabBar = 132.0;
  static const double _scrollExtraTailSpace = 56.0;
  static const double _filterChipRowHeight = 46.0;
  static const double _chipVerticalSpacingScale = 0.5;
  static const double _spacingSmall = 10.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 20.0;
  static const double _borderRadiusLarge = 32.0;
  static const double _borderRadiusSmall = 24.0;
  static const double _borderOpacity = 0.25;
  static const double _blurSigma = 10.0;
  static const int _itemsPerPage = 5;
  static const double _tablePageViewHeight = 132.0;

  int _filterIndex = 0;
  late DateTime _startDate;
  late DateTime _endDate;
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  late List<_BoardReservationRow> _reservationRows;
  late List<_BoardChallengeRow> _challengeRows;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(2024, 3, 4);
    _endDate = DateTime(2024, 5, 4);
    _reservationRows = const [
      _BoardReservationRow('욕실', '08:30', '09:00', '우진'),
      _BoardReservationRow('TV', '09:50', '11:00', '지원'),
      _BoardReservationRow('세탁기', '18:00', '19:00', '민지'),
      _BoardReservationRow('인덕션', '20:00', '20:40', '지원'),
      _BoardReservationRow('드레스룸', '21:00', '21:30', '우진'),
    ];
    _challengeRows = const [
      _BoardChallengeRow('', '', '', true),
      _BoardChallengeRow('', '', '', false),
      _BoardChallengeRow('', '', '', true),
      _BoardChallengeRow('', '', '', false),
      _BoardChallengeRow('', '', '', true),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _schedulePageJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final pages = _filterIndex == 0
            ? _paginateRows(_reservationRows, _itemsPerPage)
            : _paginateRows(_challengeRows, _itemsPerPage);
        final maxPage = pages.isEmpty ? 0 : pages.length - 1;
        final ix = _pageIndex.clamp(0, maxPage);
        _pageController.jumpToPage(ix);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}.';
  }

  Future<void> _selectDate(bool isStartDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 365));
    final selectedDate = isStartDate ? _startDate : _endDate;
    final initialDate = selectedDate.isBefore(today) ? today : selectedDate;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => GlassmorphicDatePicker(
        initialDate: initialDate,
        firstDate: today,
        lastDate: maxDate,
        isStartDate: isStartDate,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        final d = DateTime(picked.year, picked.month, picked.day);
        if (isStartDate) {
          _startDate = d;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = d;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  /// 공용소비 `_estimateMainCardContentHeightForFilter` + 하단 버튼 영역과 동일 기준으로
  /// 칩 위·아래 대칭 여백을 맞춤 (게시판만 따로 짧게 잡히면 간격이 넓어 보임)
  double _belowChipsContentHeightMatchingSharedExpense() {
    const outerPadV = 20.0 + 18.0;
    const titleBlock = 26.0 + _spacingMedium;
    const dateRowH = 52.0;
    const beforeTable = _spacingLarge;
    const tablePanel = 16.0 +
        8.0 +
        44.0 +
        8.0 +
        _tablePageViewHeight +
        4.0 +
        36.0 +
        12.0 +
        32.0;

    // 공용소비: 물품·공과금 모두 날짜 아래 정산 버튼 한 줄, 하단 액션 버튼 1개
    final cardH = outerPadV +
        titleBlock +
        dateRowH +
        (_spacingMedium + 46.0) +
        beforeTable +
        tablePanel;
    return cardH + _spacingSmall + 46 + 12;
  }

  @override
  Widget build(BuildContext context) {
    final scrollBottomPadding = _contentPaddingBottom +
        MediaQuery.viewPaddingOf(context).bottom +
        _scrollBottomInsetForTabBar +
        _scrollExtraTailSpace;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mq = MediaQuery.sizeOf(context);
              final rawH = constraints.maxHeight;
              final viewportH = (constraints.hasBoundedHeight &&
                      rawH.isFinite &&
                      rawH > 0)
                  ? rawH
                  : (mq.height -
                          _headerHeight -
                          MediaQuery.paddingOf(context).top -
                          MediaQuery.paddingOf(context).bottom -
                          150)
                      .clamp(120.0, 100000.0);
              final belowChipsContentH =
                  _belowChipsContentHeightMatchingSharedExpense();
              final band = viewportH -
                  belowChipsContentH -
                  _contentPaddingBottom;
              final symmetricPadFull =
                  band > _filterChipRowHeight ? (band - _filterChipRowHeight) / 2 : 0.0;
              final symmetricPad =
                  symmetricPadFull * _chipVerticalSpacingScale;

              return ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  _contentPaddingHorizontal,
                  0,
                  _contentPaddingHorizontal,
                  scrollBottomPadding,
                ),
                children: [
                  SizedBox(height: symmetricPad + 3),
                  _buildFilterChips(),
                  SizedBox(height: symmetricPad + 3),
                  _buildMainCard(),
                  const SizedBox(height: _spacingSmall),
                  ..._buildActionButtons(),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      height: topInset + _headerHeight,
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
              color: Colors.white.withOpacity(0.15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: topInset),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '게시판',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard Variable',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.35),
                                offset: const Offset(0, 0.5),
                                blurRadius: 2,
                              ),
                            ],
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

  Widget _buildFilterChips() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SharedExpenseFilterChip(
            label: '예약',
            selected: _filterIndex == 0,
            width: double.infinity,
            horizontalPadding: 14,
            onTap: () {
              setState(() {
                _filterIndex = 0;
                _pageIndex = 0;
              });
              _schedulePageJump();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SharedExpenseFilterChip(
            label: '챌린지',
            selected: _filterIndex == 1,
            width: double.infinity,
            horizontalPadding: 14,
            onTap: () {
              setState(() {
                _filterIndex = 1;
                _pageIndex = 0;
              });
              _schedulePageJump();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    final reservation = _filterIndex == 0;
    final pages = reservation
        ? _paginateRows(_reservationRows, _itemsPerPage)
        : _paginateRows(_challengeRows, _itemsPerPage);
    final pageSafe = _pageIndex.clamp(0, pages.length - 1).toInt();

    return FrostedPanel(
      borderRadius: BorderRadius.circular(_borderRadiusLarge),
      backgroundOpacity: 0.0,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: Text(
                reservation ? '예약 관리' : '챌린지 관리',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Pretendard Variable',
                  height: 1.2,
                  letterSpacing: -0.15,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.28),
                      offset: const Offset(0, 0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: _spacingMedium),
          if (reservation) ...[
            _buildDateRangeGlassRow(),
          ],
          const SizedBox(height: _spacingLarge),
          FrostedPanel(
            borderRadius: BorderRadius.circular(20),
            backgroundOpacity: 0.0,
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTableHeader(reservation: reservation),
                const SizedBox(height: 8),
                SizedBox(
                  height: _tablePageViewHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const PageScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    itemCount: pages.length,
                    itemBuilder: (context, pageIndex) {
                      if (reservation) {
                        return _buildReservationPage(
                          pages[pageIndex] as List<_BoardReservationRow>,
                        );
                      }
                      return _buildChallengePage(
                        pages[pageIndex] as List<_BoardChallengeRow>,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                _buildPageControl(
                  pageCount: pages.length,
                  currentIndex: pageSafe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeGlassRow() {
    const labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard Variable',
    );
    const dateStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Pretendard Variable',
    );

    return FrostedPanel(
      borderRadius: BorderRadius.circular(_borderRadiusSmall),
      backgroundOpacity: 0.08,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildDateSegment(
                label: '시작일',
                date: _formatDate(_startDate),
                isStart: true,
                labelStyle: labelStyle,
                dateStyle: dateStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            Expanded(
              child: _buildDateSegment(
                label: '종료일',
                date: _formatDate(_endDate),
                isStart: false,
                labelStyle: labelStyle,
                dateStyle: dateStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSegment({
    required String label,
    required String date,
    required bool isStart,
    required TextStyle labelStyle,
    required TextStyle dateStyle,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectDate(isStart),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                date,
                style: dateStyle,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 12,
    height: 1.35,
  );

  static const TextStyle _cellStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  Widget _buildTableHeader({required bool reservation}) {
    const headerRowHeight = 34.0;
    const pad = 6.0;

    List<Widget> cells(List<String> labels, List<int> flexes) {
      final w = <Widget>[];
      for (var i = 0; i < labels.length; i++) {
        if (i > 0) w.add(const SizedBox(width: 4));
        w.add(
          Expanded(
            flex: flexes[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding:
                    const EdgeInsets.symmetric(horizontal: pad, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        style: _headerStyle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return w;
    }

    final labels = reservation
        ? ['내용', '예약 시간', '종료 시간', '예약자']
        : ['내용', '시작', '완료', '달성 여부'];
    final flexes = reservation ? [3, 3, 3, 2] : [3, 2, 2, 2];

    return SizedBox(
      height: headerRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: cells(labels, flexes),
      ),
    );
  }

  Widget _buildReservationPage(List<_BoardReservationRow> rows) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          '예약 내역이 없습니다',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final r in rows) _buildReservationRow(r),
      ],
    );
  }

  Widget _buildReservationRow(_BoardReservationRow r) {
    // 공용소비 표 데이터 행과 동일: 셀마다 FrostedPanel·스트로크 없음, 패딩만
    const padContent = 6.0;
    const padTime = 4.0;
    const padPerson = 4.0;

    Widget fittedCell(String text) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: _cellStyle,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padContent),
              child: Text(
                r.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _cellStyle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padTime),
              child: Center(
                child: Text(
                  r.start,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: _cellStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padTime),
              child: Center(
                child: Text(
                  r.end,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: _cellStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padPerson),
              child: fittedCell(r.person),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengePage(List<_BoardChallengeRow> rows) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          '챌린지가 없습니다',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final r in rows) _buildChallengeRow(r),
      ],
    );
  }

  Widget _buildChallengeRow(_BoardChallengeRow r) {
    const padContent = 6.0;
    const padRest = 4.0;

    Widget fittedCell(String text, {required bool placeholder}) {
      final style = _cellStyle.copyWith(
        color: placeholder
            ? Colors.white.withOpacity(0.35)
            : Colors.white,
      );
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      );
    }

    final contentEmpty = r.content.isEmpty;
    final startEmpty = r.start.isEmpty;
    final completeEmpty = r.complete.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padContent),
              child: Text(
                contentEmpty ? '—' : r.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _cellStyle.copyWith(
                  color: contentEmpty
                      ? Colors.white.withOpacity(0.35)
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padRest),
              child: fittedCell(
                startEmpty ? '—' : r.start,
                placeholder: startEmpty,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padRest),
              child: fittedCell(
                completeEmpty ? '—' : r.complete,
                placeholder: completeEmpty,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padRest),
              child: Center(
                child: Icon(
                  r.achieved
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: r.achieved
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageControl({
    required int pageCount,
    required int currentIndex,
  }) {
    void goPrev() {
      if (currentIndex <= 0) return;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    void goNext() {
      if (currentIndex >= pageCount - 1) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    final canPrev = pageCount > 1 && currentIndex > 0;
    final canNext = pageCount > 1 && currentIndex < pageCount - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleArrow(Icons.chevron_left, enabled: canPrev, onTap: goPrev),
        if (pageCount > 1) ...[
          const SizedBox(width: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(pageCount, (i) {
              final active = i == currentIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withOpacity(active ? 0.95 : 0.35),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 14),
        ] else
          const SizedBox(width: 16),
        _circleArrow(Icons.chevron_right, enabled: canNext, onTap: goNext),
      ],
    );
  }

  Widget _circleArrow(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    if (_filterIndex == 0) {
      return [
        PrimaryButton(
          label: '예약하기',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('예약하기 (준비 중)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: _spacingSmall),
        PrimaryButton(
          label: '예약 내역 확인하기',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('예약 내역 확인 (준비 중)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ];
    }
    return [
      PrimaryButton(
        label: '챌린지 추가하기',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지 추가 (준비 중)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    ];
  }
}
