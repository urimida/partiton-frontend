import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/supply_category_model.dart';

/// 공용 소비 물품 카테고리 API
class SupplyService {
  final ApiClient _apiClient = ApiClient();

  /// 성공 시 `result` 리스트. 404·`SUPPLY_1005` 등은 메시지와 함께 예외.
  Future<List<SupplyCategoryGroup>> fetchSupplyCategories() async {
    try {
      final response =
          await _apiClient.get(AppConfig.suppliesCategoriesEndpoint);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '카테고리 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '카테고리 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw == null) return [];
      if (raw is! List) return [];
      return raw
          .map((e) => SupplyCategoryGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (code == 404 && body is Map<String, dynamic>) {
        final msg = body['message']?.toString();
        throw ApiException(
          message: msg ?? '등록된 카테고리가 없습니다.',
          statusCode: 404,
          originalError: e,
        );
      }
      throw ApiException.fromDioError(e);
    }
  }
}
