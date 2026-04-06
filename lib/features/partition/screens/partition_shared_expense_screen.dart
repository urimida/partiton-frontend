import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';
import 'package:partition_app/features/partition/widgets/shared_expense_filter_chip.dart';
import 'package:partition_app/features/partition/widgets/shared_expense_manual_modal.dart';
import 'package:partition_app/features/partition/widgets/utility_bill_add_modal.dart';
import 'package:partition_app/features/partition/widgets/shared_expense_item_detail_sheet.dart';
import 'package:partition_app/shared/widgets/frosted_panel.dart';
import 'package:partition_app/shared/widgets/glassmorphic_date_picker.dart';
import 'package:partition_app/shared/widgets/primary_button.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';

class PartitionSharedExpenseScreen extends StatefulWidget {
  const PartitionSharedExpenseScreen({super.key});

  @override
  State<PartitionSharedExpenseScreen> createState() =>
      _PartitionSharedExpenseScreenState();
}

class _PartitionSharedExpenseScreenState
    extends State<PartitionSharedExpenseScreen> {
  // Constants — 본문 영역 높이(상태줄 제외). 기존 125의 약 0.7로 얇게.
  static const double _headerHeight = 87.5;
  static const double _contentPaddingHorizontal = 16.0;
  static const double _contentPaddingBottom = 16.0;
  /// 하단 글래스 탭바 등이 본문과 겹칠 때 스크롤로 버튼까지 닿게 하기 위한 추가 여백
  static const double _scrollBottomInsetForTabBar = 132.0;
  /// 스크롤 끝에서 탭바·손가락 여유까지 더 내릴 수 있게 하는 추가 하단 공간
  static const double _scrollExtraTailSpace = 56.0;
  /// 물품/공과금 칩 한 줄 높이(패딩 포함 추정) — 대칭 간격 계산용
  static const double _filterChipRowHeight = 46.0;
  /// 헤더↔물품·공과금 칩, 칩↔표 카드 세로 간격만 축소 (1.0 = 기존 중앙 배치)
  static const double _chipVerticalSpacingScale = 0.5;
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

  /// 표 데이터 (수동 추가·수정 반영)
  /// 필드에서 즉시 초기화 — `late`+initState만 쓰면 핫 리로드 시 LateInitializationError
  List<SharedExpenseTableItem> _goodsExpenseItems =
      List<SharedExpenseTableItem>.from(_dummyItemsForSharedExpenseTable(0));
  List<SharedExpenseTableItem> _utilityExpenseItems =
      List<SharedExpenseTableItem>.from(_dummyItemsForSharedExpenseTable(1));

  /// 표는 세로 스크롤 대신 좌우 페이지로 넘김
  /// (필드에서 즉시 초기화: 핫 리로드 시 initState가 다시 안 돌아 late 미초기화 방지)
  final PageController _tablePageController = PageController();
  int _tablePageIndex = 0;

  /// 수동 정산 반영: 여러 행 선택 모드 (연필 반대 버튼으로 진입)
  bool _tableSelectionMode = false;
  final Set<int> _selectedRowIndices = <int>{};

  static const int _tableItemsPerPage = 5;
  /// 표 `PageView` 세로 고정 높이 — 행은 `spaceBetween`으로 이 안에서 간격 분배
  static const double _tablePageViewHeightFixed = 132.0;

  double get _tablePageViewHeight => _tablePageViewHeightFixed;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 4);
    _endDate = DateTime(now.year, now.month, 4);
  }

  List<SharedExpenseTableItem> _itemsForCurrentFilter() =>
      _filterIndex == 0 ? _goodsExpenseItems : _utilityExpenseItems;

  void _clampTablePageIndex() {
    final pages = _paginateSharedExpenseItems(
      _itemsForCurrentFilter(),
      _tableItemsPerPage,
    );
    final maxPage = pages.isEmpty ? 0 : pages.length - 1;
    if (_tablePageIndex > maxPage) {
      _tablePageIndex = maxPage;
    }
  }

  void _scheduleTablePageJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tablePageController.hasClients) {
        final pages = _paginateSharedExpenseItems(
          _itemsForCurrentFilter(),
          _tableItemsPerPage,
        );
        final maxPage = pages.isEmpty ? 0 : pages.length - 1;
        final ix = _tablePageIndex.clamp(0, maxPage);
        _tablePageController.jumpToPage(ix);
      }
    });
  }

  void _showManualSharedExpenseModal() {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => SharedExpenseManualModal(
        isUtility: _filterIndex == 1,
        initialItems: List<SharedExpenseTableItem>.from(_itemsForCurrentFilter()),
        onApply: (next) {
          setState(() {
            if (_filterIndex == 0) {
              _goodsExpenseItems = next;
            } else {
              _utilityExpenseItems = next;
            }
            _clampTablePageIndex();
          });
          _scheduleTablePageJump();
        },
      ),
    ).then((applied) {
      if (applied == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _filterIndex == 1
                  ? '공과금 내역을 반영했어요.'
                  : '공용 소비 내역을 반영했어요.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showItemDetailSheet(SharedExpenseTableItem item, int globalIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => SharedExpenseItemDetailSheet(
        item: item,
        isUtility: _filterIndex == 1,
        onSettlementChanged: (v) {
          setState(() {
            final list =
                List<SharedExpenseTableItem>.from(_itemsForCurrentFilter());
            if (globalIndex >= 0 && globalIndex < list.length) {
              list[globalIndex] =
                  list[globalIndex].copyWith(manuallySettled: v);
              if (_filterIndex == 0) {
                _goodsExpenseItems = list;
              } else {
                _utilityExpenseItems = list;
              }
            }
          });
        },
      ),
    );
  }

  void _showUtilityBillAddModal() {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => UtilityBillAddModal(
        existingItemNames: _utilityExpenseItems.map((e) => e.name).toSet(),
        onConfirm: (added) {
          setState(() {
            _utilityExpenseItems = [..._utilityExpenseItems, ...added];
            _clampTablePageIndex();
          });
          _scheduleTablePageJump();
        },
      ),
    ).then((ok) {
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공과금을 표에 추가했어요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tablePageController.dispose();
    super.dispose();
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
      builder: (context) => GlassmorphicDatePicker(
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

  /// 메인 글래스 카드(제목~표~페이지) — HUG 레이아웃에 맞춘 대략 높이 (칩 간격 계산용)
  double _estimateMainCardContentHeightForFilter(int _) {
    const outerPadV = 20.0 + 18.0;
    const titleBlock = 26.0 + _spacingMedium;
    const dateRowH = 52.0;
    // 물품·공과금 모두 날짜 아래에 정산하기 버튼 한 줄 (동일 높이)
    const settlementButtonBlock = _spacingMedium + 46.0;
    const beforeTable = _spacingLarge;
    // 표 패널 + 페이지 컨트롤 + 표 바깥(오른쪽) 추가·수정 원형 줄
    const tablePanel = 16.0 +
        8.0 +
        44.0 +
        8.0 +
        _tablePageViewHeightFixed +
        4.0 +
        36.0 +
        12.0 +
        32.0;
    return outerPadV +
        titleBlock +
        dateRowH +
        settlementButtonBlock +
        beforeTable +
        tablePanel;
  }

  /// 칩 아래(카드+하단 버튼) 고정 블록 높이 — 칩 위·아래 대칭 여백 계산용
  /// 정산하기는 카드 안(날짜 아래) / 하단 액션은 탭당 버튼 1개
  double _estimatedBelowChipsContentHeightForFilter(int filterIndex) {
    final cardH = _estimateMainCardContentHeightForFilter(filterIndex);
    final actionCount = 1;
    final actionsH =
        46 * actionCount + _spacingSmall * (actionCount > 1 ? actionCount - 1 : 0);
    return cardH + _spacingSmall + actionsH + 12;
  }

  @override
  Widget build(BuildContext context) {
    final scrollBottomPadding = _contentPaddingBottom +
        MediaQuery.viewPaddingOf(context).bottom +
        _scrollBottomInsetForTabBar +
        _scrollExtraTailSpace;

    // 패턴: Column(헤더 고정) + Expanded(남은 높이) + ListView — 스크롤 안에 Expanded 넣지 않음
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 제약이 비정상이면(무한 높이·0 등) 본문 전체가 사라지지 않도록 화면 기준으로 대체.
              // 부모 변경·탭 전환 등으로 `LayoutBuilder`만 유한 높이를 못 받는 경우가 있음.
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
              // 물품/공과금 전환 시 칩이 위아래로 움직이지 않도록, 더 큰 쪽 레이아웃 높이로만 여백 계산
              final hGoods = _estimatedBelowChipsContentHeightForFilter(0);
              final hUtility = _estimatedBelowChipsContentHeightForFilter(1);
              final belowChipsContentH =
                  hGoods > hUtility ? hGoods : hUtility;
              final band = viewportH -
                  belowChipsContentH -
                  _contentPaddingBottom;
              final symmetricPadFull = band > _filterChipRowHeight
                  ? (band - _filterChipRowHeight) / 2
                  : 0.0;
              final symmetricPad =
                  symmetricPadFull * _chipVerticalSpacingScale;

              return ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              color: Colors.white.withOpacity(0.15), // 하단바(0.4)보다 투명하지만 현재보다 불투명
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
                          '공용소비',
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
    // 표·모달 인풋과 동일한 가로 폭(스크롤 패딩 안에서 전체 너비)으로 1:1 분할
    // ListView/SliverList 자식은 세로 max가 무한 → Row.stretch는 무한 높이 제약과 충돌
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SharedExpenseFilterChip(
            label: '물품',
            selected: _filterIndex == 0,
            width: double.infinity,
            horizontalPadding: 14,
            onTap: () {
              setState(() {
                _filterIndex = 0;
                _tablePageIndex = 0;
                _tableSelectionMode = false;
                _selectedRowIndices.clear();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_tablePageController.hasClients) {
                  _tablePageController.jumpToPage(0);
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SharedExpenseFilterChip(
            label: '공과금',
            selected: _filterIndex == 1,
            width: double.infinity,
            horizontalPadding: 14,
            onTap: () {
              setState(() {
                _filterIndex = 1;
                _tablePageIndex = 0;
                _tableSelectionMode = false;
                _selectedRowIndices.clear();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_tablePageController.hasClients) {
                  _tablePageController.jumpToPage(0);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  /// 바깥 카드 높이는 내용에 맞춤(HUG). `Expanded` 없음 → 스크롤 `Column` 안에서 안전
  Widget _buildMainCard() {
    final isUtility = _filterIndex == 1;
    final tablePages = _paginateSharedExpenseItems(
      _itemsForCurrentFilter(),
      _tableItemsPerPage,
    );
    final tablePageIndexSafe =
        _tablePageIndex.clamp(0, tablePages.length - 1).toInt();
    final selectionAllSettled = _selectedRowsAreAllSettled();

    return FrostedPanel(
      borderRadius: BorderRadius.circular(_borderRadiusLarge),
      backgroundOpacity: 0.0,
      // 14+6(제목만)=20 — 날짜·시작·종료 줄과 표가 같은 폭으로 조금 더 넓게
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: Text(
                isUtility ? '공용 소비 공과금 관리' : '공용 소비 물품 관리',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
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
          _buildDateRangeGlassRow(),
          if (isUtility) ...[
            const SizedBox(height: _spacingMedium),
            PrimaryButton(
              label: '공과금 정산하기',
              enabled: !_tableSelectionMode,
              onPressed: _showUtilityBillSettlementFlow,
            ),
          ] else ...[
            const SizedBox(height: _spacingMedium),
            PrimaryButton(
              label: '공용 소비 물품 정산하기',
              enabled: !_tableSelectionMode,
              onPressed: _showSharedExpenseSettlementFlow,
            ),
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
                _buildTableHeader(selectionMode: _tableSelectionMode),
                const SizedBox(height: 8),
                SizedBox(
                  height: _tablePageViewHeight,
                  child: PageView.builder(
                    controller: _tablePageController,
                    physics: const PageScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    onPageChanged: (i) {
                      setState(() => _tablePageIndex = i);
                    },
                    itemCount: tablePages.length,
                    itemBuilder: (context, pageIndex) {
                      return _SharedExpenseTableBody(
                        filterIndex: _filterIndex,
                        items: tablePages[pageIndex],
                        onNameTap: _showItemDetailSheet,
                        selectionMode: _tableSelectionMode,
                        pageIndex: pageIndex,
                        itemsPerPage: _tableItemsPerPage,
                        selectedIndices: _selectedRowIndices,
                        onToggleRow: _toggleRowSelection,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                _buildPageControl(
                  pageCount: tablePages.length,
                  currentIndex: tablePageIndexSafe,
                ),
              ],
            ),
          ),
          // 표 아래: 왼쪽 = 선택 모드 진입·종료, 오른쪽 = 편집 또는 전체선택·삭제·정산 표시
          // 가로 패딩은 표 FrostedPanel(6)과 같게 — 오른쪽 끝 버튼이 표 수량 열과 세로 정렬
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: _tableSelectionMode
                      ? '선택 종료'
                      : '여러 항목 선택 후 정산 완료 표시·삭제',
                  child: _buildCircleArrow(
                    _tableSelectionMode
                        ? Icons.close_rounded
                        : Icons.playlist_add_check_rounded,
                    onTap: _tableSelectionMode
                        ? _exitTableSelectionMode
                        : _enterTableSelectionMode,
                  ),
                ),
                const Spacer(),
                if (!_tableSelectionMode)
                  Tooltip(
                    message: isUtility ? '공과금 내역 관리' : '공용 소비 내역 관리',
                    child: _buildCircleArrow(
                      Icons.edit_rounded,
                      onTap: _showManualSharedExpenseModal,
                    ),
                  )
                else
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildSelectionActionChip(
                            '전체선택',
                            _selectAllRowsInFilter,
                          ),
                          const SizedBox(width: 6),
                          _buildSelectionActionChip(
                            '삭제',
                            () => _deleteSelectedRows(),
                          ),
                          const SizedBox(width: 6),
                          _buildSelectionActionChip(
                            selectionAllSettled
                                ? '정산 해제하기'
                                : '정산 표시하기',
                            selectionAllSettled
                                ? _cancelSettlementSelectedRows
                                : _settleSelectedRows,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final isUtility = _filterIndex == 1;
    
    if (isUtility) {
      return [
        PrimaryButton(
          label: '공과금 추가하기',
          onPressed: _showUtilityBillAddModal,
        ),
      ];
    } else {
      return [
        PrimaryButton(
          label: '파티션 AI 영수증 인식',
          onPressed: _showAiReceiptRecognitionFlow,
        ),
      ];
    }
  }

  /// 시작일·종료일을 한 줄에 두고, 카드·칩과 동일한 글래스 패널로 감쌈
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
              child: _buildDateInlineSegment(
                label: '시작일',
                date: _formatDate(_startDate),
                isStartDate: true,
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
              child: _buildDateInlineSegment(
                label: '종료일',
                date: _formatDate(_endDate),
                isStartDate: false,
                labelStyle: labelStyle,
                dateStyle: dateStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInlineSegment({
    required String label,
    required String date,
    required bool isStartDate,
    required TextStyle labelStyle,
    required TextStyle dateStyle,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectDate(isStartDate),
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

  Widget _buildTableHeader({required bool selectionMode}) {
    // 데이터 행과 동일 fontSize·height (굵기만 헤더 강조) — 살짝 축소해 날짜·금액·수량 한 줄 표시
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 12,
      height: 1.35,
    );

    final isUtility = _filterIndex == 1;
    final lastHeaderLabel = isUtility ? '비고' : '수량';
    // 공과금: 항목명 짧음·비고 넓음. 물품: 내용 폭 축소·날짜(YY.MM.DD.) 폭 확대
    const contentFlex = 4;
    final dateFlex = isUtility ? 2 : 3;
    final lastColFlex = isUtility ? 3 : 2;

    // 내용 : 날짜 : 금액 : 마지막열
    const padContent = 4.0;
    const padDate = 3.0;
    const padAmount = 3.0;
    const padQty = 3.0;

    const headerRowHeight = 34.0;
    return SizedBox(
      height: headerRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 선택 모드에서도 행 체크박스 열 너비만 맞추고, 상단 체크 레이블은 표시하지 않음
          if (selectionMode) ...[
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 3),
          ],
          Expanded(
            flex: contentFlex,
            child: Padding(
              // 표 제목 캡슐만 좌우 1px씩 좁게 (데이터 행과 동일 레이아웃 유지)
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: padContent, vertical: 6),
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Center(
                    child: Text(
                      '내용',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: dateFlex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: padDate, vertical: 6),
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Center(
                    child: Text(
                      '날짜',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: padAmount, vertical: 6),
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Center(
                    child: Text(
                      '금액',
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: lastColFlex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FrostedPanel(
                borderRadius: BorderRadius.circular(20),
                backgroundOpacity: 0.4,
                padding: const EdgeInsets.symmetric(horizontal: padQty, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        lastHeaderLabel,
                        style: headerStyle,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
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
      _tablePageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    void goNext() {
      if (currentIndex >= pageCount - 1) return;
      _tablePageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    final canPrev = pageCount > 1 && currentIndex > 0;
    final canNext = pageCount > 1 && currentIndex < pageCount - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleArrow(
          Icons.chevron_left,
          enabled: canPrev,
          onTap: canPrev ? goPrev : null,
        ),
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
        _buildCircleArrow(
          Icons.chevron_right,
          enabled: canNext,
          onTap: canNext ? goNext : null,
        ),
      ],
    );
  }

  Widget _buildCircleArrow(
    IconData icon, {
    VoidCallback? onTap,
    bool enabled = true,
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
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 선택 모드 — 텍스트 너비에 맞춘 작은 글래스 pill (한 줄 배치용, FrostedPanel 무한 너비 방지)
  Widget _buildSelectionActionChip(String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.06),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enterTableSelectionMode() {
    setState(() {
      _tableSelectionMode = true;
      _selectedRowIndices.clear();
    });
  }

  void _exitTableSelectionMode() {
    setState(() {
      _tableSelectionMode = false;
      _selectedRowIndices.clear();
    });
  }

  void _toggleRowSelection(int globalIndex) {
    setState(() {
      if (_selectedRowIndices.contains(globalIndex)) {
        _selectedRowIndices.remove(globalIndex);
      } else {
        _selectedRowIndices.add(globalIndex);
      }
    });
  }

  void _selectAllRowsInFilter() {
    setState(() {
      final n = _itemsForCurrentFilter().length;
      _selectedRowIndices.clear();
      for (var i = 0; i < n; i++) {
        _selectedRowIndices.add(i);
      }
    });
  }

  Future<void> _deleteSelectedRows() async {
    if (_selectedRowIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 항목을 선택해주세요.')),
      );
      return;
    }
    final count = _selectedRowIndices.length;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '선택한 $count개 항목을 삭제할까요?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      final list = List<SharedExpenseTableItem>.from(_itemsForCurrentFilter());
      final sorted = _selectedRowIndices.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final i in sorted) {
        if (i >= 0 && i < list.length) list.removeAt(i);
      }
      if (_filterIndex == 0) {
        _goodsExpenseItems = list;
      } else {
        _utilityExpenseItems = list;
      }
      _selectedRowIndices.clear();
      _clampTablePageIndex();
    });
    _scheduleTablePageJump();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 항목을 삭제했어요.')),
      );
    }
  }

  /// 선택이 비어 있지 않고, 모두 정산 완료(`manuallySettled`)인 경우에만 true — 버튼을「정산 해제하기」로 쓸 때
  bool _selectedRowsAreAllSettled() {
    if (_selectedRowIndices.isEmpty) return false;
    final list = _itemsForCurrentFilter();
    for (final i in _selectedRowIndices) {
      if (i < 0 || i >= list.length) return false;
      if (!list[i].manuallySettled) return false;
    }
    return true;
  }

  void _settleSelectedRows() {
    if (_selectedRowIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 항목을 선택해주세요.')),
      );
      return;
    }
    final count = _selectedRowIndices.length;
    setState(() {
      final list = List<SharedExpenseTableItem>.from(_itemsForCurrentFilter());
      for (final i in _selectedRowIndices) {
        if (i >= 0 && i < list.length) {
          list[i] = list[i].copyWith(manuallySettled: true);
        }
      }
      if (_filterIndex == 0) {
        _goodsExpenseItems = list;
      } else {
        _utilityExpenseItems = list;
      }
      _selectedRowIndices.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('선택한 $count개 항목을 정산 완료로 표시했어요.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelSettlementSelectedRows() {
    if (_selectedRowIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 항목을 선택해주세요.')),
      );
      return;
    }
    final count = _selectedRowIndices.length;
    setState(() {
      final list = List<SharedExpenseTableItem>.from(_itemsForCurrentFilter());
      for (final i in _selectedRowIndices) {
        if (i >= 0 && i < list.length) {
          list[i] = list[i].copyWith(manuallySettled: false);
        }
      }
      if (_filterIndex == 0) {
        _goodsExpenseItems = list;
      } else {
        _utilityExpenseItems = list;
      }
      _selectedRowIndices.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('선택한 $count개 항목의 정산 완료 표시를 해제했어요.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// AI 영수증 인식 — 촬영(가상) → 분석 확인 → 추출 내용 (카메라 연동 전 더미 플로우)
  Future<void> _showAiReceiptRecognitionFlow() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const _AiReceiptRecognitionFlowDialog(),
    );
  }

  /// 공용 소비 물품 정산 — 항목 선택 → 정산할 인원 선택 (더미)
  Future<void> _showSharedExpenseSettlementFlow() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const _SharedExpenseSettlementFlowDialog(),
    );
  }

  /// 공과금 정산 — 기간·항목 선택(페이지) → 1인당 금액
  Future<void> _showUtilityBillSettlementFlow() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => _UtilityBillSettlementFlowDialog(
        items: List<SharedExpenseTableItem>.from(_utilityExpenseItems),
      ),
    );
  }
}

class _SharedExpenseTableBody extends StatelessWidget {
  /// 표 데이터 행 — 동일 TextStyle; 날짜만 고정 크기, 금액·수량은 길면 FittedBox로 맞춤
  static const TextStyle _cellTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  final int filterIndex;
  final List<SharedExpenseTableItem> items;
  final void Function(SharedExpenseTableItem item, int globalIndex) onNameTap;
  final bool selectionMode;
  final int pageIndex;
  final int itemsPerPage;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggleRow;

  const _SharedExpenseTableBody({
    required this.filterIndex,
    required this.items,
    required this.onNameTap,
    required this.selectionMode,
    required this.pageIndex,
    required this.itemsPerPage,
    required this.selectedIndices,
    required this.onToggleRow,
  });

  @override
  Widget build(BuildContext context) {
    final isUtility = filterIndex == 1;

    if (items.isEmpty) {
      return Center(
        child: Text(
          '내역이 없습니다',
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
        for (var index = 0; index < items.length; index++)
          _buildItemRow(
            context,
            isUtility,
            items[index],
            pageIndex * itemsPerPage + index,
          ),
      ],
    );
  }

  TextStyle _styleFor(SharedExpenseTableItem item) {
    if (!item.manuallySettled) return _cellTextStyle;
    return _cellTextStyle.copyWith(
      color: Colors.white.withOpacity(0.55),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    bool isUtility,
    SharedExpenseTableItem item,
    int globalIndex,
  ) {
    // 내용 열: 카테고리 제외 실제 품목명만 (분류는 상세 시트에서)
    final label = item.name;
    final rowStyle = _styleFor(item);

    // 헤더 셀과 동일한 가로 패딩·flex (_buildTableHeader와 맞출 것)
    const padContent = 4.0;
    const padDate = 3.0;
    const padAmount = 3.0;
    const padQty = 3.0;
    const contentFlex = 4;
    final dateFlex = isUtility ? 2 : 3;
    final lastColFlex = isUtility ? 3 : 2;

    /// 물품 품목명: 6자 초과 시 앞 6자 + … (공과금은 전체 표시용 FittedBox)
    final displayName = !isUtility && label.length > 6
        ? '${label.substring(0, 6)}...'
        : label;

    /// 금액·수량 등 긴 문자열용 (날짜는 축소 없이 고정 글자 크기)
    Widget fittedCell(String text, TextStyle style) {
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

    Widget row = Padding(
      padding: EdgeInsets.symmetric(vertical: selectionMode ? 1 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (selectionMode) ...[
            Expanded(
              flex: 1,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Transform.scale(
                    scale: 0.82,
                    alignment: Alignment.center,
                    child: Checkbox(
                      value: selectedIndices.contains(globalIndex),
                      onChanged: (_) => onToggleRow(globalIndex),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.65),
                        width: 1.0,
                      ),
                      fillColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.transparent;
                      }),
                      checkColor: const Color(0xFF2A2A2A),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
          ],
          Expanded(
            flex: contentFlex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padContent),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onNameTap(item, globalIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    child: isUtility
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: rowStyle,
                            ),
                          )
                        : Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: rowStyle,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: dateFlex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padDate),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    item.date,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: rowStyle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padAmount),
              child: fittedCell(item.amount, rowStyle),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: lastColFlex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: padQty),
              child: fittedCell(
                isUtility ? (item.quantity ?? '—') : (item.quantity ?? ''),
                rowStyle,
              ),
            ),
          ),
        ],
      ),
    );

    return row;
  }
}

List<SharedExpenseTableItem> _dummyItemsForSharedExpenseTable(int filterIndex) {
  final isUtility = filterIndex == 1;
  if (isUtility) {
    return [
      const SharedExpenseTableItem(
          name: '월세', date: '6일 뒤', amount: '60만원', quantity: '고정'),
      const SharedExpenseTableItem(
          name: '수도세',
          date: '10일 뒤',
          amount: '알 수 없음',
          quantity: '후불'),
      const SharedExpenseTableItem(
          name: '전기세',
          date: '15일 뒤',
          amount: '45,000원',
          quantity: '자동이체'),
      const SharedExpenseTableItem(
          name: '가스세',
          date: '20일 뒤',
          amount: '30,000원',
          quantity: '자동이체'),
      const SharedExpenseTableItem(
          name: '관리비', date: '12일 뒤', amount: '15만원', quantity: '고정'),
      const SharedExpenseTableItem(
          name: '인터넷',
          date: '8일 뒤',
          amount: '33,000원',
          quantity: '자동이체'),
      const SharedExpenseTableItem(
          name: 'TV 수신료',
          date: '1일 뒤',
          amount: '2,500원',
          quantity: '자동이체'),
      const SharedExpenseTableItem(
          name: '건물 보험',
          date: '25일 뒤',
          amount: '12,000원',
          quantity: '연납'),
      const SharedExpenseTableItem(
          name: '주차비', date: '5일 뒤', amount: '50,000원', quantity: '고정'),
      const SharedExpenseTableItem(
          name: '공용 전기',
          date: '18일 뒤',
          amount: '8,200원',
          quantity: '후불'),
    ];
  }
  return [
    const SharedExpenseTableItem(
        name: '콘푸라이트 500g',
        date: '25.05.04.',
        amount: '5,980원',
        quantity: '3개'),
    const SharedExpenseTableItem(
        name: '두루마리 휴지',
        date: '25.05.05.',
        amount: '8,000원',
        quantity: '3개',
        majorCategory: '욕실용품',
        minorCategory: '휴지'),
    const SharedExpenseTableItem(
        name: '10W 충전기',
        date: '25.05.14.',
        amount: '9,000원',
        quantity: '2개'),
    const SharedExpenseTableItem(
        name: '그래놀라 450g',
        date: '25.05.16.',
        amount: '12,000원',
        quantity: '3개'),
    const SharedExpenseTableItem(
        name: '인덕션용 냄비',
        date: '25.05.17.',
        amount: '20,000원',
        quantity: '1개'),
    const SharedExpenseTableItem(
        name: '커피 원두 1kg',
        date: '25.05.18.',
        amount: '18,500원',
        quantity: '2개'),
    const SharedExpenseTableItem(
        name: '주방 세제 세트',
        date: '25.05.19.',
        amount: '6,400원',
        quantity: '1개'),
    const SharedExpenseTableItem(
        name: '라면 5입 묶음',
        date: '25.05.20.',
        amount: '4,200원',
        quantity: '4개'),
    const SharedExpenseTableItem(
        name: '우유 900ml',
        date: '25.05.21.',
        amount: '3,100원',
        quantity: '5개'),
    const SharedExpenseTableItem(
        name: '계란 30구',
        date: '25.05.22.',
        amount: '7,800원',
        quantity: '2개'),
  ];
}

/// 한 페이지에 `pageSize`개씩 나눔. 빈 목록이면 빈 페이지 1장.
List<List<SharedExpenseTableItem>> _paginateSharedExpenseItems(
  List<SharedExpenseTableItem> items,
  int pageSize,
) {
  if (items.isEmpty) {
    return [[]];
  }
  final pages = <List<SharedExpenseTableItem>>[];
  for (var i = 0; i < items.length; i += pageSize) {
    final end = i + pageSize > items.length ? items.length : i + pageSize;
    pages.add(items.sublist(i, end));
  }
  return pages;
}

/// 추가/확인/AI 모달에서 재사용하는 글래스 다이얼로그 프레임
class _SharedGlassDialogShell extends StatelessWidget {
  final Widget child;
  final BoxConstraints constraints;

  const _SharedGlassDialogShell({
    required this.child,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: constraints,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 0.5),
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
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatKrwSettlement(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

double _settlementMemberAmountFieldWidth({
  required String digits,
  required TextStyle style,
}) {
  final t = digits.isEmpty ? '0' : digits;
  final painter = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  // 컨테이너 좌우 패딩(4+4) + 필드 안쪽(2+2) + 커서 여유
  const extra = 14.0;
  return (painter.size.width + extra).clamp(24.0, 128.0);
}

/// 정산 멤버 행 오른쪽: 숫자만 입력, `원`은 필드 밖 고정, 폭은 글자에 맞춤
Widget _buildSettlementMemberAmountTrailing({
  required TextEditingController controller,
  required bool selected,
  required VoidCallback onAmountChanged,
}) {
  final amountStyle = TextStyle(
    color: selected ? Colors.white : Colors.white.withOpacity(0.45),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Pretendard Variable',
    height: 1.05,
  );
  final hintStyle = TextStyle(
    color: Colors.white.withOpacity(0.35),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Pretendard Variable',
    height: 1.05,
  );
  final w = _settlementMemberAmountFieldWidth(
    digits: controller.text,
    style: amountStyle,
  );

  return Expanded(
    child: Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(selected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(selected ? 0.45 : 0.22),
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: selected,
                onChanged: (_) => onAmountChanged(),
                textAlign: TextAlign.right,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: amountStyle,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  hintText: selected ? null : '0',
                  hintStyle: hintStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '원',
            style: TextStyle(
              color: selected
                  ? Colors.white.withOpacity(0.95)
                  : Colors.white.withOpacity(0.4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard Variable',
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettlementSelectableLine {
  final String name;
  final int amountWon;
  bool selected;

  _SettlementSelectableLine({
    required this.name,
    this.amountWon = 0,
    this.selected = true,
  });
}

/// 공용 소비 물품 정산: 기간·항목 선택 → 정산할 인원 선택 → 완료 모달
class _SharedExpenseSettlementFlowDialog extends StatefulWidget {
  const _SharedExpenseSettlementFlowDialog();

  @override
  State<_SharedExpenseSettlementFlowDialog> createState() =>
      _SharedExpenseSettlementFlowDialogState();
}

class _SharedExpenseSettlementFlowDialogState
    extends State<_SharedExpenseSettlementFlowDialog> {
  /// 0: 항목 선택, 1: 정산할 인원
  int _step = 0;

  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late final List<_SettlementSelectableLine> _lines;

  List<String> _memberNames = [];
  List<bool> _memberSelected = [];
  final List<TextEditingController> _memberAmountCtrls = [];
  bool _loadingMembers = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _rangeStart = DateTime(2025, 8, 15);
    _rangeEnd = DateTime(2025, 8, 15);
    _lines = [
      _SettlementSelectableLine(name: '콘프로스트', amountWon: 12000),
      _SettlementSelectableLine(name: '생과일요거트', amountWon: 8000),
      _SettlementSelectableLine(name: '멀티탭', amountWon: 6000),
    ];
    _loadMembers();
  }

  @override
  void dispose() {
    for (final c in _memberAmountCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureMemberAmountControllers() {
    while (_memberAmountCtrls.length < _memberNames.length) {
      _memberAmountCtrls.add(TextEditingController());
    }
    while (_memberAmountCtrls.length > _memberNames.length) {
      _memberAmountCtrls.removeLast().dispose();
    }
  }

  void _syncMemberAmountFields() {
    _ensureMemberAmountControllers();
    final per = _getGoodsPerPersonWon();
    for (var i = 0; i < _memberNames.length; i++) {
      if (_memberSelected[i]) {
        _memberAmountCtrls[i].text = per > 0 ? '$per' : '0';
      } else {
        _memberAmountCtrls[i].text = '0';
      }
    }
  }

  Future<void> _loadMembers() async {
    final names = await _authService.fetchHouseholdMemberNames();
    if (!mounted) return;
    setState(() {
      _memberNames = names;
      _memberSelected = List<bool>.filled(names.length, true);
      _loadingMembers = false;
      _ensureMemberAmountControllers();
      _syncMemberAmountFields();
    });
  }

  int _getSelectedGoodsTotalWon() {
    var sum = 0;
    for (final line in _lines) {
      if (line.selected) sum += line.amountWon;
    }
    return sum;
  }

  int _getSelectedMemberCount() {
    var n = 0;
    for (final s in _memberSelected) {
      if (s) n++;
    }
    return n;
  }

  int _getGoodsPerPersonWon() {
    final total = _getSelectedGoodsTotalWon();
    final n = _getSelectedMemberCount();
    if (n <= 0 || total <= 0) return 0;
    return (total / n).ceil();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}.';
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 365));
    final selected = isStart ? _rangeStart : _rangeEnd;
    final initialDate = selected.isBefore(today) ? today : selected;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => GlassmorphicDatePicker(
        initialDate: initialDate,
        firstDate: today,
        lastDate: maxDate,
        isStartDate: isStart,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        final d = DateTime(picked.year, picked.month, picked.day);
        if (isStart) {
          _rangeStart = d;
          if (_rangeEnd.isBefore(_rangeStart)) {
            _rangeEnd = _rangeStart;
          }
        } else {
          _rangeEnd = d;
          if (_rangeEnd.isBefore(_rangeStart)) {
            _rangeStart = _rangeEnd;
          }
        }
      });
    }
  }

  Widget _buildDateChip(String label, DateTime date, bool isStart) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickDate(isStart),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(20),
          backgroundOpacity: 0.08,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _formatDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(_SettlementSelectableLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => line.selected = !line.selected),
        behavior: HitTestBehavior.opaque,
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(22),
          backgroundOpacity: 0.08,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                line.selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: line.selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSelect(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    '공용 소비 물품 정산',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '어떤 소비 물품을 정산하실 건가요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard Variable',
                height: 1.22,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildDateChip('시작일', _rangeStart, true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '~',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildDateChip('종료일', _rangeEnd, false),
              ],
            ),
            const SizedBox(height: 18),
            ..._lines.map(_buildItemRow),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.35,
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
                    child: const Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 8,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(width: 14),
                Opacity(
                  opacity: 0.35,
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
                    child: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: '다음',
              onPressed: () {
                if (!_lines.any((e) => e.selected)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('정산할 물품을 하나 이상 선택해주세요.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                setState(() {
                  _step = 1;
                  _syncMemberAmountFields();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(BuildContext context, int index) {
    final name = _memberNames[index];
    final sel = _memberSelected[index];
    final maxNameW = (MediaQuery.sizeOf(context).width - 32) * 0.38;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FrostedPanel(
        borderRadius: BorderRadius.circular(22),
        backgroundOpacity: 0.08,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _memberSelected[index] = !sel;
                _syncMemberAmountFields();
              }),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color:
                        sel ? Colors.white : Colors.white.withOpacity(0.45),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxNameW),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSettlementMemberAmountTrailing(
              controller: _memberAmountCtrls[index],
              selected: sel,
              onAmountChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepMembers(BuildContext context) {
    final total = _getSelectedGoodsTotalWon();
    final n = _getSelectedMemberCount();
    final per = _getGoodsPerPersonWon();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => _step = 0),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '정산할 인원 선택',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pretendard Variable',
                      height: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '같은 그룹 멤버 중 정산에 참여할 인원을 선택하세요.\n'
              '(선택한 인원으로 N분의 1)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard Variable',
                height: 1.22,
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingMembers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else ...[
              Text(
                '선택 물품 합계: ${_formatKrwSettlement(total)}원 · 1인당: ${_formatKrwSettlement(per)}원 (${n > 0 ? n : '-'}명)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(
                _memberNames.length,
                (i) => _buildMemberRow(context, i),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: '정산하기',
              onPressed: () {
                if (_loadingMembers) return;
                if (_getSelectedMemberCount() == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('정산에 참여할 인원을 한 명 이상 선택해주세요.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('정산 요청 알림을 보냈어요.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return _SharedGlassDialogShell(
      constraints: BoxConstraints(
        maxWidth: sw - 32,
        maxHeight: sh * 0.72,
      ),
      child: _step == 0
          ? _buildStepSelect(context)
          : _buildStepMembers(context),
    );
  }
}

class _UtilitySelectableLine {
  final SharedExpenseTableItem item;
  bool selected;

  _UtilitySelectableLine({required this.item}) : selected = true;
}

/// 공과금 정산: 기간·항목 선택 → 정산할 인원 선택 → 완료 모달
class _UtilityBillSettlementFlowDialog extends StatefulWidget {
  final List<SharedExpenseTableItem> items;

  const _UtilityBillSettlementFlowDialog({required this.items});

  @override
  State<_UtilityBillSettlementFlowDialog> createState() =>
      _UtilityBillSettlementFlowDialogState();
}

class _UtilityBillSettlementFlowDialogState
    extends State<_UtilityBillSettlementFlowDialog> {
  int _step = 0;

  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late final List<_UtilitySelectableLine> _lines;
  late int _perPersonWon;

  List<String> _memberNames = [];
  List<bool> _memberSelected = [];
  final List<TextEditingController> _memberAmountCtrls = [];
  bool _loadingMembers = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _rangeStart = DateTime(2025, 8, 15);
    _rangeEnd = DateTime(2025, 8, 15);
    _lines = widget.items
        .map((e) => _UtilitySelectableLine(item: e))
        .toList();
    _perPersonWon = 8000;
    _loadMembers();
  }

  @override
  void dispose() {
    for (final c in _memberAmountCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureMemberAmountControllers() {
    while (_memberAmountCtrls.length < _memberNames.length) {
      _memberAmountCtrls.add(TextEditingController());
    }
    while (_memberAmountCtrls.length > _memberNames.length) {
      _memberAmountCtrls.removeLast().dispose();
    }
  }

  void _syncMemberAmountFields() {
    _ensureMemberAmountControllers();
    for (var i = 0; i < _memberNames.length; i++) {
      if (_memberSelected[i]) {
        _memberAmountCtrls[i].text =
            _perPersonWon > 0 ? '$_perPersonWon' : '0';
      } else {
        _memberAmountCtrls[i].text = '0';
      }
    }
  }

  Future<void> _loadMembers() async {
    final names = await _authService.fetchHouseholdMemberNames();
    if (!mounted) return;
    setState(() {
      _memberNames = names;
      _memberSelected = List<bool>.filled(names.length, true);
      _loadingMembers = false;
      _recalculatePerPerson();
      _ensureMemberAmountControllers();
      _syncMemberAmountFields();
    });
  }

  int _getSelectedMemberCount() {
    var n = 0;
    for (final s in _memberSelected) {
      if (s) n++;
    }
    return n;
  }

  int _getSelectedUtilitySumWon() {
    var sum = 0;
    for (final line in _lines) {
      if (!line.selected) continue;
      final w = _parseAmountToWon(line.item.amount);
      if (w != null) sum += w;
    }
    return sum;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}.';
  }

  int? _parseAmountToWon(String amount) {
    final t = amount.trim();
    if (t.isEmpty || t.contains('알 수 없음')) return null;
    final man = RegExp(r'(\d+)\s*만').firstMatch(t);
    if (man != null) {
      final v = int.tryParse(man.group(1)!);
      return v != null ? v * 10000 : null;
    }
    final digitsOnly = t.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return null;
    return int.tryParse(digitsOnly);
  }

  String _formatKrw(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _recalculatePerPerson() {
    var sum = 0;
    var any = false;
    for (final line in _lines) {
      if (!line.selected) continue;
      final w = _parseAmountToWon(line.item.amount);
      if (w != null) {
        sum += w;
        any = true;
      }
    }
    final n = _getSelectedMemberCount();
    if (n <= 0) {
      _perPersonWon = 8000;
      return;
    }
    if (!any || sum <= 0) {
      _perPersonWon = 8000;
      return;
    }
    _perPersonWon = (sum / n).ceil();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 365));
    final selected = isStart ? _rangeStart : _rangeEnd;
    final initialDate = selected.isBefore(today) ? today : selected;

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => GlassmorphicDatePicker(
        initialDate: initialDate,
        firstDate: today,
        lastDate: maxDate,
        isStartDate: isStart,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        final d = DateTime(picked.year, picked.month, picked.day);
        if (isStart) {
          _rangeStart = d;
          if (_rangeEnd.isBefore(_rangeStart)) {
            _rangeEnd = _rangeStart;
          }
        } else {
          _rangeEnd = d;
          if (_rangeEnd.isBefore(_rangeStart)) {
            _rangeStart = _rangeEnd;
          }
        }
      });
    }
  }

  Widget _buildDateChip(String label, DateTime date, bool isStart) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickDate(isStart),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(20),
          backgroundOpacity: 0.08,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _formatDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(_UtilitySelectableLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => line.selected = !line.selected),
        behavior: HitTestBehavior.opaque,
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(22),
          backgroundOpacity: 0.08,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                line.selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: line.selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.item.displayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepSelect(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    '공과금 정산',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '어떤 공과금을 정산하실 건가요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard Variable',
                height: 1.22,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildDateChip('시작일', _rangeStart, true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '~',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildDateChip('종료일', _rangeEnd, false),
              ],
            ),
            const SizedBox(height: 18),
            if (_lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '표에 공과금 내역을 먼저 추가해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              )
            else
              ..._lines.map(_buildItemRow),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.35,
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
                    child: const Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 8,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(width: 14),
                Opacity(
                  opacity: 0.35,
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
                    child: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: '다음',
              onPressed: () {
                if (_lines.isEmpty || !_lines.any((e) => e.selected)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _lines.isEmpty
                            ? '정산할 공과금 내역이 없습니다.'
                            : '정산할 공과금을 하나 이상 선택해주세요.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                setState(() {
                  _recalculatePerPerson();
                  _step = 1;
                  _syncMemberAmountFields();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityMemberRow(BuildContext context, int index) {
    final name = _memberNames[index];
    final sel = _memberSelected[index];
    final maxNameW = (MediaQuery.sizeOf(context).width - 32) * 0.38;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FrostedPanel(
        borderRadius: BorderRadius.circular(22),
        backgroundOpacity: 0.08,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _memberSelected[index] = !sel;
                _recalculatePerPerson();
                _syncMemberAmountFields();
              }),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color:
                        sel ? Colors.white : Colors.white.withOpacity(0.45),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxNameW),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSettlementMemberAmountTrailing(
              controller: _memberAmountCtrls[index],
              selected: sel,
              onAmountChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepMembers(BuildContext context) {
    final total = _getSelectedUtilitySumWon();
    final n = _getSelectedMemberCount();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => _step = 0),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '정산할 인원 선택',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Pretendard Variable',
                      height: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '같은 그룹 멤버 중 정산에 참여할 인원을 선택하세요.\n'
              '(선택한 인원으로 N분의 1)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard Variable',
                height: 1.22,
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingMembers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else ...[
              Text(
                '선택 항목 합계: ${_formatKrw(total)}원 · 1인당: ${_formatKrw(_perPersonWon)}원 (${n > 0 ? n : '-'}명)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(
                _memberNames.length,
                (i) => _buildUtilityMemberRow(context, i),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: '정산하기',
              onPressed: () {
                if (_loadingMembers) return;
                if (_getSelectedMemberCount() == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('정산에 참여할 인원을 한 명 이상 선택해주세요.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                _recalculatePerPerson();
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('정산 요청 알림을 보냈어요.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return _SharedGlassDialogShell(
      constraints: BoxConstraints(
        maxWidth: sw - 32,
        maxHeight: sh * 0.72,
      ),
      child: _step == 0
          ? _buildStepSelect(context)
          : _buildStepMembers(context),
    );
  }
}

class _ExtractedReceiptLine {
  String name;
  DateTime date;
  int amountWon;
  int qty;
  bool selected;

  _ExtractedReceiptLine({
    required this.name,
    required this.date,
    required this.amountWon,
    required this.qty,
    this.selected = true,
  });
}

/// AI 영수증: 소개 → 분석 확인 → 추출 (카메라 미연동 시 촬영만 시뮬레이션)
class _AiReceiptRecognitionFlowDialog extends StatefulWidget {
  const _AiReceiptRecognitionFlowDialog();

  @override
  State<_AiReceiptRecognitionFlowDialog> createState() =>
      _AiReceiptRecognitionFlowDialogState();
}

class _AiReceiptRecognitionFlowDialogState
    extends State<_AiReceiptRecognitionFlowDialog> {
  /// 0: 촬영 안내, 1: 분석 확인, 2: 추출 내용
  int _step = 0;

  late final List<_ExtractedReceiptLine> _lines;

  /// 다이얼로그 닫기: 포커스 해제 후 다음 프레임에 pop 해 라이프사이클·의존성 assert 방지
  void _closeReceiptFlowDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
    });
  }

  void _disposeEditControllerNextFrame(TextEditingController c) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.dispose();
    });
  }

  @override
  void initState() {
    super.initState();
    _lines = [
      _ExtractedReceiptLine(
        name: '가위',
        date: DateTime(2025, 8, 25),
        amountWon: 3000,
        qty: 1,
      ),
      _ExtractedReceiptLine(
        name: '주방칼',
        date: DateTime(2025, 8, 28),
        amountWon: 4000,
        qty: 1,
      ),
      _ExtractedReceiptLine(
        name: '키친타올',
        date: DateTime(2025, 8, 25),
        amountWon: 2500,
        qty: 2,
      ),
      _ExtractedReceiptLine(
        name: '쓰레기봉투',
        date: DateTime(2025, 8, 25),
        amountWon: 1800,
        qty: 1,
      ),
      _ExtractedReceiptLine(
        name: '주방세제',
        date: DateTime(2025, 8, 26),
        amountWon: 3200,
        qty: 1,
      ),
      _ExtractedReceiptLine(
        name: '라면 5입',
        date: DateTime(2025, 8, 27),
        amountWon: 4500,
        qty: 1,
      ),
      _ExtractedReceiptLine(
        name: '우유 900ml',
        date: DateTime(2025, 8, 28),
        amountWon: 3100,
        qty: 2,
      ),
    ];
  }

  void _simulateCapture() {
    // TODO: image_picker / camera — 현재는 사용자가 촬영한 것으로 간주
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    // 추출 단계는 이전 대비 높이 절반 — 목록은 ListView로 스크롤
    final maxH = _step == 2 ? sh * 0.37 : sh * 0.52;

    if (_step == 2) {
      return _SharedGlassDialogShell(
        constraints: BoxConstraints(maxWidth: sw - 32, maxHeight: maxH),
        child: SizedBox(
          height: maxH,
          child: _buildStepExtract(context),
        ),
      );
    }

    return _SharedGlassDialogShell(
      constraints: BoxConstraints(maxWidth: sw - 32, maxHeight: maxH),
      child: _step == 0
          ? _buildStepCapture(context)
          : _buildStepAnalyze(context),
    );
  }

  Widget _buildStepCapture(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 40),
              const Expanded(
                child: Text(
                  'AI 영수증 인식',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
              IconButton(
                onPressed: _closeReceiptFlowDialog,
                icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.9)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '영수증을 촬영해 구매 내역을 등록하시겠어요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard Variable',
              height: 1.22,
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: '촬영하기',
            onPressed: _simulateCapture,
          ),
        ],
      ),
    );
  }

  Widget _buildStepAnalyze(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '분석하시겠습니까?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Pretendard Variable',
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '촬영한 영수증 이미지를 분석해 품목을 추출합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Pretendard Variable',
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: '분석하기',
            onPressed: () => setState(() => _step = 2),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _closeReceiptFlowDialog,
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExtractReceiptDate(DateTime d) {
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}.';
  }

  Future<void> _editExtractLineName(int index) async {
    final line = _lines[index];
    final controller = TextEditingController(text: line.name);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          '품목명',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Pretendard Variable',
          ),
          decoration: InputDecoration(
            hintText: '텍스트로 입력',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    _disposeEditControllerNextFrame(controller);
    if (!mounted) return;
    if (ok == true && text.isNotEmpty) {
      setState(() => line.name = text);
    }
  }

  Future<void> _editExtractLineDate(int index) async {
    final line = _lines[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(2018, 1, 1);
    final last = today.add(const Duration(days: 365 * 3));

    final picked = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => GlassmorphicDatePicker(
        initialDate: line.date.isBefore(first)
            ? first
            : (line.date.isAfter(last) ? last : line.date),
        firstDate: first,
        lastDate: last,
        isStartDate: true,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        line.date = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _editExtractLineAmountWon(int index) async {
    final line = _lines[index];
    final controller =
        TextEditingController(text: line.amountWon.toString());
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          '금액 (원)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Pretendard Variable',
          ),
          decoration: InputDecoration(
            hintText: '정수만 입력 (원)',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            suffixText: '원',
            suffixStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Pretendard Variable',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ),
        ],
      ),
    );
    final raw = controller.text.trim();
    _disposeEditControllerNextFrame(controller);
    if (!mounted || ok != true) return;
    final v = int.tryParse(raw);
    if (v == null) return;
    setState(() => line.amountWon = v.clamp(0, 999999999));
  }

  Future<void> _editExtractLineQty(int index) async {
    final line = _lines[index];
    final controller = TextEditingController(text: line.qty.toString());
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          '수량',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard Variable',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Pretendard Variable',
          ),
          decoration: InputDecoration(
            hintText: '정수만 입력 (개)',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            suffixText: '개',
            suffixStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Pretendard Variable',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ),
        ],
      ),
    );
    final raw = controller.text.trim();
    _disposeEditControllerNextFrame(controller);
    if (!mounted || ok != true) return;
    final v = int.tryParse(raw);
    if (v == null || v < 1) return;
    setState(() => line.qty = v.clamp(1, 99999));
  }

  Widget _buildEditableExtractPill({
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: FrostedPanel(
            borderRadius: BorderRadius.circular(14),
            backgroundOpacity: 0.06,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Center(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepExtract(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '추출 내용',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '내용을 클릭해 수정할 수 있고, 원하는 리스트만 선택하여 등록할 수 있어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard Variable',
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _closeReceiptFlowDialog,
                icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.9)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            itemCount: _lines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final line = _lines[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => line.selected = !line.selected),
                    child: Icon(
                      line.selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: line.selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.45),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        _buildEditableExtractPill(
                          text: line.name,
                          onTap: () => _editExtractLineName(index),
                        ),
                        const SizedBox(width: 6),
                        _buildEditableExtractPill(
                          text: _formatExtractReceiptDate(line.date),
                          onTap: () => _editExtractLineDate(index),
                        ),
                        const SizedBox(width: 6),
                        _buildEditableExtractPill(
                          text: '${line.amountWon}원',
                          onTap: () => _editExtractLineAmountWon(index),
                        ),
                        const SizedBox(width: 6),
                        _buildEditableExtractPill(
                          text: '${line.qty}개',
                          onTap: () => _editExtractLineQty(index),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: '선택한 내용 등록하기',
                onPressed: () {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final n = _lines.where((e) => e.selected).length;
                  FocusManager.instance.primaryFocus?.unfocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.of(context, rootNavigator: true).maybePop();
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(
                          n > 0 ? '$n건 등록 요청 (더미)' : '선택된 항목이 없습니다.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _closeReceiptFlowDialog,
                  child: Text(
                    '영수증 분석 내용 취소',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

