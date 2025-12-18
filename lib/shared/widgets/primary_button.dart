import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:partition_app/shared/widgets/frosted_panel.dart';

/// 앱 전반에서 사용할 기본 버튼 스타일 (버튼 1)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 360,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius pillRadius = BorderRadius.circular(height / 2);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: FrostedPanel(
          borderRadius: pillRadius,
          padding: EdgeInsets.zero,
          backgroundOpacity: 0.08,
          showStroke: true,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: pillRadius),
              backgroundColor: Colors.transparent,
            ),
            onPressed: onPressed,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                    FontFeature.liningFigures(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

