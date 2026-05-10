import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/supply_category_model.dart';
import 'package:partition_app/features/partition/models/supply_purchase_model.dart';

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
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        final apiCode = body['code']?.toString();
        if (apiCode == 'SUPPLY_1005' ||
            (status == 404 && body['isSuccess'] == false)) {
          final msg = body['message']?.toString();
          throw ApiException(
            message: msg ?? '등록된 카테고리가 없습니다.',
            statusCode: status ?? 404,
            originalError: e,
          );
        }
      }
      throw ApiException.fromDioError(e);
    }
  }

  /// 공용 구매 물품 **정산 대상** 조회
  /// `GET /api/supplies/settlement/purchases?startDate=yyyy-MM-dd&endDate=yyyy-MM-dd`
  /// (미정산 `UNSETTLED` 등 — 응답 형식은 [SupplyPurchasesListResult]).
  Future<SupplyPurchasesListResult> fetchSettlementPurchases({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.suppliesPurchasesSettlementListEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
        // 명세: GET — Dio 기본이 GET이나, 인프라 이슈 대비해 명시합니다.
        options: Options(method: 'GET'),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '정산 목록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '정산 목록 조회에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        return const SupplyPurchasesListResult(totalCount: 0, purchases: []);
      }
      return SupplyPurchasesListResult.fromJson(raw);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 공동 구매 물품 목록 조회 (GET /supplies/purchases?startDate&endDate)
  Future<SupplyPurchasesListResult> fetchPurchases({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.suppliesPurchasesEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '구매 목록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '구매 목록 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        return const SupplyPurchasesListResult(totalCount: 0, purchases: []);
      }
      return SupplyPurchasesListResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 공동 구매 물품 수동 추가 (POST /supplies/purchases)
  Future<SupplyPurchaseResult> createPurchase({
    required String itemName,
    required String purchaseDate,
    required int amount,
    required int quantity,
    required String category,
    required String subCategory,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.suppliesPurchasesEndpoint,
        data: {
          'itemName': itemName,
          'purchaseDate': purchaseDate,
          'amount': amount,
          'quantity': quantity,
          'category': category,
          'subCategory': subCategory,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '구매 등록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '구매 등록에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '구매 등록 결과가 없습니다.');
      }
      return SupplyPurchaseResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 공용 물품 구매 기록 삭제 (DELETE `/supplies/purchases/{purchaseId}`)
  Future<void> deletePurchase(int purchaseId) async {
    if (purchaseId <= 0) {
      throw ApiException(message: '삭제할 구매 기록이 없어요.');
    }
    try {
      final response = await _apiClient.delete(
        '${AppConfig.suppliesPurchasesEndpoint}/$purchaseId',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['isSuccess'] == false) {
        throw ApiException(
          message: data['message']?.toString() ?? '구매 기록 삭제에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 공용 물품 구매 기록 수정 (PATCH /supplies/purchases/{purchaseId})
  ///
  /// 서버는 필드가 없으면 유지·부분 갱신이 가능하지만, 앱은 폼 저장 시
  /// 변경된 값이 반영되도록 [itemName]~[subCategory]를 함께 보냅니다.
  Future<SupplyPurchaseResult> updatePurchase({
    required int purchaseId,
    required String itemName,
    required String purchaseDate,
    required int amount,
    required int quantity,
    required String category,
    required String subCategory,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${AppConfig.suppliesPurchasesEndpoint}/$purchaseId',
        data: {
          'itemName': itemName,
          'purchaseDate': purchaseDate,
          'amount': amount,
          'quantity': quantity,
          'category': category,
          'subCategory': subCategory,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '구매 수정 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '구매 기록 수정에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '구매 수정 결과가 없습니다.');
      }
      return SupplyPurchaseResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 공용 구매 물품 **정산 요청**
  /// `POST /api/supplies/settlement` — 본문 `{ purchaseIds, memberIds }`
  Future<SupplySettlementRequestResult> requestSettlement({
    required List<int> purchaseIds,
    required List<int> memberIds,
  }) async {
    if (purchaseIds.isEmpty) {
      throw ApiException(message: '정산할 구매 기록을 선택해주세요.');
    }
    if (memberIds.isEmpty) {
      throw ApiException(message: '정산 대상 멤버를 선택해주세요.');
    }
    try {
      final response = await _apiClient.post(
        AppConfig.suppliesSettlementRequestEndpoint,
        data: {
          'purchaseIds': purchaseIds,
          'memberIds': memberIds,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '정산 요청 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '정산 요청에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '정산 요청 결과가 없습니다.');
      }
      return SupplySettlementRequestResult.fromJson(raw);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 정산 **상세** 조회 (GET `/supplies/settlement/{settlementId}`)
  Future<SupplySettlementDetailResult> fetchSettlementDetail(
    int settlementId,
  ) async {
    if (settlementId <= 0) {
      throw ApiException(message: '유효하지 않은 정산입니다.');
    }
    try {
      final response = await _apiClient.get(
        AppConfig.suppliesSettlementDetailPath(settlementId),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '정산 상세 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '정산 상세 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '정산 상세 결과가 없습니다.');
      }
      return SupplySettlementDetailResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 정산 **완료** 처리 (PATCH `/supplies/settlement/{settlementId}/confirm`)
  Future<SupplySettlementConfirmResult> confirmSettlement(
    int settlementId,
  ) async {
    if (settlementId <= 0) {
      throw ApiException(message: '유효하지 않은 정산입니다.');
    }
    try {
      final response = await _apiClient.patch(
        AppConfig.suppliesSettlementConfirmPath(settlementId),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '정산 완료 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '정산 완료 처리에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '정산 완료 결과가 없습니다.');
      }
      return SupplySettlementConfirmResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 영수증 이미지 분석 (POST multipart `image` — jpg, jpeg, png)
  Future<ReceiptImageAnalysisResult> analyzeReceiptImage(XFile file) async {
    final path = file.path;
    var filename = file.name;
    if (filename.isEmpty) {
      final lower = path.toLowerCase();
      if (lower.endsWith('.png')) {
        filename = 'receipt.png';
      } else {
        filename = 'receipt.jpg';
      }
    }
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          path,
          filename: filename,
        ),
      });
      final response = await _apiClient.postMultipart(
        AppConfig.suppliesPurchasesImageEndpoint,
        data: form,
        receiveTimeout: const Duration(minutes: 2),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '영수증 분석 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '영수증 분석에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        return const ReceiptImageAnalysisResult(items: []);
      }
      return ReceiptImageAnalysisResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
