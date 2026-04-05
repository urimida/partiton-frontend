import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:partition_app/features/partition/screens/partition_home_screen.dart';
import 'package:partition_app/features/partition/screens/partition_shared_expense_screen.dart';
import 'package:partition_app/features/partition/screens/partition_report_screen.dart';
import 'package:partition_app/features/partition/screens/partition_board_screen.dart';
import 'package:partition_app/shared/utils/app_colors.dart';
import 'package:partition_app/shared/widgets/glassmorphism_widget.dart';

/// 파티션 메인 화면 - 4개의 탭으로 구성
class PartitionMainScreen extends StatefulWidget {
  const PartitionMainScreen({super.key});

  @override
  State<PartitionMainScreen> createState() => _PartitionMainScreenState();
}

class _PartitionMainScreenState extends State<PartitionMainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  /// 마우스·트랙패드 호버, 또는 손가락을 바 위에 댄 동안 글로우
  bool _navBarHovered = false;
  bool _navBarPointerOnBar = false;

  bool get _navBarGlow =>
      _navBarHovered || _navBarPointerOnBar;

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
  }

  @override
  void dispose() {
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHomeScreen = _currentIndex == 0;

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
          appBar: (isHomeScreen || _currentIndex == 1)
              ? null
              : AppBar(
                  title: Text(_titles[_currentIndex]),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          // 공용소비(1): 헤더를 화면 최상단에 붙이기 위해 바깥 top 패딩 없음 — SafeArea는
          // `PartitionSharedExpenseScreen` 헤더 안에서 처리. 하단 140은 리포트·게시판만.
          body: Padding(
            padding: EdgeInsets.only(
              top: _currentIndex == 1
                  ? 0
                  : MediaQuery.of(context).padding.top +
                      (_currentIndex == 0 ? 0 : kToolbarHeight),
              bottom: _currentIndex == 1 ? 0 : 140,
            ),
            child: _screens[_currentIndex],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            bottom: false,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => setState(() => _navBarPointerOnBar = true),
              onPointerUp: (_) => setState(() => _navBarPointerOnBar = false),
              onPointerCancel: (_) =>
                  setState(() => _navBarPointerOnBar = false),
              child: MouseRegion(
                onEnter: (_) => setState(() => _navBarHovered = true),
                onExit: (_) => setState(() => _navBarHovered = false),
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // 글래스 바와 동일 위치·크기·클립 (35 + 121 = 하단 영역과 일치)
                      Positioned(
                        top: 35,
                        left: 0,
                        right: 0,
                        height: 121,
                        child: ClipPath(
                          clipper: _BottomNavClipper(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: 121,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                width: 1,
                                color: _navBarGlow
                                    ? Colors.white.withOpacity(0.48)
                                    : Colors.transparent,
                              ),
                              boxShadow: _navBarGlow
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.22),
                                        blurRadius: 14,
                                        spreadRadius: -6,
                                        offset: Offset.zero,
                                      ),
                                    ]
                                  : const [],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 35,
                        left: 0,
                        right: 0,
                        child: ClipPath(
                          clipper: _BottomNavClipper(),
                          child: SizedBox(
                            height: 121,
                            child: GlassmorphismWidget(
                          borderRadius: BorderRadius.circular(24),
                          backgroundOpacity: 0.4,
                          showStroke: true,
                          borderColor: Colors.white.withOpacity(0.25),
                          strokeGradient: const RadialGradient(
                            center: Alignment(0.2535, -0.6739),
                            radius: 2.5,
                            colors: [
                              Color.fromRGBO(255, 255, 255, 0.3),
                              Color.fromRGBO(255, 255, 255, 0.0),
                            ],
                            stops: [0.0, 1.0],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 20),
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
                    ),
                  ),
                  Positioned(
                    top: -15,
                    child: Container(
                      width: 88,
                      height: 69,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
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
                                    final double glow =
                                        0.7 + (_glowAnimation!.value * 0.3);
                                    return Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: const Alignment(0.0, 0.0),
                                          radius: 0.85,
                                          colors: [
                                            Color.fromRGBO(
                                                255, 242, 215, 0.9 * glow),
                                            Color.fromRGBO(
                                                251, 218, 158, 0.55 * glow),
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
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
                color: isSelected ? Colors.white : AppColors.mainNavy,
                size: 24,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.mainNavy,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavClipper extends CustomClipper<Path> {
  const _BottomNavClipper();

  @override
  Path getClip(Size size) {
    const double cornerRadius = 24;
    const double notchRadius = 30;
    const double notchWidth = 104;
    const double notchHeight = 60;
    const double notchOffset = 6;

    final Path base = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(cornerRadius),
        ),
      );

    final Path notch = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, notchRadius + notchOffset - 40),
            width: notchWidth,
            height: notchHeight,
          ),
          const Radius.circular(notchRadius),
        ),
      );

    return Path.combine(PathOperation.difference, base, notch);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
