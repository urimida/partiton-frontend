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

  /// 공과금 **정산 요청** — `POST /api/bills/settlement` (`billIds`, `memberIds`).
  /// 푸시 알림은 서버에서 발송; 단말은 `PATCH /users/me/fcm-token`으로 FCM 토큰을 등록해야 함.
  Future<BillSettlementRequestResult> requestBillSettlement({
    required List<int> billIds,
    required List<int> memberIds,
  }) async {
    if (billIds.isEmpty) {
      throw ApiException(message: '정산할 공과금을 선택해주세요.');
    }
    if (memberIds.isEmpty) {
      throw ApiException(message: '정산 대상 멤버를 선택해주세요.');
    }
    try {
      final response = await _apiClient.post(
        AppConfig.billsSettlementRequestEndpoint,
        data: {
          'billIds': billIds,
          'memberIds': memberIds,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 요청 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 정산 요청에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 요청 결과가 없습니다.');
      }
      return BillSettlementRequestResult.fromJson(raw);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 정산 **상세** 조회 (GET `/bills/settlement/{settlementId}`)
  Future<BillSettlementDetailResult> fetchBillSettlementDetail(
    int settlementId,
  ) async {
    if (settlementId <= 0) {
      throw ApiException(message: '유효하지 않은 정산입니다.');
    }
    try {
      final response = await _apiClient.get(
        AppConfig.billsSettlementDetailPath(settlementId),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 상세 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 정산 상세 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 상세 결과가 없습니다.');
      }
      return BillSettlementDetailResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 정산 **완료** 처리 (PATCH `/bills/settlement/{settlementId}/confirm`)
  Future<BillSettlementConfirmResult> confirmBillSettlement(
    int settlementId,
  ) async {
    if (settlementId <= 0) {
      throw ApiException(message: '유효하지 않은 정산입니다.');
    }
    try {
      final response = await _apiClient.patch(
        AppConfig.billsSettlementConfirmPath(settlementId),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 완료 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '공과금 정산 완료 처리에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '공과금 정산 완료 결과가 없습니다.');
      }
      return BillSettlementConfirmResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
