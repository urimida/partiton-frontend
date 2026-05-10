import 'package:web/web.dart' as web;

/// 웹에서 `record`가 반환하는 `blob:` URL 해제.
Future<void> discardLocalRecording(String? path) async {
  if (path == null || !path.startsWith('blob:')) return;
  try {
    web.URL.revokeObjectURL(path);
  } catch (_) {}
}
