import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// iOS 스타일 로딩 인디케이터
class IosLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const IosLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        radius: size != null ? size! / 2 : 10,
        color: color,
      );
    }
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );
  }
}

