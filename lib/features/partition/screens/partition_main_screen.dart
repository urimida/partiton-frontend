import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
              // 이미지 로드 실패 시 대체 배경색
              return Container(color: Colors.black);
            },
          ),
        ),
        Scaffold(
          appBar: isHomeScreen
              ? null
              : AppBar(
                  title: Text(_titles[_currentIndex]),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top +
                  (isHomeScreen ? 0 : kToolbarHeight),
              bottom: 140, // 네비게이션 바 높이만큼 하단 패딩
            ),
            child: _screens[_currentIndex],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            bottom: false,
            child: SizedBox(
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
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
                    ),
                  ),
                ],
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
    String? svgAsset,
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
            // SVG 아이콘이 있으면 SVG 사용, 없으면 Material Icon 사용
            if (svgAsset != null)
              Builder(
                builder: (context) {
                  try {
                    return SvgPicture.asset(
                      svgAsset,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.white : AppColors.mainNavy,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (context) => Icon(
                        Icons.error_outline,
                        color: isSelected ? Colors.white : AppColors.mainNavy,
                        size: 24,
                      ),
                    );
                  } catch (e) {
                    // SVG 로드 실패 시 대체 아이콘 표시
                    return Icon(
                      Icons.error_outline,
                      color: isSelected ? Colors.white : AppColors.mainNavy,
                      size: 24,
                    );
                  }
                },
              )
            else if (icon != null)
              isSelected
                  ? Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    )
                  : Icon(
                      icon,
                      color: AppColors.mainNavy,
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
    const double notchOffset = 6; // how far below the top edge the notch dips

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

