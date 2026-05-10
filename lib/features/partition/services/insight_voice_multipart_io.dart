import 'dart:io';

import 'package:dio/dio.dart';

/// 모바일·데스크톱: 디스크 경로에서 multipart `audio` 필드 생성.
Future<MultipartFile> buildInsightVoiceMultipart(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('녹음 파일을 찾을 수 없습니다.');
  }
  return MultipartFile.fromFile(
    path,
    filename: path.replaceAll(r'\', '/').split('/').last,
  );
}
