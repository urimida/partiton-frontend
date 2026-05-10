import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/insight_query_models.dart';
import 'package:partition_app/features/partition/services/insight_voice_multipart.dart';

/// 인사이트 질의 API — PARTITION_AI FastAPI ([AppConfig.insightsAiQueryUrl] 등).
class InsightsQueryService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _bodyForText({
    required String question,
    String? startDate,
    String? endDate,
  }) {
    final m = <String, dynamic>{'question': question};
    if (startDate != null) m['startDate'] = startDate;
    if (endDate != null) m['endDate'] = endDate;
    return m;
  }

  InsightQueryResult _parseOk(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: '인사이트 응답 형식이 올바르지 않습니다.');
    }
    return InsightQueryResult.fromJson(data);
  }

  Future<InsightQueryResult> queryText({
    required String question,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.insightsAiQueryUrl,
        data: _bodyForText(
          question: question,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      return _parseOk(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<InsightQueryResult> queryVoice({
    required String audioFilePath,
    String? question,
    String? startDate,
    String? endDate,
  }) async {
    final form = FormData();
    form.files.add(
      MapEntry(
        'audio',
        await buildInsightVoiceMultipart(audioFilePath),
      ),
    );
    if (question != null && question.trim().isNotEmpty) {
      form.fields.add(MapEntry('question', question.trim()));
    }
    if (startDate != null) {
      form.fields.add(MapEntry('startDate', startDate));
    }
    if (endDate != null) {
      form.fields.add(MapEntry('endDate', endDate));
    }

    try {
      final response = await _apiClient.postMultipart(
        AppConfig.insightsAiQueryVoiceUrl,
        data: form,
        receiveTimeout: const Duration(minutes: 3),
      );
      return _parseOk(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
