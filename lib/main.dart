import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/core/theme/app_theme.dart';
import 'package:partition_app/core/providers/app_providers.dart';
import 'package:partition_app/debug/debug_home_screen.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: kDebugMode ? const DebugHomeScreen() : null,
        initialRoute: kDebugMode ? null : AppRouter.initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

