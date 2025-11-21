import 'package:flutter/material.dart';
import 'package:partition_app/features/auth/screens/login_screen.dart';
import 'package:partition_app/features/auth/screens/register_screen.dart';
import 'package:partition_app/features/partition/screens/partition_main_screen.dart';
import 'package:partition_app/features/settings/screens/settings_screen.dart';
import 'package:partition_app/shared/widgets/not_found_screen.dart';

class AppRouter {
  static const String initialRoute = '/login';
  
  // Route names
  static const String login = '/login';
  static const String register = '/register';
  static const String partitionMain = '/partitions';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );
      case partitionMain:
        return MaterialPageRoute(
          builder: (_) => const PartitionMainScreen(),
        );
      case AppRouter.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}

