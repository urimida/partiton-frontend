import 'package:dio/dio.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';

/// FCM 토큰 등록·갱신 — `PATCH /api/users/me/fcm-token` (`{ "fcmToken": "..." }`), 회원 인증 필요.
class UserFcmService {
  final ApiClient _apiClient = ApiClient();

  /// 백엔드가 필드명을 다르게 받으면 여기만 수정
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final response = await _apiClient.patch(
        AppConfig.userFcmTokenEndpoint,
        data: {'fcmToken': fcmToken},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(message: 'FCM 토큰 등록 응답 형식이 올바르지 않습니다.');
      }
      if (data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? 'FCM 토큰 등록에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
