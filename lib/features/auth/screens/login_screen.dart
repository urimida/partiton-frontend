import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';
import 'package:partition_app/features/auth/services/kakao_auth_service.dart';
import 'package:partition_app/shared/utils/debug_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isKakaoLoginLoading = false;

  /// 사용자 상태에 따라 적절한 라우트 반환
  Future<String> _getTargetRoute() async {
    final authService = AuthService();
    
    final userInfo = await authService.getUserInfo();

    // 1. 닉네임 확인 (세션 모델·로컬 스토리지)
    String? userName = userInfo?.name;
    if (userName == null || userName.isEmpty) {
      userName = await StorageService.getUserName();
      if (userName == null || userName.isEmpty) {
        return AppRouter.onboardingSurvey; // 닉네임 입력 화면
      }
    } else {
      await StorageService.setUserName(userName);
    }

    // 2. 그룹(가구) 확인
    final householdId = await StorageService.getHouseholdId();
    if (householdId == null || householdId.isEmpty) {
      return AppRouter.groupSelection; // 그룹 선택 화면
    }

    // 3. 선호도 입력 완료 여부 확인
    final isOnboardingCompleted = await StorageService.isOnboardingCompleted();
    if (!isOnboardingCompleted) {
      return AppRouter.preferenceSurvey; // 선호도 설문 화면
    }

    // 모든 설정이 완료된 경우 홈으로 이동
    return AppRouter.partitionMain;
  }

  Future<void> _handleKakaoLogin() async {
    if (_isKakaoLoginLoading) return;
    
    setState(() {
      _isKakaoLoginLoading = true;
    });

    try {
      DebugHelper.log('🔐 카카오 로그인 시도');
      
      // 카카오 로그인 실행
      final token = await KakaoAuthService.login();
      
      if (token == null) {
        // 사용자가 로그인을 취소한 경우
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 취소되었습니다.')),
          );
        }
        return;
      }

      DebugHelper.log('✅ 카카오 로그인 성공');
      DebugHelper.log('액세스 토큰: ${token.accessToken}');

      // 잠시 대기 (토큰이 완전히 설정되도록)
      await Future.delayed(const Duration(milliseconds: 100));

      // 사용자 정보 조회
      final user = await KakaoAuthService.getUserInfo();
      
      if (user != null) {
        DebugHelper.log('=== 카카오 사용자 정보 ===');
        DebugHelper.log('회원번호: ${user.id}');
        DebugHelper.log('카카오 계정 존재: ${user.kakaoAccount != null}');
        
        if (user.kakaoAccount != null) {
          DebugHelper.log('닉네임: ${user.kakaoAccount!.profile?.nickname ?? "null"}');
          DebugHelper.log('이메일: ${user.kakaoAccount!.email ?? "null"}');
          DebugHelper.log('이메일 동의 필요 여부: ${user.kakaoAccount!.emailNeedsAgreement}');
          DebugHelper.log('이메일 유효 여부: ${user.kakaoAccount!.isEmailValid}');
          DebugHelper.log('이메일 검증 여부: ${user.kakaoAccount!.isEmailVerified}');
          DebugHelper.log('카카오 계정 전체: ${user.kakaoAccount}');
        } else {
          DebugHelper.log('⚠️⚠️⚠️ kakaoAccount가 null입니다! ⚠️⚠️⚠️');
          DebugHelper.log('이것은 카카오 계정 정보를 전혀 받아오지 못했다는 의미입니다.');
          DebugHelper.log('');
          DebugHelper.log('해결 방법:');
          DebugHelper.log('1. 카카오 개발자 콘솔에서 동의 항목 확인');
          DebugHelper.log('   - 제품 설정 > 카카오 로그인 > 동의 항목');
          DebugHelper.log('   - 이메일 항목이 "필수 동의" 또는 "선택 동의"로 설정되어 있는지 확인');
          DebugHelper.log('2. 앱에서 로그아웃 후 다시 로그인');
          DebugHelper.log('   - 기존 로그인 정보가 캐시되어 있을 수 있음');
          DebugHelper.log('3. 카카오 앱에서 동의 항목 확인');
          DebugHelper.log('   - 카카오 앱 > 설정 > 개인정보 > 연결된 서비스 관리');
          DebugHelper.log('   - 해당 앱의 동의 항목을 확인하고 이메일 제공에 동의');
          DebugHelper.log('4. 앱 재설치 (필요시)');
          DebugHelper.log('   - 완전히 삭제 후 재설치하여 새로운 동의 화면 표시');
        }
      } else {
        DebugHelper.log('⚠️ 사용자 정보 조회 실패');
      }

      // 카카오 로그인 성공 후 서비스 로그인 처리
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // 카카오 이메일 가져오기
        String? email;
        
        // kakaoAccount가 null인 경우 처리
        if (user?.kakaoAccount == null) {
          DebugHelper.log('❌ kakaoAccount가 null입니다. 카카오 계정 정보를 받아오지 못했습니다.');
          DebugHelper.log('카카오 개발자 콘솔 설정 후 로그아웃하고 다시 로그인해주세요.');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('카카오 계정 정보를 받아오지 못했습니다. 로그아웃 후 다시 로그인해주세요.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
          
          // 임시로 카카오 ID를 이메일 형식으로 변환
          final kakaoId = user?.id.toString() ?? 'kakao_${DateTime.now().millisecondsSinceEpoch}';
          email = '$kakaoId@kakao.com';
          DebugHelper.log('⚠️ 임시 이메일 사용: $email');
        } else {
          // kakaoAccount가 있는 경우 이메일 가져오기
          email = user?.kakaoAccount?.email;
          
          // 이메일이 없거나 유효하지 않은 경우 처리
          if (email == null || email.isEmpty) {
            DebugHelper.log('⚠️ 이메일이 null이거나 비어있습니다.');
            DebugHelper.log('이메일 동의 필요: ${user?.kakaoAccount?.emailNeedsAgreement}');
            DebugHelper.log('이메일 유효: ${user?.kakaoAccount?.isEmailValid}');
            DebugHelper.log('이메일 검증: ${user?.kakaoAccount?.isEmailVerified}');
            
            // 추가 동의가 필요한 경우
            if (user?.kakaoAccount?.emailNeedsAgreement == true) {
              DebugHelper.log('❌ 이메일 추가 동의가 필요합니다!');
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('이메일 동의가 필요합니다. 카카오 앱에서 동의 항목을 확인해주세요.'),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
            
            // 임시로 카카오 ID를 이메일 형식으로 변환
            final kakaoId = user?.id.toString() ?? 'kakao_${DateTime.now().millisecondsSinceEpoch}';
            email = '$kakaoId@kakao.com';
            DebugHelper.log('⚠️ 임시 이메일 사용: $email');
          } else {
            DebugHelper.log('✅✅✅ 카카오 이메일 정상 수신: $email ✅✅✅');
          }
        }
        
        // 카카오 액세스 토큰으로 서버 로그인 처리
        final result = await authProvider.loginWithKakao(
          kakaoAccessToken: token.accessToken,
        );
        
        if (result.success && mounted) {
          // userRole에 따라 적절한 화면으로 이동
          String targetRoute;
          if (result.userRole == 'LEADER' || result.userRole == 'MEMBER') {
            // LEADER 또는 MEMBER인 경우 홈으로 이동
            targetRoute = AppRouter.partitionMain;
          } else if (result.userRole == 'GUEST') {
            // GUEST인 경우 온보딩으로 이동
            targetRoute = AppRouter.onboardingSurvey;
          } else {
            // userRole이 없는 경우 기존 로직 사용
            targetRoute = await _getTargetRoute();
          }
          
          Navigator.of(context).pushReplacementNamed(targetRoute);
        }
      } catch (e) {
        DebugHelper.log('서비스 로그인 처리 중 오류: $e');
        // Provider 에러 발생 시에도 사용자 상태 확인 후 이동
        if (mounted) {
          final targetRoute = await _getTargetRoute();
          Navigator.of(context).pushReplacementNamed(targetRoute);
        }
      }
    } catch (error) {
      DebugHelper.log('❌ 카카오 로그인 실패: $error');
      
      if (mounted) {
        String errorMessage = '카카오 로그인 중 오류가 발생했습니다.';
        
        if (error.toString().contains('CANCELED')) {
          errorMessage = '로그인이 취소되었습니다.';
        } else if (error.toString().contains('NETWORK')) {
          errorMessage = '네트워크 오류가 발생했습니다.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isKakaoLoginLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 백그라운드 이미지
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 이미지 로드 실패 시 대체 배경색
              return Container(color: Colors.black);
            },
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 로고
                    const SizedBox(height: 100),
                    SvgPicture.asset(
                      'assets/icons/logo.svg',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 20),
                    // partition 텍스트
                    const Text(
                      'PARTITION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                    const SizedBox(height: 60),
                    // 카카오 로그인 버튼 — 공식 에셋 비율 유지 (전체 너비로 늘리지 않음)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 366),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isKakaoLoginLoading ? null : _handleKakaoLogin,
                            borderRadius: BorderRadius.circular(8),
                            child: _isKakaoLoginLoading
                                ? const SizedBox(
                                    height: 48,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF000000),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/kakao_login_medium_wide.png',
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          constraints: const BoxConstraints(
                                            maxWidth: 366,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE500),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: const Center(
                                            child: Text(
                                              '카카오 로그인',
                                              style: TextStyle(
                                                color: Color(0xFF000000),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 200), // 하단 여백
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
