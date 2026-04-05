import 'package:flutter/material.dart';
import 'package:partition_app/shared/widgets/glassmorphism_widget.dart';

/// 재사용 가능한 글래스모피즘 패널
/// 캘린더 등에서 사용하던 스타일을 컴포넌트화
class FrostedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double backgroundOpacity;
  final bool showStroke;
  final Gradient? strokeGradient;
  final Color? borderColor;

  const FrostedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.backgroundOpacity = 0.0,
    this.showStroke = true,
    this.strokeGradient = const RadialGradient(
      center: Alignment(0.2535, -0.6739),
      radius: 2.6345,
      colors: [
        Color.fromRGBO(255, 255, 255, 0.12),
        Color.fromRGBO(255, 255, 255, 0.0),
      ],
      stops: [0.0, 1.0],
    ),
    this.borderColor = const Color.fromRGBO(255, 255, 255, 0.25),
  });

  @override
  Widget build(BuildContext context) {
    // 부모가 유한한 가로·세로를 줄 때만 width/height를 넘겨 Glassmorphism이 StackFit.expand 경로를 타게 함.
    // (세로만 무한인 Stack + Column/Expanded/ListView 조합에서 무한 높이 붕괴 방지 — 홈 캘린더 등)
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final useFixed = w.isFinite &&
            w > 0 &&
            h.isFinite &&
            h > 0 &&
            constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight;
        return GlassmorphismWidget(
          width: useFixed ? w : null,
          height: useFixed ? h : null,
          borderRadius: borderRadius,
          padding: padding,
          backgroundOpacity: backgroundOpacity,
          showStroke: showStroke,
          strokeGradient: strokeGradient,
          borderColor: borderColor,
          child: child,
        );
      },
    );
  }
}

