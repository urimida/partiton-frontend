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

class _PartitionMainScreenState extends State<PartitionMainScreen> {
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
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 391,
                height: 121,
                child: GlassmorphismWidget(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  backgroundOpacity: 0.005,
                  showStroke: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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

