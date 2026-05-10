import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/push/fcm_registration_service.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/core/theme/app_theme.dart';
import 'package:partition_app/core/providers/app_providers.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/debug/debug_home_screen.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase는 웹에서 백그라운드 메시지 핸들러 미지원
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await FcmRegistrationService.initializePlugin();

  // 카카오 SDK 초기화 (웹은 javascriptAppKey 필요)
  KakaoSdk.init(
    nativeAppKey: '0638124027aec1134312be64899dcde2',
    javaScriptAppKey: '4b6461d2fcd70ec1c6a0f4cd4c0c3cdf',
  );

  runApp(const PartitionApp());
}

class PartitionApp extends StatelessWidget {
  const PartitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
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
          unawaited(FcmRegistrationService.registerIfLoggedIn());
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      }
    }
  }

  /// 사용자 상태에 따라 적절한 라우트 반환
  Future<String> _getTargetRoute() async {
    final authService = AuthService();
    
    // 로컬 토큰·저장소 기반 세션 사용자 (GET /users/me 미사용)
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