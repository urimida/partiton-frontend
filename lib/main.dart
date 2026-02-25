import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/core/theme/app_theme.dart';
import 'package:partition_app/core/providers/app_providers.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/debug/debug_home_screen.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';
import 'package:partition_app/features/auth/models/user_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: '0638124027aec1134312be64899dcde2',
  );
  
  runApp(const PartitionApp());
}

class PartitionApp extends StatelessWidget {
  const PartitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider를 디버그 모드에서 더미 유저로 초기화
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            if (kDebugMode) {
              // 디버그 모드에서 자동으로 더미 유저 설정 (선택사항)
              // auth.setMockUserForDebug();
            }
            return auth;
          },
        ),
        // 나머지 Provider들
        ...AppProviders.providers.skip(1), // AuthProvider는 이미 추가했으므로 제외
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // 디버그 모드에서는 DebugHomeScreen을 시작 화면으로
        home: kDebugMode 
            ? const DebugHomeScreen() 
            : const AuthWrapper(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

/// 인증 상태에 따라 초기 화면을 결정하는 위젯
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // StorageService 초기화
    await StorageService.init();
    
    // 인증 상태 확인
    final authService = AuthService();
    final isAuth = await authService.isAuthenticated();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
      
      // AuthProvider도 업데이트
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();
      
      // 인증 상태에 따라 네비게이션
      if (isAuth) {
        // 사용자 상태 확인 및 적절한 화면으로 이동
        final targetRoute = await _getTargetRoute();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(targetRoute);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      }
    }
  }  /// 사용자 상태에 따라 적절한 라우트 반환
  Future<String> _getTargetRoute() async {
    final authService = AuthService();
    
    // 서버에서 사용자 정보 조회 시도 (실패해도 계속 진행)
    UserModel? userInfo;
    try {
      userInfo = await authService.getUserInfo();
    } catch (e) {
      // 서버 에러 발생해도 무시하고 로컬 스토리지로 fallback
      debugPrint('사용자 정보 조회 실패 (로컬 스토리지 사용): $e');
    }
    
    // 1. 닉네임 확인 (서버 정보 우선, 없으면 로컬 스토리지 확인)
    String? userName = userInfo?.name;
    if (userName == null || userName.isEmpty) {
      userName = await StorageService.getUserName();
      if (userName == null || userName.isEmpty) {
        return AppRouter.onboardingSurvey; // 닉네임 입력 화면
      }
    } else {
      // 서버에서 가져온 이름을 로컬 스토리지에 저장
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 로딩 중이 아니면 빈 화면 (네비게이션이 처리됨)
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}