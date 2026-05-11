import 'package:flutter/material.dart';

/// 상단의 '물품 / 공과금' 토글에 사용하는 반투명 필터 칩
class SharedExpenseFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;
  final double? horizontalPadding;
  final double verticalPadding;
  final double minHeight;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;

  const SharedExpenseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
    this.horizontalPadding,
    this.verticalPadding = 11,
    this.minHeight = 44,
    this.borderRadius = 24,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w800,
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
          vertical: verticalPadding,
        ),
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: selected
              ? Colors.white.withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
          border: Border.all(
            color: Colors.white.withOpacity(selected ? 0.9 : 0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            // 비선택: 어두운 남색 대신 반투명 흰색 — 배경에서도 읽기 쉽게 (선택보다는 덜 밝게)
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.68),
            fontWeight: fontWeight,
            fontSize: fontSize,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

