import 'package:flutter/material.dart';
import 'package:partition_app/features/partition/theme/partition_ui_tokens.dart';
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
    this.height = PartitionUiTokens.actionButtonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius pillRadius =
        BorderRadius.circular(PartitionUiTokens.actionButtonRadius);
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
              ? PartitionUiTokens.actionButtonBorder
              : PartitionUiTokens.actionButtonBorderDisabled,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: PartitionUiTokens.actionText,
              disabledForegroundColor: PartitionUiTokens.actionTextDisabled,
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
                      ? PartitionUiTokens.actionText
                      : PartitionUiTokens.actionTextDisabled,
                  fontFamily: 'Pretendard Variable',
                  fontSize: PartitionUiTokens.actionFontSize,
                  fontWeight: PartitionUiTokens.actionWeight,
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

