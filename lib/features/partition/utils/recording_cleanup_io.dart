import 'dart:io';

/// 로컬 녹음 파일 삭제 (모바일·데스크톱).
Future<void> discardLocalRecording(String? path) async {
  if (path == null) return;
  try {
    await File(path).delete();
  } catch (_) {}
}
