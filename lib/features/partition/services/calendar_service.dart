import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/calendar_response_model.dart';
import 'package:partition_app/features/partition/models/daily_calendar_response_model.dart';
import 'package:partition_app/features/partition/models/schedule_response_model.dart';

class CalendarService {
  final ApiClient _apiClient = ApiClient();

  /// 월간 캘린더 조회
  Future<CalendarResponseModel> getMonthlyCalendar({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.monthlyCalendarEndpoint,
        queryParameters: {
          'year': year,
          'month': month,
        },
      );

      return CalendarResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 일간 캘린더 상세 조회
  Future<DailyCalendarResponseModel> getDailyCalendar({
    required String date, // YYYY-MM-DD 형식
  }) async {
    try {
      final response = await _apiClient.get(
        AppConfig.dailyCalendarEndpoint,
        queryParameters: {
          'date': date,
        },
      );

      return DailyCalendarResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 일정 등록
  Future<ScheduleResponseModel> registerSchedule({
    required String content,
    required String date, // YYYY-MM-DD 형식
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.schedulesEndpoint,
        data: {
          'content': content,
          'date': date,
        },
      );

      return ScheduleResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 일정 수정
  Future<ScheduleResponseModel> updateSchedule({
    required int scheduleId,
    String? content,
    String? date, // YYYY-MM-DD 형식
  }) async {
    try {
      final endpoint = AppConfig.scheduleDetailEndpoint.replaceAll('{scheduleId}', scheduleId.toString());
      final response = await _apiClient.patch(
        endpoint,
        data: {
          if (content != null) 'content': content,
          if (date != null) 'date': date,
        },
      );

      return ScheduleResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 일정 삭제
  /// - API: DELETE /api/schedules/{scheduleId}
  /// - Path Parameter: scheduleId (integer)
  /// - Response: ScheduleResponseModel (isSuccess, code, message, result, error)
  Future<ScheduleResponseModel> deleteSchedule({
    required int scheduleId,
  }) async {
    try {
      final endpoint = AppConfig.scheduleDetailEndpoint.replaceAll('{scheduleId}', scheduleId.toString());
      final response = await _apiClient.delete(endpoint);

      return ScheduleResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

