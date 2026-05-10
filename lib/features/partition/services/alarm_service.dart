import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/alarm_model.dart';

/// 알림 API — `GET /api/alarms`, 읽음 `PATCH /alarms/{id}/read`, 삭제 `DELETE /alarms/{id}`
class AlarmService {
  final ApiClient _apiClient = ApiClient();

  /// `404` + `ALARM_1001` 은 빈 목록으로 처리합니다.
  Future<AlarmListResult> fetchMyAlarms() async {
    try {
      final response = await _apiClient.get(AppConfig.alarmsEndpoint);
      return _parseResult(response.data);
    } on DioException catch (e) {
      final empty = _tryEmptyAlarmResponse(e.response);
      if (empty != null) return empty;

      throw ApiException.fromDioError(e);
    }
  }

  AlarmListResult? _tryEmptyAlarmResponse(Response<dynamic>? response) {
    if (response == null || response.statusCode != 404) return null;
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['code']?.toString() == 'ALARM_1001') {
        return const AlarmListResult(alarms: [], unreadCount: 0);
      }
    }
    return null;
  }

  AlarmListResult _parseResult(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: '알림 목록 응답 형식이 올바르지 않습니다.');
    }
    if (data['isSuccess'] != true) {
      throw ApiException(
        message: data['message']?.toString() ?? '알림 목록 조회에 실패했습니다.',
      );
    }
    final rawResult = data['result'];
    if (rawResult == null) {
      return const AlarmListResult(alarms: [], unreadCount: 0);
    }
    if (rawResult is! Map<String, dynamic>) {
      throw ApiException(message: '알림 목록 결과 형식이 올바르지 않습니다.');
    }
    final listRaw = rawResult['alarms'];
    final alarms = <AlarmItem>[];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map<String, dynamic>) {
          alarms.add(AlarmItem.fromJson(e));
        }
      }
    }
    final unread = (rawResult['unreadCount'] as num?)?.toInt() ?? 0;
    return AlarmListResult(alarms: alarms, unreadCount: unread);
  }

  /// PATCH `/alarms/{alarmId}/read`
  Future<void> markAlarmAsRead(int alarmId) async {
    try {
      final response =
          await _apiClient.patch(AppConfig.alarmsReadPath(alarmId));
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: '알림 읽음 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '알림 읽음 처리에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// DELETE `/alarms/{alarmId}`
  Future<void> deleteAlarm(int alarmId) async {
    try {
      final response =
          await _apiClient.delete(AppConfig.alarmsItemPath(alarmId));
      final data = response.data;
      if (data == null) return;
      if (data is String && data.isEmpty) return;
      if (data is! Map<String, dynamic>) return;
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '알림 삭제에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
