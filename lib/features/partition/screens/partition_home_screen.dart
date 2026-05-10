import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/features/partition/providers/home_share_provider.dart';
import 'package:partition_app/features/partition/services/geocoding_service.dart';
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
  final GlobalKey<HomeCalendarWidgetState> _calendarKey =
      GlobalKey<HomeCalendarWidgetState>();

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
        onSuccess: _refreshCalendar,
      ),
    );
  }

  void _showChoreAssignmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ChoreAssignmentModal(
        onSuccess: _refreshCalendar,
      ),
    );
  }

  // ── 집 위치 변경 ──────────────────────────────────────────────────────────

  Future<void> _onEditHomeLocation(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => const _HomeLocationChangeDialog(),
    );
  }

  // ── 귀가 공유 토글 처리 ────────────────────────────────────────────────────

  Future<void> _onToggleSharing(BuildContext context) async {
    final provider = context.read<HomeShareProvider>();

    if (provider.isEnabled) {
      await provider.disableSharing();
      return;
    }

    // 집 위치가 없으면 설정 다이얼로그 먼저
    if (provider.homeLocation == null) {
      final bool set = await _showHomeSetupDialog(context);
      if (!set) return;
    }

    final bool success = await provider.enableSharing();
    if (!success && context.mounted) {
      // ignore: use_build_context_synchronously
      _showEnableFailFeedback(context);
    }
  }

  Future<bool> _showHomeSetupDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => const _HomeLocationSetupDialog(),
    );
    return result ?? false;
  }

  Future<void> _showEnableFailFeedback(BuildContext context) async {
    final perm = await Permission.location.status;
    if (!context.mounted) return;
    if (perm.isPermanentlyDenied) {
      _showPermissionDeniedDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 서비스 또는 권한이 필요합니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '위치 권한 필요',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '귀가 공유를 사용하려면 위치 권한이 필요합니다.\n'
          '설정 > Partition App > 위치에서 허용해주세요.',
          style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('취소', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: const Text('설정 열기',
                style: TextStyle(color: Color(0xFF6BA3FF))),
          ),
        ],
      ),
    );
  }

  // ── UI 빌드 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth - 32;

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
            const SizedBox(height: 0),
            Image.asset(
              'assets/icons/partition-logo-mini.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 26),
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
            const SizedBox(height: 12),
            _HomeShareCard(
              onToggle: () => _onToggleSharing(context),
              onEditLocation: () => _onEditHomeLocation(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 귀가 공유 토글 카드
// ─────────────────────────────────────────────────────────────────────────────

class _HomeShareCard extends StatelessWidget {
  const _HomeShareCard({
    required this.onToggle,
    required this.onEditLocation,
  });

  final VoidCallback onToggle;
  final VoidCallback onEditLocation;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeShareProvider>();
    final bool enabled = provider.isEnabled;
    final bool nearHome = provider.isNearHome;
    final bool loading = provider.isLoading;
    final bool hasHome = provider.homeLocation != null;

    final Color accentColor =
        nearHome ? const Color(0xFFFFFDCB) : const Color(0xFF6BA3FF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(enabled ? 0.15 : 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled
                  ? accentColor.withOpacity(0.45)
                  : Colors.white.withOpacity(0.22),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 아이콘
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: enabled
                          ? accentColor.withOpacity(0.18)
                          : Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      enabled && nearHome
                          ? Icons.home_rounded
                          : Icons.directions_walk_rounded,
                      color: enabled
                          ? accentColor
                          : Colors.white.withOpacity(0.55),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '귀가 공유',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel(enabled, nearHome, hasHome),
                          style: TextStyle(
                            color: enabled
                                ? accentColor.withOpacity(0.9)
                                : Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 집 위치 변경 버튼
                  GestureDetector(
                    onTap: onEditLocation,
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.edit_location_alt_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                  // 토글 또는 로딩
                  if (loading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 50,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: enabled
                              ? accentColor.withOpacity(0.8)
                              : Colors.white.withOpacity(0.18),
                          border: Border.all(
                            color: enabled
                                ? accentColor
                                : Colors.white.withOpacity(0.28),
                          ),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              top: 3,
                              left: enabled ? 22 : 3,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // 집 근처일 때 상태 배지
              if (enabled && nearHome) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDCB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFFDCB).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFDCB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '룸메이트에게 귀가 알림을 보내고 있어요.',
                        style: TextStyle(
                          color: const Color(0xFFFFFDCB).withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(bool enabled, bool nearHome, bool hasHome) {
    if (!enabled) return '룸메이트에게 귀가를 알려요';
    if (!hasHome) return '집 위치가 설정되지 않았어요';
    if (nearHome) return '집 근처에 있어요';
    return '집 밖에서 공유 중이에요';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 집 위치 설정 다이얼로그
// ─────────────────────────────────────────────────────────────────────────────

class _HomeLocationSetupDialog extends StatefulWidget {
  const _HomeLocationSetupDialog();

  @override
  State<_HomeLocationSetupDialog> createState() =>
      _HomeLocationSetupDialogState();
}

class _HomeLocationSetupDialogState extends State<_HomeLocationSetupDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _onSetCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<HomeShareProvider>();
    final bool success = await provider.setHomeFromCurrentLocation();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = '현재 위치를 가져오지 못했습니다.\n위치 권한을 확인해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F42).withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BA3FF).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Color(0xFF6BA3FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '집 위치 설정',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 설명
                Text(
                  '귀가 공유 기능을 사용하려면 집 위치를 먼저 등록해야 해요.\n\n'
                  '집 반경 300m 안에 들어오면 룸메이트에게\n'
                  '조용한 알림이 전송됩니다.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 14,
                    height: 1.6,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),

                // 공유 정책 안내
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _policyRow(Icons.check_circle_outline_rounded,
                          '"집 근처 도착 여부"만 공유'),
                      const SizedBox(height: 6),
                      _policyRow(
                          Icons.do_not_disturb_alt_rounded, '실시간 위치·이동 경로 비공개'),
                      const SizedBox(height: 6),
                      _policyRow(Icons.group_rounded, '같은 파티션 그룹 룸메이트에게만 전송'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 오류 메시지
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B2942).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _onSetCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6BA3FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 18),
                    label: Text(
                      _loading ? '위치 가져오는 중...' : '현재 위치를 집으로 설정',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(false),
                    child: Text(
                      '나중에 설정하기',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        decoration: TextDecoration.none,
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

  Widget _policyRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6BA3FF).withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 집 위치 변경 다이얼로그
// ─────────────────────────────────────────────────────────────────────────────

class _HomeLocationChangeDialog extends StatefulWidget {
  const _HomeLocationChangeDialog();

  @override
  State<_HomeLocationChangeDialog> createState() =>
      _HomeLocationChangeDialogState();
}

class _HomeLocationChangeDialogState extends State<_HomeLocationChangeDialog> {
  final TextEditingController _searchController = TextEditingController();

  bool _locationLoading = false;
  bool _searchLoading = false;
  bool _addressLoading = false;
  List<PlaceSuggestion> _suggestions = [];
  bool _searchedOnce = false;
  String? _error;
  Timer? _debounce;
  bool _apiKeyMissing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkApiKey();
    _ensureAddressLoaded();
  }

  void _checkApiKey() {
    _apiKeyMissing = !GeocodingService.hasApiKey;
  }

  Future<void> _ensureAddressLoaded() async {
    final provider = context.read<HomeShareProvider>();
    if (provider.homeAddress == null && provider.homeLocation != null) {
      setState(() => _addressLoading = true);
      final loc = provider.homeLocation!;
      final address = await GeocodingService.reverseGeocode(loc.lat, loc.lng);
      if (!mounted) return;
      if (address != null) await provider.updateHomeAddress(address);
      setState(() => _addressLoading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searchLoading = true;
      _searchedOnce = true;
      _error = null;
    });
    final (:results, :error) = await GeocodingService.searchPlaces(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _error = error;
      _searchLoading = false;
    });
  }

  Future<void> _onUseCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _error = null;
    });
    final provider = context.read<HomeShareProvider>();
    final success = await provider.setHomeFromCurrentLocation();
    if (!mounted) return;
    setState(() => _locationLoading = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = '현재 위치를 가져오지 못했습니다.\n위치 권한을 확인해주세요.');
    }
  }

  Future<void> _onSelectPlace(PlaceSuggestion place) async {
    // 카카오 검색 결과에는 좌표가 이미 포함되어 있으므로 별도 상세 조회 불필요
    setState(() {
      _suggestions = [];
      _error = null;
    });
    final provider = context.read<HomeShareProvider>();
    await provider.setHomeFromCoordinates(
        place.lat, place.lng, place.formattedAddress);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeShareProvider>();
    final homeAddress = provider.homeAddress;
    final hasHome = provider.homeLocation != null;
    final hasAddress = homeAddress != null && homeAddress.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2F42).withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 (고정)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6BA3FF).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Color(0xFF6BA3FF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '집 위치 변경',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.45),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 스크롤 가능한 본문
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 현재 설정 주소
                          if (hasHome) ...[
                            Text(
                              '현재 설정된 집 주소',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: hasAddress
                                    ? const Color(0xFF6BA3FF).withOpacity(0.12)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasAddress
                                      ? const Color(0xFF6BA3FF).withOpacity(0.3)
                                      : Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_addressLoading)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    )
                                  else
                                    Icon(
                                      hasAddress
                                          ? Icons.location_on_rounded
                                          : Icons.location_searching_rounded,
                                      color: hasAddress
                                          ? const Color(0xFF6BA3FF)
                                          : Colors.white.withOpacity(0.35),
                                      size: 18,
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _addressLoading
                                        ? Text(
                                            '주소 불러오는 중...',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.45),
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              decoration: TextDecoration.none,
                                            ),
                                          )
                                        : hasAddress
                                            ? Text(
                                                homeAddress,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.88),
                                                  fontSize: 13,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '주소 정보 없음',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.55),
                                                      fontSize: 13,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '아래 검색으로 집 주소를 등록해주세요',
                                                    style: TextStyle(
                                                      color: Colors.orange
                                                          .withOpacity(0.75),
                                                      fontSize: 11,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 현재 위치로 설정 버튼
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _locationLoading ? null : _onUseCurrentLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6BA3FF),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: _locationLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.my_location_rounded,
                                      size: 16),
                              label: Text(
                                _locationLoading
                                    ? '위치 가져오는 중...'
                                    : '현재 위치로 설정',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 구분선
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: Colors.white.withOpacity(0.15))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '또는 주소 검색',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Colors.white.withOpacity(0.15))),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 검색 입력창
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.15)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14),
                              decoration: InputDecoration(
                                hintText: _apiKeyMissing
                                    ? '카카오 REST API 키 설정 후 사용 가능'
                                    : '장소 또는 주소를 검색하세요',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 14,
                                  decoration: TextDecoration.none,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.38),
                                  size: 20,
                                ),
                                suffixIcon: _searchLoading
                                    ? Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                Colors.white.withOpacity(0.4),
                                          ),
                                        ),
                                      )
                                    : _searchController.text.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              _searchController.clear();
                                              setState(() {
                                                _suggestions = [];
                                                _searchedOnce = false;
                                              });
                                            },
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Colors.white
                                                  .withOpacity(0.35),
                                            ),
                                          )
                                        : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                enabled: !_apiKeyMissing,
                              ),
                            ),
                          ),

                          // 에러 메시지
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B2942).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],

                          // 검색 결과
                          if (_suggestions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.12)),
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                  itemBuilder: (context, index) {
                                    final place = _suggestions[index];
                                    return InkWell(
                                      onTap: () => _onSelectPlace(place),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 16,
                                              color: const Color(0xFF6BA3FF)
                                                  .withOpacity(0.7),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    place.mainText,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.92),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                  if (place.secondaryText
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      place.secondaryText,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.45),
                                                        fontSize: 11,
                                                        decoration:
                                                            TextDecoration.none,
                                                      ),
                                                    ),
                                                  ],
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
                            ),
                          ] else if (_searchedOnce &&
                              !_searchLoading &&
                              _error == null &&
                              _searchController.text.isNotEmpty) ...[
                            // 검색 결과 없음
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                '검색 결과가 없어요',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
