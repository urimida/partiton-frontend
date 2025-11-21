import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:partition_app/shared/utils/app_colors.dart';

/// 글래스모피즘 효과를 적용한 위젯
/// 재사용 가능한 컴포넌트
class GlassmorphismWidget extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool showStroke;
  final double backgroundOpacity;
  final Gradient? strokeGradient;
  final Color? borderColor;

  const GlassmorphismWidget({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.showStroke = true,
    this.backgroundOpacity = 0.1,
    this.strokeGradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderRadius ?? BorderRadius.circular(0);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: border,
      ),
      child: ClipRRect(
        borderRadius: border,
        child: Stack(
          children: [
            // Backdrop blur 효과 + 반투명 배경 (글래스모피즘 내부 채우기)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  // 반투명 배경 (블러와 함께 글래스모피즘 효과)
                  color: Colors.white.withOpacity(backgroundOpacity.clamp(0, 1)),
                  borderRadius: border,
                ),
              ),
            ),
            // 글래스 스트로크 (radial gradient) - 전체 영역에 오버레이로 적용
            if (showStroke) ...[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: border,
                    border: Border.all(
                      color: borderColor ?? Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: border,
                    gradient: strokeGradient ??
                        const RadialGradient(
                          // 263.45% 205.32% at 25.35% -67.39%
                          center: Alignment(0.2535, -0.6739),
                          radius: 2.6345,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 1.0), // #FFF 0%
                            Color.fromRGBO(255, 255, 255, 0.0), // rgba(255, 255, 255, 0.00) 100%
                          ],
                          stops: [0.0, 1.0],
                        ),
                  ),
                ),
              ),
            ],
            // 내용물
            Container(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// 글래스모피즘 스트로크 효과 (radial gradient)
class GlassmorphismStroke extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const GlassmorphismStroke({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          child,
          // 글래스 스트로크 그라데이션
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: const RadialGradient(
                  center: Alignment(0.25, -0.67),
                  radius: 2.0,
                  colors: [
                    Color.fromRGBO(255, 255, 255, 1.0), // #FFF
                    Color.fromRGBO(255, 255, 255, 0.0), // rgba(255, 255, 255, 0.00)
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

