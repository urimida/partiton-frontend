import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:partition_app/shared/widgets/frosted_panel.dart';

/// 앱 전반에서 사용할 기본 버튼 스타일 (버튼 1)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final double width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.width = 360,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius pillRadius = BorderRadius.circular(height / 2);
    final active = enabled;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: FrostedPanel(
          borderRadius: pillRadius,
          padding: EdgeInsets.zero,
          backgroundOpacity: active ? 0.08 : 0.04,
          showStroke: true,
          borderColor: active
              ? const Color.fromRGBO(255, 255, 255, 0.25)
              : const Color.fromRGBO(160, 160, 170, 0.55),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withOpacity(0.38),
              shape: RoundedRectangleBorder(borderRadius: pillRadius),
              backgroundColor: Colors.transparent,
            ),
            onPressed: active ? onPressed : null,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : Colors.white.withOpacity(0.42),
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontFeatures: const [
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

