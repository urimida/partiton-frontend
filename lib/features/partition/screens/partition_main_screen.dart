import 'dart:async';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/core/push/fcm_registration_service.dart';
import 'package:partition_app/features/partition/controllers/alarm_navigation_controller.dart';
import 'package:partition_app/features/partition/models/alarm_model.dart';
import 'package:partition_app/features/partition/screens/partition_home_screen.dart';
import 'package:partition_app/features/partition/screens/partition_shared_expense_screen.dart';
import 'package:partition_app/features/partition/screens/partition_report_screen.dart';
import 'package:partition_app/features/partition/services/alarm_service.dart';
import 'package:partition_app/features/partition/screens/partition_board_screen.dart';
/// 파티션 메인 화면 - 4개의 탭으로 구성
class PartitionMainScreen extends StatefulWidget {
  const PartitionMainScreen({super.key});

  @override
  State<PartitionMainScreen> createState() => _PartitionMainScreenState();
}

class _PartitionMainScreenState extends State<PartitionMainScreen>
    with TickerProviderStateMixin {
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
      setState(() => _currentIndex = 1);
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
    setState(() => _currentIndex = 1);
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
      if (_initialFcmOpenHandled || !mounted) return;
      _initialFcmOpenHandled = true;
      final m = await FirebaseMessaging.instance.getInitialMessage();
      if (m != null && mounted) {
        _handleFcmRemoteOpenForAlarmNavigation(m);
      }
    });
  }

  @override
  void dispose() {
    _panelController.removeListener(_handlePanelForAlarms);
    _glowController?.dispose();
    _panelController.dispose();
    super.dispose();
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
          body: Padding(
            padding: EdgeInsets.only(
              top: fullBleedBody
                  ? 0
                  : MediaQuery.of(context).padding.top +
                      (_currentIndex == 0 ? 0 : kToolbarHeight),
              bottom: fullBleedBody ? 0 : 148,
            ),
            child: _screens[_currentIndex],
          ),
        ),
        _buildUnifiedBottomComponent(),
      ],
    );
  }

  /// 하단 통합 컴포넌트: 하단바 ↔ 알림 패널을 같은 글래스 컨테이너 안에서 전환
  Widget _buildUnifiedBottomComponent() {
    /// 아래쪽만 늘리며 바닥에 붙이는 높이(이전 10px 띄움만큼 하단 확장).
    const double closedHeight = 148.0;
    const double openHeight = 700.0;

    return AnimatedBuilder(
      animation: _panelController,
      builder: (context, child) {
        final t = _panelController.value;
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
        _panelController.value =
            (_panelController.value - details.delta.dy / 450.0)
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
                    child: Transform.translate(
                      offset: const Offset(0, 10),
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
                        ), // Row
                    ), // Padding
                  ), // Transform.translate
                ), // Align
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
                child: _buildOrb(),
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
        return Material(
          color:
              read ? _alarmReadRowFill : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
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
        );
      },
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
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
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
