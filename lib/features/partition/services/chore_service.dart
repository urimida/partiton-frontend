import 'package:flutter/foundation.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/chore_auto_assign_response_model.dart';

class ChoreService {
  final ApiClient _apiClient = ApiClient();

  /// 집안일 자동 배정 요청
  /// - API: POST /api/chores/auto-assign
  /// - Query: startDate, endDate (YYYY-MM-DD)
  /// - Body: selectedChores (선택된 집안일 목록)
  Future<ChoreAutoAssignResponseModel> autoAssignChores({
    required String startDate,
    required String endDate,
    required List<String> selectedChores,
  }) async {
    try {
      // 디버깅: API 요청 데이터 확인
      debugPrint('📤 집안일 자동 배정 API 호출');
      debugPrint('  - 엔드포인트: ${AppConfig.choresAutoAssignEndpoint}');
      debugPrint('  - Query Parameters:');
      debugPrint('    * startDate: $startDate');
      debugPrint('    * endDate: $endDate');
      debugPrint('  - Request Body:');
      debugPrint('    * chores: $selectedChores');
      debugPrint('    * chores 개수: ${selectedChores.length}');
      
      // API 명세에 따라 선택된 집안일만 전달
      // 서버는 이 목록에 있는 집안일만 배정함
      final requestBody = {
        'chores': selectedChores, // 선택된 집안일 이름 목록만 전달
      };
      
      debugPrint('  - 전체 Request Body: $requestBody');
      debugPrint('  - ⚠️ 중요: 선택된 집안일만 배정됩니다!');
      
      final response = await _apiClient.post(
        AppConfig.choresAutoAssignEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
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
}

