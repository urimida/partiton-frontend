import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/partition_report_model.dart';

/// 파티션 리포트 GET `/reports`
class ReportService {
  final ApiClient _apiClient = ApiClient();

  Future<PartitionReportResult> fetchReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.reportsEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '파티션 리포트 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message:
              data['message']?.toString() ?? '파티션 리포트 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        return const PartitionReportResult(
          chores: <ChoreReportEntry>[],
          supplies: ReportSupplies.empty,
          bills: <ReportBillDelta>[],
          reservations: <ReservationReportEntry>[],
        );
      }
      return PartitionReportResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// GET `/reports/settlement` — 정산 완료 공용물품·공과금
  Future<SettlementReportResult> fetchSettlementReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.reportsSettlementEndpoint,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '정산 리포트 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message:
              data['message']?.toString() ?? '정산 리포트 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        return SettlementReportResult.empty;
      }
      return SettlementReportResult.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
