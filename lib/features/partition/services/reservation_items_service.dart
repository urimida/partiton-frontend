import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/reservation_item_model.dart';

/// 예약 대상 API (`GET`·`POST`·`PATCH`·`DELETE` `/api/reservations/items`)
class ReservationItemsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReservationItem>> fetchItems() async {
    try {
      final response =
          await _apiClient.get(AppConfig.reservationsItemsEndpoint);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 대상 목록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message:
              data['message']?.toString() ?? '예약 대상 목록 조회에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! List) return [];
      return raw
          .map((e) => ReservationItem.fromJson(e as Map<String, dynamic>))
          .where((item) => item.itemId > 0 && item.name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReservationItemCreated> createItem(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiException(message: '예약 대상 이름을 입력해주세요.');
    }
    try {
      final response = await _apiClient.post(
        AppConfig.reservationsItemsEndpoint,
        data: <String, dynamic>{'name': trimmed},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 대상 추가 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '예약 대상 추가에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '예약 대상 추가 결과가 비어 있습니다.');
      }
      return ReservationItemCreated.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReservationItemUpdated> updateItem(int itemId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiException(message: '예약 대상 이름을 입력해주세요.');
    }
    try {
      final response = await _apiClient.patch(
        AppConfig.reservationsItemPath(itemId),
        data: <String, dynamic>{'name': trimmed},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 대상 수정 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '예약 대상 수정에 실패했습니다.',
        );
      }
      final raw = data['result'];
      if (raw is! Map<String, dynamic>) {
        throw ApiException(message: '예약 대상 수정 결과가 비어 있습니다.');
      }
      return ReservationItemUpdated.fromJson(raw);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    try {
      final response = await _apiClient.delete(
        AppConfig.reservationsItemsEndpoint,
        data: <String, dynamic>{
          'itemIds': itemIds,
        },
      );
      final data = response.data;
      if (data == null || data == '') {
        return;
      }
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '예약 대상 삭제 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '예약 대상 삭제에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
