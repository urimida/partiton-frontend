import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/reservation_booking_model.dart';

/// 예약 목록 조회·등록·삭제 (`GET`·`POST`·`DELETE /api/reservations`)
class ReservationsService {
  final ApiClient _apiClient = ApiClient();

  static String _yyyyMmDd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// API 요청용 `LocalDateTime` 문자열 (분 단위 포함, `yyyy-MM-ddTHH:mm:ss`)
  static String toApiLocalDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    return '${d.year}-${two(d.month)}-${two(d.day)}T'
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// `GET ?startDate&endDate` (yyyy-MM-dd)
  Future<List<ReservationListEntry>> fetchReservations({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    try {
      final response = await _apiClient.get(
        AppConfig.reservationsEndpoint,
        queryParameters: <String, dynamic>{
          'startDate': _yyyyMmDd(s),
          'endDate': _yyyyMmDd(e),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 목록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '예약 목록 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! List) return [];
      return raw
          .map((e) => ReservationListEntry.fromJson(e as Map<String, dynamic>))
          .where((r) => r.reservationId > 0 && r.itemName.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReservationCreated> createReservation({
    required int itemId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.reservationsEndpoint,
        data: <String, dynamic>{
          'itemId': itemId,
          'startTime': toApiLocalDateTime(startTime),
          'endTime': toApiLocalDateTime(endTime),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 등록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '예약 등록에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '예약 등록 결과가 비어 있습니다.');
      }
      return ReservationCreated.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 본문 `{ reservationIds: [...] }` — 다중 삭제
  Future<void> deleteReservations(List<int> reservationIds) async {
    if (reservationIds.isEmpty) {
      throw ApiException(message: '삭제할 예약을 선택해주세요.');
    }
    try {
      final response = await _apiClient.delete(
        AppConfig.reservationsEndpoint,
        data: <String, dynamic>{
          'reservationIds': reservationIds,
        },
      );
      final data = response.data;
      if (data == null || data == '') {
        return;
      }
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 삭제 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '예약 삭제에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
