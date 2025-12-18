import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/chore_auto_assign_response_model.dart';

class ChoreService {
  final ApiClient _apiClient = ApiClient();

  /// 집안일 자동 배정 요청
  /// - API: POST /api/chores/auto-assign
  /// - Query: startDate, endDate (YYYY-MM-DD)
  Future<ChoreAutoAssignResponseModel> autoAssignChores({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.choresAutoAssignEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      return ChoreAutoAssignResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

