import 'package:flutter/material.dart';
import 'package:partition_app/shared/utils/app_colors.dart';

/// 상단의 '물품 / 공과금' 토글에 사용하는 반투명 필터 칩
class SharedExpenseFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final double? horizontalPadding;

  const SharedExpenseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? 28,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected
              ? Colors.white.withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.9 : 0.4),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.mainNavy,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

