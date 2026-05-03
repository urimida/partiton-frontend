import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/utility_bill_model.dart';

/// 공과금 API (`/bills`, `/bills/categories`)
class UtilityBillService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UtilityBillCategory>> fetchCategories() async {
    try {
      final response =
          await _apiClient.get(AppConfig.billsCategoriesEndpoint);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 카테고리 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message:
              data['message']?.toString() ?? '공과금 카테고리 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! List) return [];
      return raw
          .map((e) => UtilityBillCategory.fromJson(e as Map<String, dynamic>))
          .where((c) => c.category.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<UtilityBillListItem>> fetchBills({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.billsEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 목록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 목록 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! List) return [];
      return raw
          .map((e) => UtilityBillListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// POST /api/bills — 수동 등록 (`payDay`: 매달 해당 일에 결제)
  Future<UtilityBillCreateResult> createBill({
    required String utilityType,
    required int payDay,
    required int amount,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'utilityType': utilityType,
        'payDay': payDay,
        'amount': amount,
        'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      };
      final response = await _apiClient.post(
        AppConfig.billsEndpoint,
        data: payload,
      );
      final data = response.data;     
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 등록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 등록에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 등록 결과가 비어 있습니다.');
      }
      return UtilityBillCreateResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// PATCH /api/bills/{billId}
  Future<UtilityBillCreateResult> updateBill({
    required int billId,
    required String utilityType,
    required int payDay,
    required int amount,
    String? note,
  }) async {
    try {
      final payload = <String, dynamic>{
        'utilityType': utilityType,
        'payDay': payDay,
        'amount': amount,
        'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      };
      final response = await _apiClient.patch(
        AppConfig.billsBillPath(billId),
        data: payload,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 수정 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 수정에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 수정 결과가 비어 있습니다.');
      }
      return UtilityBillCreateResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// DELETE /api/bills/{billId}
  Future<void> deleteBill(int billId) async {
    try {
      final response =
          await _apiClient.delete(AppConfig.billsBillPath(billId));
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 삭제 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 삭제에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET /api/bills/settlement/list
  Future<UtilityBillSettlementSummary> fetchSettlementList({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.billsSettlementListEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          message: '공과금 정산 목록 응답 형식이 올바르지 않습니다.',
        );
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message:
              data['message']?.toString() ?? '공과금 정산 목록 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 목록 결과가 비어 있습니다.');
      }
      return UtilityBillSettlementSummary.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
