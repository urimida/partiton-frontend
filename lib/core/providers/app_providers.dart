import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';
import 'package:partition_app/features/partition/controllers/alarm_navigation_controller.dart';
import 'package:partition_app/features/partition/providers/home_share_provider.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<AlarmNavigationController>(
          create: (_) => AlarmNavigationController(),
        ),
        ChangeNotifierProvider<HomeShareProvider>(
          create: (_) => HomeShareProvider(),
        ),
      ];
}

