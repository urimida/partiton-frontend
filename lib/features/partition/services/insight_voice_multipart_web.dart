import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

/// 웹: `record`가 돌려준 `blob:` URL을 읽어 multipart `audio` 필드 생성.
Future<MultipartFile> buildInsightVoiceMultipart(String blobUrl) async {
  final res = await http.get(Uri.parse(blobUrl));
  if (res.statusCode != 200) {
    throw StateError('녹음 데이터를 읽지 못했습니다. (${res.statusCode})');
  }
  final rawCt =
      (res.headers['content-type'] ?? 'audio/webm').split(';').first.trim();

  var name = 'voice.webm';
  if (rawCt.contains('wav')) {
    name = 'voice.wav';
  } else if (rawCt.contains('mp4') || rawCt.contains('mpeg')) {
    name = 'voice.m4a';
  } else if (rawCt.contains('ogg')) {
    name = 'voice.ogg';
  }

  return MultipartFile.fromBytes(
    res.bodyBytes,
    filename: name,
  );
}
