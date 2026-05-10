import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';

/// 귀가 공유 — 집 근처 도착 이벤트 전송 및 위치 공유 동의 관리
class HomeShareService {
  final ApiClient _apiClient = ApiClient();

  /// 집 근처 진입 이벤트를 서버로 전송합니다.
  /// 서버는 같은 가구(household) 룸메이트에게 FCM 푸시를 발송합니다.
  Future<void> sendNearHomeEvent() async {
    try {
      final response = await _apiClient.post(
        AppConfig.nearHomeEventEndpoint,
        data: {'eventType': 'entered_home_area'},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['isSuccess'] != true) {
        throw ApiException(
          message: data['message']?.toString() ?? '집 근처 알림 전송에 실패했습니다.',
        );
      }
    } on DioException catch (e) {
      if (_is404(e)) return; // 서버 미구현 — 로컬 기능은 정상 동작
      throw ApiException.fromDioError(e);
    }
  }

  /// 위치 공유 동의 여부를 서버에 저장합니다.
  Future<void> saveLocationConsent({required bool agreed}) async {
    try {
      await _apiClient.post(
        AppConfig.locationConsentEndpoint,
        data: {'agreed': agreed},
      );
    } on DioException catch (e) {
      if (_is404(e)) return;
      throw ApiException.fromDioError(e);
    }
  }

  /// 집 위치(위도·경도·반경)를 서버에 저장합니다.
  Future<void> saveHomeLocation({
    required double lat,
    required double lng,
    double radius = 300,
  }) async {
    try {
      await _apiClient.post(
        AppConfig.homeLocationEndpoint,
        data: {'lat': lat, 'lng': lng, 'radius': radius},
      );
    } on DioException catch (e) {
      if (_is404(e)) return;
      throw ApiException.fromDioError(e);
    }
  }

  /// 404 응답 여부 확인 (백엔드 미구현 엔드포인트 무시용)
  bool _is404(DioException e) {
    final is404 = e.response?.statusCode == 404;
    if (is404) {
      debugPrint('[HomeShareService] 서버 미구현 엔드포인트 — 로컬 저장으로 대체됩니다.');
    }
    return is404;
  }
}
