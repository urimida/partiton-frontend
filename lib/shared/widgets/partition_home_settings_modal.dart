import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/features/auth/models/household_response_model.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';
import 'package:partition_app/features/auth/services/kakao_auth_service.dart';

/// 홈 탭 「설정」— 그룹 리더 여부·그룹 코드·계정 관련 동작
class PartitionHomeSettingsModal extends StatefulWidget {
  const PartitionHomeSettingsModal({super.key});

  @override
  State<PartitionHomeSettingsModal> createState() =>
      _PartitionHomeSettingsModalState();
}

class _PartitionHomeSettingsModalState extends State<PartitionHomeSettingsModal> {
  final AuthService _authService = AuthService();
  HouseholdResponseModel? _household;
  bool _loading = true;

  static const Color _destructiveMuted = Color(0xFFD88A94);

  @override
  void initState() {
    super.initState();
    _loadHousehold();
  }

  Future<void> _loadHousehold() async {
    setState(() => _loading = true);
    final res = await _authService.fetchMyHousehold();
    if (!mounted) return;
    setState(() {
      _household = res;
      _loading = false;
    });
  }

  bool get _isLeader {
    final r = _household?.result?.role?.trim().toUpperCase();
    if (r == 'LEADER') return true;
    if (r == null || r.isEmpty) {
      return StorageService.getUserRole()?.toUpperCase() == 'LEADER';
    }
    return false;
  }

  String get _groupCode {
    final c = _household?.result?.code?.trim();
    if (c != null && c.isNotEmpty) return c;
    return '—';
  }

  String get _groupName {
    final n = _household?.result?.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return '내 그룹';
  }

  Future<void> _copyGroupCode(BuildContext ctx) async {
    final code = _groupCode;
    if (code == '—') {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('복사할 그룹 코드가 없습니다.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('그룹 코드를 복사했습니다.')),
    );
  }

  Future<bool> _confirm(
    BuildContext ctx, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          message,
          style:
              TextStyle(color: Colors.white.withOpacity(0.85), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text('취소',
                style: TextStyle(color: Colors.white.withOpacity(0.55))),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(confirmLabel,
                style: const TextStyle(color: Color(0xFF6BA3FF))),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onLogout(BuildContext ctx) async {
    final ok =
        await _confirm(ctx,
            title: '로그아웃',
            message: '로그아웃할까요?',
            confirmLabel: '로그아웃');
    if (!ok || !mounted) return;
    try {
      try {
        await KakaoAuthService.logout();
      } catch (_) {}
      // ignore: use_build_context_synchronously
      await ctx.read<AuthProvider>().logout();
    } catch (_) {}
    if (!mounted || !ctx.mounted) return;
    Navigator.of(ctx, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRouter.login,
      (_) => false,
    );
  }

  Future<void> _onLeaveGroup(BuildContext ctx) async {
    final ok =
        await _confirm(ctx,
            title: '그룹 나가기',
            message:
                '이 파티션 그룹에서 나가요. 같은 그룹에 다시 들어오려면 그룹 코드가 필요합니다.',
            confirmLabel: '나가기');
    if (!ok || !mounted) return;

    try {
      await _authService.leaveHouseholdAsMember();
    } catch (e) {
      if (!ctx.mounted) return;
      final msg = e is ApiException ? e.message : '그룹 나가기에 실패했어요.';
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    await StorageService.clearHouseholdAffiliation();
    if (!ctx.mounted) return;
    Navigator.of(ctx, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRouter.groupSelection,
      (_) => false,
    );
  }

  Future<void> _onDeleteAccount(BuildContext ctx) async {
    final ok =
        await _confirm(ctx,
            title: '회원 탈퇴',
            message: '계정과 연결된 정보가 삭제될 수 있어요.\n계속 진행할까요?',
            confirmLabel: '탈퇴');
    if (!ok || !mounted) return;

    try {
      await _authService.deleteMyAccountOnServer();
    } catch (e) {
      if (!ctx.mounted) return;
      final msg = e is ApiException ? e.message : '회원 탈퇴에 실패했어요.';
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    try {
      await KakaoAuthService.logout();
    } catch (_) {}
    if (!ctx.mounted) return;
    await ctx.read<AuthProvider>().logout();
    if (!ctx.mounted) return;
    Navigator.of(ctx, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRouter.login,
      (_) => false,
    );
  }

  Widget _dangerButton(BuildContext ctx, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: _destructiveMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mutedButton(BuildContext ctx, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.24)),
              color: Colors.white.withOpacity(0.10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        const Expanded(
                          child: Text(
                            '설정',
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
                          tooltip: '닫기',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 40, minHeight: 40),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.88),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        _groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isLeader
                                ? Icons.manage_accounts_rounded
                                : Icons.person_outline_rounded,
                            size: 20,
                            color: Colors.white.withOpacity(0.75),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isLeader ? '그룹 리더예요.' : '그룹 리더가 아니에요. (그룹원)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 13,
                                height: 1.35,
                                fontFamily: 'Pretendard Variable',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '그룹 코드',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _copyGroupCode(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.16)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _groupCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Pretendard Variable',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.copy_rounded,
                                size: 20,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '탭하면 코드가 복사돼요.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.42),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _mutedButton(context, '로그아웃',
                          () => _onLogout(context)),
                      const SizedBox(height: 10),
                      _dangerButton(context, '그룹 나가기',
                          () => _onLeaveGroup(context)),
                      const SizedBox(height: 10),
                      _dangerButton(context, '회원 탈퇴',
                          () => _onDeleteAccount(context)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
