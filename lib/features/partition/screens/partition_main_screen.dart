import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/core/push/fcm_registration_service.dart';
import 'package:partition_app/features/partition/controllers/alarm_navigation_controller.dart';
import 'package:partition_app/features/partition/models/alarm_model.dart';
import 'package:partition_app/features/partition/screens/partition_home_screen.dart';
import 'package:partition_app/features/partition/screens/partition_shared_expense_screen.dart';
import 'package:partition_app/features/partition/screens/partition_report_screen.dart';
import 'package:partition_app/features/partition/services/alarm_service.dart';
import 'package:partition_app/features/partition/models/insight_query_models.dart';
import 'package:partition_app/features/partition/utils/recording_cleanup.dart';
import 'package:partition_app/features/partition/screens/partition_board_screen.dart';
import 'package:partition_app/features/partition/screens/partition_insight_result_screen.dart';
import 'package:partition_app/features/partition/services/insights_query_service.dart';
import 'package:partition_app/features/partition/providers/home_share_provider.dart';
/// 파티션 메인 화면 - 4개의 탭으로 구성
class PartitionMainScreen extends StatefulWidget {
  const PartitionMainScreen({super.key});

  @override
  State<PartitionMainScreen> createState() => _PartitionMainScreenState();
}

class _PartitionMainScreenState extends State<PartitionMainScreen>
    with TickerProviderStateMixin {
  /// 알림 패널이 완전히 열렸을 때 차지하는 높이 = 화면 세로의 이 비율 (고정 px 대비 짧은 기기 대응)
  static const double _alarmPanelOpenHeightFraction = 4 / 5;

  static const Color _bottomNavInactiveColor = Color(0xFF26394B);
  /// 읽은 알림 행 배경 — 흰 톤보다 어둡고 남색(#26394B) 계열 혼합
  static const Color _alarmReadRowFill = Color(0xFF1A2F42);

  int _currentIndex = 0;

  /// 마우스·트랙패드 호버, 또는 손가락을 바 위에 댄 동안 글로우
  bool _navBarHovered = false;
  bool _navBarPointerOnBar = false;

  bool get _navBarGlow =>
      _navBarHovered || _navBarPointerOnBar;

  /// 알림 패널 드래그 애니메이션 (0 = 닫힘, 1 = 완전히 열림)
  late AnimationController _panelController;

  final List<Widget> _screens = [
    const PartitionHomeScreen(),
    const PartitionSharedExpenseScreen(),
    const PartitionReportScreen(),
    const PartitionBoardScreen(),
  ];

  final List<String> _titles = [
    '홈',
    '공용소비',
    '파티션 리포트',
    '게시판',
  ];

  AnimationController? _glowController;
  Animation<double>? _glowAnimation;

  /// 좌우 스와이프로 탭 이동
  final PageController _tabPageController = PageController();

  final AlarmService _alarmService = AlarmService();
  List<AlarmItem> _alarms = [];
  int _alarmUnreadCount = 0;
  bool _alarmLoading = false;
  String? _alarmError;
  /// 패널이 열림 구간(값)에 진입했을 때만 API 호출 (중복·닫힘 리셋)
  bool _alarmPanelFetchArmed = false;
  int _alarmFetchGeneration = 0;
  final Set<int> _alarmMarkReadBusy = {};
  bool _initialFcmOpenHandled = false;

  void _showAlarmApiFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    debugPrint(isError ? '[Alarms][FAIL] $message' : '[Alarms][OK] $message');
    final bottom = MediaQuery.of(context).padding.bottom + 176;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
        backgroundColor:
            isError ? const Color(0xFF8B2942) : const Color(0xE61A2F42),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _handlePanelForAlarms() {
    final v = _panelController.value;
    /// 닫힌 상태(값이 낮음)에서 올라올 때마다 GET (끌어올릴 때 리로드)
    const openThreshold = 0.32;
    final isOpenEnough = v >= openThreshold;
    if (isOpenEnough && !_alarmPanelFetchArmed) {
      _fetchAlarms();
    }
    _alarmPanelFetchArmed = isOpenEnough;
  }

  Future<void> _fetchAlarms() async {
    if (!mounted) return;
    final gen = ++_alarmFetchGeneration;
    setState(() {
      _alarmLoading = true;
      _alarmError = null;
    });
    try {
      final result = await _alarmService.fetchMyAlarms();
      if (!mounted || gen != _alarmFetchGeneration) return;
      setState(() {
        _alarms = result.alarms;
        _alarmUnreadCount = result.unreadCount;
        _alarmLoading = false;
      });
    } catch (e) {
      if (!mounted || gen != _alarmFetchGeneration) return;
      setState(() {
        _alarmLoading = false;
        _alarmError = e is ApiException
            ? e.message
            : '알림을 불러오지 못했습니다.';
      });
      final msg = e is ApiException
          ? e.message
          : '알림을 불러오지 못했습니다.';
      _showAlarmApiFeedback(msg, isError: true);
    }
  }

  /// 정산 관련 알림이면 `referenceId`를 settlementId로 공용소비 탭으로 보냅니다.
  bool _alarmItemHasSettlementDeepLink(AlarmItem item) {
    final rid = item.referenceId;
    if (rid == null || rid <= 0) return false;
    switch (item.type) {
      case AlarmNoticeType.supplySettlementRequested:
      case AlarmNoticeType.supplySettlementConfirmed:
      case AlarmNoticeType.billSettlementRequested:
      case AlarmNoticeType.billSettlementConfirmed:
        return true;
      default:
        return false;
    }
  }

  /// 문서 순서: (목록에서 확인) → `referenceId`로 정산 화면 이동 → `PATCH .../read`
  Future<void> _onAlarmRowTapped(AlarmItem item) async {
    if (_alarmItemHasSettlementDeepLink(item)) {
      if (!mounted) return;
      context.read<AlarmNavigationController>().setPending(
            AlarmNavPending(
              settlementId: item.referenceId!,
              noticeType: item.type,
              alarmId: item.alarmId,
            ),
          );
      _switchToTab(1, animate: false);
      _closePanel();
    }

    if (item.isRead || _alarmMarkReadBusy.contains(item.alarmId)) return;
    setState(() => _alarmMarkReadBusy.add(item.alarmId));
    try {
      await _alarmService.markAlarmAsRead(item.alarmId);
      if (!mounted) return;
      setState(() {
        _alarmMarkReadBusy.remove(item.alarmId);
        final ix =
            _alarms.indexWhere((a) => a.alarmId == item.alarmId);
        if (ix != -1) {
          final wasUnread = !_alarms[ix].isRead;
          final next = List<AlarmItem>.from(_alarms);
          next[ix] = next[ix].copyWith(isRead: true);
          _alarms = next;
          if (wasUnread && _alarmUnreadCount > 0) {
            _alarmUnreadCount = _alarmUnreadCount - 1;
          }
        }
      });
      debugPrint('[Alarms] 읽음 처리 alarmId=${item.alarmId}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _alarmMarkReadBusy.remove(item.alarmId));
      final msg = e is ApiException ? e.message : '읽음 처리에 실패했습니다.';
      _showAlarmApiFeedback(msg, isError: true);
    }
  }

  /// FCM `data`에 `settlementId`·`referenceId`·`type`(또는 `alarmType`)·선택 `alarmId` 포함 시 공용소비로 이동.
  void _handleFcmRemoteOpenForAlarmNavigation(RemoteMessage message) {
    if (!mounted) return;
    final data = message.data;
    final sid = int.tryParse(
      data['settlementId']?.toString() ??
          data['referenceId']?.toString() ??
          '',
    );
    final typeStr =
        data['type']?.toString() ?? data['alarmType']?.toString() ?? '';
    final noticeType = AlarmNoticeType.parse(typeStr);
    if (sid == null || sid <= 0 || noticeType == AlarmNoticeType.unknown) {
      return;
    }
    final aid = int.tryParse(data['alarmId']?.toString() ?? '') ?? 0;
    context.read<AlarmNavigationController>().setPending(
          AlarmNavPending(
            settlementId: sid,
            noticeType: noticeType,
            alarmId: aid,
          ),
        );
    _switchToTab(1, animate: false);
  }

  String _formatAlarmTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _glowController!,
      curve: Curves.easeInOut,
    );

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _panelController.addListener(_handlePanelForAlarms);

    FcmRegistrationService.attachRemoteOpenListener(
      _handleFcmRemoteOpenForAlarmNavigation,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // FCM 초기 메시지 처리
      if (!_initialFcmOpenHandled) {
        _initialFcmOpenHandled = true;
        final m = await FirebaseMessaging.instance.getInitialMessage();
        if (m != null && mounted) {
          _handleFcmRemoteOpenForAlarmNavigation(m);
        }
      }

      // 귀가 공유 저장된 상태 복원
      if (mounted) {
        await context.read<HomeShareProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _panelController.removeListener(_handlePanelForAlarms);
    _glowController?.dispose();
    _panelController.dispose();
    _tabPageController.dispose();
    super.dispose();
  }

  /// 하단바·딥링크에서 탭 전환 시 [PageView]와 상태를 맞춤.
  void _switchToTab(int index, {bool animate = true}) {
    assert(index >= 0 && index < _screens.length);
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }

    void apply() {
      if (!_tabPageController.hasClients) return;
      final pos = _tabPageController.page;
      final current = pos != null ? pos.round() : _tabPageController.initialPage;
      if (current == index) return;
      if (animate) {
        _tabPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _tabPageController.jumpToPage(index);
      }
    }

    if (_tabPageController.hasClients) {
      apply();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        apply();
      });
    }
  }

  /// 탭별로 기존 [Scaffold.body] 패딩과 동일 (스와이프 중에도 각 페이지 레이아웃 유지)
  Widget _paddedTabPage(BuildContext context, int index, Widget screen) {
    final fullBleed = index == 1 || index == 2 || index == 3;
    return Padding(
      padding: EdgeInsets.only(
        top: fullBleed
            ? 0
            : MediaQuery.paddingOf(context).top +
                (index == 0 ? 0 : kToolbarHeight),
        bottom: fullBleed ? 0 : 148,
      ),
      child: screen,
    );
  }

  Widget _buildTabPageView(BuildContext context) {
    return PageView.builder(
      controller: _tabPageController,
      itemCount: _screens.length,
      onPageChanged: (i) {
        if (_currentIndex != i) setState(() => _currentIndex = i);
      },
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemBuilder: (context, i) => _paddedTabPage(context, i, _screens[i]),
    );
  }

  void _openPanel() =>
      _panelController.animateTo(1.0, curve: Curves.easeOutCubic);

  void _closePanel() =>
      _panelController.animateTo(0.0, curve: Curves.easeInCubic);

  @override
  Widget build(BuildContext context) {
    final isHomeScreen = _currentIndex == 0;
    final fullBleedBody =
        _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3;
    return Stack(
      children: [
        // 전 화면에 깔리는 공통 배경
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.black);
            },
          ),
        ),
        Scaffold(
          appBar: (isHomeScreen || fullBleedBody)
              ? null
              : AppBar(
                  title: Text(_titles[_currentIndex]),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          // 공용소비(1)·게시판(3): 커스텀 헤더를 최상단에 붙이기 위해 바깥 top 패딩 없음.
          // 하단 148은 홈·리포트만 (닫힌 하단바 높이와 맞춤, 바는 화면 하단 붙임).
          body: _buildTabPageView(context),
        ),
        _buildUnifiedBottomComponent(),
      ],
    );
  }

  /// 하단 통합 컴포넌트: 하단바 ↔ 알림 패널을 같은 글래스 컨테이너 안에서 전환
  Widget _buildUnifiedBottomComponent() {
    /// 아래쪽만 늘리며 바닥에 붙이는 높이(이전 10px 띄움만큼 하단 확장).
    const double closedHeight = 148.0;

    return AnimatedBuilder(
      animation: _panelController,
      builder: (context, child) {
        final t = _panelController.value;
        final screenH = MediaQuery.sizeOf(context).height;
        final openHeight = screenH * _alarmPanelOpenHeightFraction;
        final height = lerpDouble(closedHeight, openHeight, t)!;
        const double bottom = 0.0;
        return Positioned(
          bottom: bottom,
          left: 0,
          right: 0,
          height: height,
          child: child!,
        );
      },
      child: _buildBottomContainer(),
    );
  }

  Widget _buildBottomContainer() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        final screenH = MediaQuery.sizeOf(context).height;
        final openH = screenH * _alarmPanelOpenHeightFraction;
        const closedH = 148.0;
        final dragRange = (openH - closedH).clamp(240.0, 1200.0);
        _panelController.value =
            (_panelController.value - details.delta.dy / dragRange)
                .clamp(0.0, 1.0);
      },
      onVerticalDragEnd: (details) {
        if (_panelController.value > 0.3 ||
            details.velocity.pixelsPerSecond.dy < -400) {
          _openPanel();
        } else {
          _closePanel();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => setState(() => _navBarPointerOnBar = true),
        onPointerUp: (_) => setState(() => _navBarPointerOnBar = false),
        onPointerCancel: (_) => setState(() => _navBarPointerOnBar = false),
        child: MouseRegion(
          onEnter: (_) => setState(() => _navBarHovered = true),
          onExit: (_) => setState(() => _navBarHovered = false),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 글래스 배경: 닫힌 상태는 원래 노치 모양, 열린 상태는 풀 패널
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _panelController,
                  builder: (ctx, _) => ClipPath(
                    clipper: _UnifiedNavClipper(t: _panelController.value),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                              _navBarGlow ? 0.20 : 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 글래스 테두리 (동일 클립 적용)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _panelController,
                  builder: (ctx, _) => ClipPath(
                    clipper: _UnifiedNavClipper(t: _panelController.value),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(
                              _navBarGlow ? 0.45 : 0.25),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 하단바 아이템: 글래스 시작선(~노치 아래)부터 바닥까지 채우고 세로 중앙 정렬
              AnimatedBuilder(
                animation: _panelController,
                builder: (ctx, child) {
                  final opacity =
                      (1.0 - _panelController.value * 4.0).clamp(0.0, 1.0);
                  return Positioned(
                    top: _UnifiedNavClipper.navTopOffsetClosed,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: _panelController.value > 0.1,
                      child: Opacity(opacity: opacity, child: child),
                    ),
                  );
                },
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  minimum: EdgeInsets.zero,
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            icon: _currentIndex == 0
                                ? Icons.calendar_today
                                : Icons.calendar_today_outlined,
                            label: '홈',
                            index: 0,
                          ),
                          _buildNavItem(
                            icon: _currentIndex == 1
                                ? Icons.inventory_2
                                : Icons.inventory_2_outlined,
                            label: '공용 소비',
                            index: 1,
                          ),
                          _buildNavItem(
                            icon: Icons.home,
                            label: '파티션 리포트',
                            index: 2,
                          ),
                          _buildNavItem(
                            icon: Icons.notifications,
                            label: '게시판',
                            index: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
              ), // SafeArea
              ),
              // 알림 패널 내용 (패널이 열릴수록 나타남)
              AnimatedBuilder(
                animation: _panelController,
                builder: (ctx, child) {
                  final opacity =
                      ((_panelController.value - 0.25) / 0.75).clamp(0.0, 1.0);
                  return Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _panelController.value < 0.5,
                      child: Opacity(opacity: opacity, child: child),
                    ),
                  );
                },
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                  child: _buildNotificationPanel(),
                ),
              ),
              // 오브 (패널이 열릴수록 사라짐)
              AnimatedBuilder(
                animation: _panelController,
                builder: (ctx, child) {
                  final opacity =
                      (1.0 - _panelController.value * 4.0).clamp(0.0, 1.0);
                  return Positioned(
                    top: -20,
                    child: IgnorePointer(
                      ignoring: _panelController.value > 0.1,
                      child: Opacity(opacity: opacity, child: child),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: _showAiModal,
                  child: _buildOrb(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                '알림',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
              if (_alarmUnreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_alarmUnreadCount',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(height: 0.5, color: Colors.white.withOpacity(0.18)),
        Expanded(child: _buildNotificationBody()),
      ],
    );
  }

  Widget _buildNotificationBody() {
    if (_alarmLoading && _alarms.isEmpty && _alarmError == null) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      );
    }
    if (_alarmError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _alarmError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _alarmLoading ? null : () => _fetchAlarms(),
                child: Text(
                  '다시 시도',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 10),
            Text(
              '새로운 알림이 없습니다',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    final bottomPad = MediaQuery.of(context).padding.bottom + 12;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding:
          EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      itemCount: _alarms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = _alarms[i];
        final subLine = item.referenceId != null &&
                item.type != AlarmNoticeType.unknown
            ? '정산번호 ${item.referenceId} · ${_formatAlarmTime(item.createdAt)}'
            : _formatAlarmTime(item.createdAt);
        final read = item.isRead;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Dismissible(
            key: ValueKey<int>(item.alarmId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              try {
                await _alarmService.deleteAlarm(item.alarmId);
                return true;
              } catch (e) {
                if (!mounted) return false;
                final msg =
                    e is ApiException ? e.message : '알림을 삭제하지 못했습니다.';
                _showAlarmApiFeedback(msg, isError: true);
                return false;
              }
            },
            onDismissed: (_) {
              if (!mounted) return;
              setState(() {
                _alarms.removeWhere((a) => a.alarmId == item.alarmId);
                _alarmMarkReadBusy.remove(item.alarmId);
                if (!item.isRead && _alarmUnreadCount > 0) {
                  _alarmUnreadCount = _alarmUnreadCount - 1;
                }
              });
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: const Color(0xFF8B2942),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.white.withOpacity(0.92),
                size: 26,
              ),
            ),
            child: Material(
              color:
                  read ? _alarmReadRowFill : Colors.white.withOpacity(0.06),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => unawaited(_onAlarmRowTapped(item)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!item.isRead)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _alarmMarkReadBusy.contains(item.alarmId)
                                  ? Colors.white.withOpacity(0.35)
                                  : const Color(0xFF6BA3FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayMessage,
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                    read ? 0.72 : 0.96),
                                fontSize: 15,
                                fontWeight:
                                    read ? FontWeight.w400 : FontWeight.w600,
                                height: 1.35,
                                decoration: TextDecoration.none,
                                decorationColor: Colors.transparent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subLine,
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                    read ? 0.32 : 0.4),
                                fontSize: 12,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAiModal() async {
    final result = await showGeneralDialog<InsightQueryResult?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI 모달',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const _PartitionAiModal(),
      transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        child: child,
      ),
    );
    if (!mounted || result == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PartitionInsightResultScreen(result: result),
      ),
    );
  }

  Widget _buildOrb() {
    return Container(
      width: 88,
      height: 69,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        gradient: const RadialGradient(
          center: Alignment(-0.1477, -0.4783),
          radius: 3.2411,
          colors: [
            Color.fromRGBO(255, 255, 255, 0.15),
            Color.fromRGBO(255, 255, 255, 0.3),
          ],
          stops: [0.0, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: _glowAnimation != null
              ? AnimatedBuilder(
                  animation: _glowAnimation!,
                  builder: (context, _) {
                    final double glow = 0.7 + (_glowAnimation!.value * 0.3);
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, 0.0),
                          radius: 0.85,
                          colors: [
                            Color.fromRGBO(255, 242, 215, 0.9 * glow),
                            Color.fromRGBO(251, 218, 158, 0.55 * glow),
                            Color.fromRGBO(77, 101, 119, 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.65, 1.0],
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.0),
                      radius: 0.85,
                      colors: [
                        Color.fromRGBO(255, 242, 215, 0.9),
                        Color.fromRGBO(251, 218, 158, 0.55),
                        Color.fromRGBO(77, 101, 119, 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData? icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchToTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: isSelected ? Colors.white : _bottomNavInactiveColor,
                size: 24,
              ),
            const SizedBox(height: 4),
            Transform.translate(
              offset: const Offset(0, 5),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : _bottomNavInactiveColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단바(노치 있음) → 알림 패널(풀 패널)로 전환되는 통합 클리퍼
class _UnifiedNavClipper extends CustomClipper<Path> {
  /// 닫힌 상태 글래스 상단 시작(노치·오브 영역 아래와 맞춤)
  static const double navTopOffsetClosed = 30.0;

  final double t; // 0 = 하단바 상태(노치), 1 = 풀 패널 상태

  const _UnifiedNavClipper({required this.t});

  @override
  Path getClip(Size size) {
    const double cornerRadius = 24.0;
    const double notchRadius = 30.0;
    const double notchWidth = 104.0;
    const double notchHeight = 60.0;
    const double notchOffset = 6.0;

    // 상단 여백: t=0이면 노치 아래 글래스 시작선, t=1이면 0(풀 패널)
    final double topOffset = navTopOffsetClosed * (1.0 - t);

    final Path base = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, topOffset, size.width, size.height - topOffset),
        topLeft: const Radius.circular(cornerRadius),
        topRight: const Radius.circular(cornerRadius),
      ));

    // 노치는 처음 40% 구간에서 사라짐
    final double notchDepth = ((1.0 - t / 0.4)).clamp(0.0, 1.0);
    if (notchDepth <= 0) return base;

    final double notchCenterY =
        topOffset + (notchRadius + notchOffset - 40) * notchDepth;

    final Path notch = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, notchCenterY),
          width: notchWidth * notchDepth,
          height: notchHeight * notchDepth,
        ),
        Radius.circular(notchRadius * notchDepth),
      ));

    return Path.combine(PathOperation.difference, base, notch);
  }

  @override
  bool shouldReclip(_UnifiedNavClipper oldClipper) => oldClipper.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// 파티션 AI 질문 모달
// ─────────────────────────────────────────────────────────────────────────────

/// 사용자 지정 액센트 (#FFFDCB, 불투명)
const Color _kPartitionAiCream = Color(0xFFFFFDCB);

/// 화면 가장자리 얇은 선 — 흰색↔크림이 천천히 흐르는 물결 느낌 (전체 화면 그라데이션 대비 가벼움)
class _ScreenEdgeFlowBorderPainter extends CustomPainter {
  _ScreenEdgeFlowBorderPainter({required this.flowT});

  /// 0~1 한 바퀴
  final double flowT;

  static const double _stroke = 1.25;
  static const double _inset = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 화면 비율 기반으로 모서리 반경을 동적으로 계산 (폰 화면 곡률에 맞춤)
    final cornerRadius = size.width * 0.12;

    final rect = Rect.fromLTWH(
      _inset,
      _inset,
      size.width - _inset * 2,
      size.height - _inset * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    final path = Path()..addRRect(rrect);

    final sweep = SweepGradient(
      center: Alignment.center,
      startAngle: flowT * math.pi * 2,
      endAngle: flowT * math.pi * 2 + math.pi * 2,
      colors: [
        Colors.white.withOpacity(0.95),
        _kPartitionAiCream.withOpacity(0.92),
        Colors.white.withOpacity(0.95),
        _kPartitionAiCream.withOpacity(0.92),
        Colors.white.withOpacity(0.95),
      ],
      stops: const [0.0, 0.22, 0.45, 0.68, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..shader = sweep.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScreenEdgeFlowBorderPainter oldDelegate) =>
      oldDelegate.flowT != flowT;
}

class _PartitionAiModal extends StatefulWidget {
  const _PartitionAiModal();

  @override
  State<_PartitionAiModal> createState() => _PartitionAiModalState();
}

class _PartitionAiModalState extends State<_PartitionAiModal>
    with TickerProviderStateMixin {
  /// 테두리 색 흐름 (느리게 한 바퀴 — 레이어 하나·선만 repaint)
  late final AnimationController _borderFlowCtrl;

  final InsightsQueryService _insights = InsightsQueryService();
  final AudioRecorder _recorder = AudioRecorder();

  // 0 = 텍스트로 질문, 1 = 자연어(음성)로 질문
  int _modeIndex = 0;

  // 텍스트 모드
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  /// 음성과 함께 보낼 선택 질문 (`text+audio`)
  final TextEditingController _voiceAuxCtrl = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;

  bool _submitting = false;

  bool _isRecording = false;
  bool _micBusy = false;
  Timer? _recordingTicker;
  int _recordingSecs = 0;
  String? _recordingPathActive;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    _borderFlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) _endDate = _startDate;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endDate = picked;
      if (_startDate.isAfter(_endDate)) _startDate = _endDate;
    });
  }

  Future<void> _showMicPermissionDialog(bool permanentlyDenied) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('마이크 권한'),
        content: Text(
          permanentlyDenied
              ? '마이크가 꺼져 있어 녹음할 수 없습니다. 설정에서 Partition 앱의 마이크를 허용해 주세요.'
              : '음성으로 질문하려면 마이크 사용에 동의해 주세요. 시스템에서 뜨는 허용 창에서 「허용」을 눌러 주세요.',
        ),
        actions: [
          if (permanentlyDenied)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text('설정 열기'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecordingErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('녹음'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_submitting || _isRecording) return;
    setState(() => _micBusy = true);
    try {
      if (!kIsWeb) {
        var status = await Permission.microphone.status;
        if (!status.isGranted) {
          status = await Permission.microphone.request();
        }
        if (!status.isGranted) {
          if (mounted) {
            await _showMicPermissionDialog(status.isPermanentlyDenied);
          }
          return;
        }
      }

      final recorderOk = await _recorder.hasPermission();
      if (!recorderOk) {
        if (mounted) {
          await _showMicPermissionDialog(false);
        }
        return;
      }

      if (_recordedPath != null) {
        await discardLocalRecording(_recordedPath);
        if (mounted) {
          setState(() => _recordedPath = null);
        }
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/insight_${DateTime.now().millisecondsSinceEpoch}.m4a';

      final recordConfig = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.wav : AudioEncoder.aacLc,
      );

      try {
        await _recorder.start(
          recordConfig,
          path: path,
        );
      } catch (e) {
        debugPrint('[PartitionAI] record start failed: $e');
        if (mounted) {
          await _showRecordingErrorDialog(
            '녹음을 시작하지 못했습니다.\n\n$e',
          );
        }
        return;
      }

      _recordingTicker?.cancel();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingSecs = 0;
        _recordingPathActive = path;
      });
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSecs++);
      });
    } finally {
      if (mounted) setState(() => _micBusy = false);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordingTicker?.cancel();
    _recordingTicker = null;
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedPath = path ?? _recordingPathActive;
        _recordingPathActive = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingPathActive = null;
        });
        await _showRecordingErrorDialog('녹음을 저장하지 못했습니다.\n\n$e');
      }
    }
  }

  Future<void> _discardRecording() async {
    final p = _recordedPath;
    if (p != null) {
      await discardLocalRecording(p);
    }
    if (!mounted) return;
    setState(() {
      _recordedPath = null;
      _recordingSecs = 0;
    });
  }

  Future<void> _submitText() async {
    final query = _textCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final res = await _insights.queryText(
        question: query,
        startDate: _fmtYmd(_startDate),
        endDate: _fmtYmd(_endDate),
      );
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitVoice() async {
    final path = _recordedPath;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음을 완료한 뒤 질문하기를 눌러 주세요.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await _insights.queryVoice(
        audioFilePath: path,
        question: _voiceAuxCtrl.text.trim().isEmpty
            ? null
            : _voiceAuxCtrl.text.trim(),
        startDate: _fmtYmd(_startDate),
        endDate: _fmtYmd(_endDate),
      );
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _switchMode(int index) {
    if (_isRecording) {
      unawaited(_stopRecording());
    }
    setState(() {
      _modeIndex = index;
    });
    if (index == 0) {
      _textFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    unawaited(_recorder.dispose());
    _borderFlowCtrl.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    _voiceAuxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // ── 어두운 반투명 배경 ─────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),

            // ── 화면 가장자리 얇은 선: 흰색 ↔ #FFFDCB 색이 천천히 흐름 ─────
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _borderFlowCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ScreenEdgeFlowBorderPainter(
                        flowT: _borderFlowCtrl.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── 모달 카드 ──────────────────────────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 24,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: _buildCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.11),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // 제목
              const Text(
                '파티션 AI에게 질문하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 16),

              _buildQueryOptions(),
              const SizedBox(height: 18),

              // 모드 토글
              _buildModeToggle(),
              const SizedBox(height: 24),

              // 모드별 내용
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _modeIndex == 0
                    ? _buildTextMode()
                    : _buildVoiceMode(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '조회 기간',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dateChip(
                label: '시작',
                value: _fmtYmd(_startDate),
                onTap: _submitting ? null : _pickStartDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateChip(
                label: '종료',
                value: _fmtYmd(_endDate),
                onTap: _submitting ? null : _pickEndDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateChip({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 11,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          _buildModeTab('텍스트로 질문', 0),
          _buildModeTab('자연어로 질문', 1),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, int index) {
    final isSelected = _modeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.45),
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  // ── 텍스트 입력 모드 ─────────────────────────────────────────────────────

  Widget _buildTextMode() {
    return Column(
      key: const ValueKey('text'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: TextField(
            controller: _textCtrl,
            focusNode: _textFocus,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
            decoration: InputDecoration(
              hintText: '파티션 AI에게 물어보세요...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.32),
                fontSize: 15,
              ),
              contentPadding:
                  const EdgeInsets.fromLTRB(16, 14, 16, 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            maxLines: 5,
            minLines: 3,
            cursorColor: _kPartitionAiCream,
            cursorWidth: 2,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _buildSendButton(
            onPressed: _submitting ? null : _submitText,
            busy: _submitting,
          ),
        ),
      ],
    );
  }

  // ── 음성 입력 모드 (FastAPI `POST /api/insights/query-voice`) ─────────────

  Widget _buildVoiceMode() {
    return Column(
      key: const ValueKey('voice'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          kIsWeb
              ? '브라우저에서 마이크를 허용하면 녹음됩니다. (HTTPS 또는 localhost 필요)'
              : '마이크로 녹음한 파일을 서버로 보내 분석합니다. (Whisper / 오디오 모델)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.52),
            fontSize: 13,
            height: 1.4,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_submitting || _isRecording || _micBusy)
                    ? null
                    : () {
                        unawaited(_startRecording());
                      },
                icon: _micBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.fiber_manual_record,
                        color: Colors.redAccent.withOpacity(0.9),
                        size: 18,
                      ),
                label: Text(_micBusy ? '준비 중…' : '녹음 시작'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.28)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (!_isRecording || _submitting) ? null : _stopRecording,
                icon: Icon(Icons.stop, color: _kPartitionAiCream.withOpacity(0.95)),
                label: const Text('녹음 종료'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.28)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_isRecording) ...[
          const SizedBox(height: 10),
          Text(
            '녹음 중 · ${_recordingSecs}s',
            style: TextStyle(
              color: _kPartitionAiCream.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
          ),
        ],
        if (_recordedPath != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent.withOpacity(0.85), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '녹음이 준비되었습니다.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 13,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
              ),
              TextButton(
                onPressed: _submitting ? null : _discardRecording,
                child: const Text('다시 녹음'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: TextField(
            controller: _voiceAuxCtrl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
            decoration: InputDecoration(
              hintText: '같이 보낼 질문 (선택, 텍스트+음성)',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.32),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              border: InputBorder.none,
            ),
            maxLines: 2,
            minLines: 1,
            cursorColor: _kPartitionAiCream,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _buildSendButton(
            onPressed: _submitting ? null : _submitVoice,
            busy: _submitting,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton({VoidCallback? onPressed, bool busy = false}) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPartitionAiCream,
        foregroundColor: const Color(0xFF1A2F42),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Color(0xFF1A2F42),
              ),
            )
          : const Text(
              '질문하기',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
    );
  }
}
