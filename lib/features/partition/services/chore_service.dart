import 'package:flutter/foundation.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/chore_auto_assign_response_model.dart';
import 'package:partition_app/features/partition/models/schedule_response_model.dart';

class ChoreService {
  final ApiClient _apiClient = ApiClient();

  /// 집안일 자동 배정 요청
  /// - API: POST /api/chores/auto-assign
  /// - Body: { startDate, endDate, choreTypes[] }
  /// - choreTypes: DISH_WASHING, COOKING, LAUNDRY, FOODTRASH, TRASH, RECYCLING, VACUUM, MOPPING, WINDOW, BATHROOM, FRIDGE
  Future<ChoreAutoAssignResponseModel> autoAssignChores({
    required String startDate,
    required String endDate,
    required List<String> choreTypes, // enum 값들 (DISH_WASHING 등)
  }) async {
    try {
      // 디버깅: API 요청 데이터 확인
      debugPrint('📤 집안일 자동 배정 API 호출');
      debugPrint('  - 엔드포인트: ${AppConfig.choresAutoAssignEndpoint}');
      debugPrint('  - Request Body:');
      debugPrint('    * startDate: $startDate');
      debugPrint('    * endDate: $endDate');
      debugPrint('    * choreTypes: $choreTypes');
      debugPrint('    * choreTypes 개수: ${choreTypes.length}');
      
      // API 명세에 따라 body에 모든 데이터 포함
      final requestBody = {
        'startDate': startDate,
        'endDate': endDate,
        'choreTypes': choreTypes, // enum 값 배열
      };
      
      debugPrint('  - 전체 Request Body: $requestBody');
      
      final response = await _apiClient.post(
        AppConfig.choresAutoAssignEndpoint,
        data: requestBody,
      );

      debugPrint('✅ API 응답 받음');
      debugPrint('  - 응답 데이터: ${response.data}');

      return ChoreAutoAssignResponseModel.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ API 호출 실패: $e');
      throw ApiException.fromDioError(e);
    }
  }

  /// 집안일 완료·미완료 토글 (일간 캘린더)
  /// - 완료: PATCH /api/chores/{choreId}/complete (본문 없음)
  /// - 미완료: PATCH /api/chores/{choreId} … `{ "isCompleted": false }`
  Future<ScheduleResponseModel> updateChoreCompletion({
    required int choreId,
    required bool isCompleted,
  }) async {
    try {
      if (isCompleted) {
        final endpoint = AppConfig.choreCompleteEndpoint.replaceAll(
          '{choreId}',
          choreId.toString(),
        );
        final response = await _apiClient.patch(endpoint);
        return ScheduleResponseModel.fromJson(response.data);
      }

      final endpoint = AppConfig.choreDetailEndpoint.replaceAll(
        '{choreId}',
        choreId.toString(),
      );
      final response = await _apiClient.patch(
        endpoint,
        data: {'isCompleted': false},
      );
      return ScheduleResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

