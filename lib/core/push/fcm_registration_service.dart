import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/features/auth/services/user_fcm_service.dart';

/// 푸시 탭으로 앱이 열렸을 때(백그라운드·종료) 상위에서 구독합니다. 중복 등록 방지.
typedef FcmRemoteOpenHandler = void Function(RemoteMessage message);

/// 백그라운드 진입점 (최상위 함수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// 앱 시작 시 Firebase 초기화 + `onTokenRefresh` 로 서버 PATCH
/// 로그인된 경우에만 [registerIfLoggedIn]으로 단말 토큰을 서버로 보냄
class FcmRegistrationService {
  FcmRegistrationService._();

  static bool _firebaseCoreReady = false;
  static bool _listenersAttached = false;
  static bool _remoteOpenListenerAttached = false;
  static String? _lastSentFcmToken;

  static Future<void> initializePlugin() async {
    try {
      await Firebase.initializeApp();
      _firebaseCoreReady = true;
    } catch (e, st) {
      debugPrint('[FCM] Firebase.initializeApp 실패(google-services.json 등 설정 확인): $e');
      debugPrint('$st');
      _firebaseCoreReady = false;
      return;
    }

    if (!_listenersAttached) {
      _listenersAttached = true;
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) => unawaited(_pushTokenToServer(newToken)),
        onError: (Object e) => debugPrint('[FCM] onTokenRefresh 오류: $e'),
      );
    }
  }

  /// 로그아웃 시 마지막 전송 토큰 캐시 초기화
  static void onLogout() {
    _lastSentFcmToken = null;
  }

  /// `FirebaseMessaging.onMessageOpenedApp` — 한 번만 구독합니다.
  static void attachRemoteOpenListener(FcmRemoteOpenHandler handler) {
    if (_remoteOpenListenerAttached) return;
    _remoteOpenListenerAttached = true;
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  /// 로컬 JWT가 있을 때만 FCM 토큰을 받아 서버에 PATCH
  static Future<void> registerIfLoggedIn() async {
    if (!_firebaseCoreReady) return;
    try {
      final jwt = await StorageService.getToken();
      if (jwt == null || jwt.isEmpty) return;

      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _pushTokenToServer(token);
      }
    } catch (e, st) {
      debugPrint('[FCM] registerIfLoggedIn 실패: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _pushTokenToServer(String token) async {
    try {
      final jwt = await StorageService.getToken();
      if (jwt == null || jwt.isEmpty) return;
      if (_lastSentFcmToken == token) return;

      await UserFcmService().updateFcmToken(token);
      _lastSentFcmToken = token;
      debugPrint('[FCM] 서버에 토큰 등록 완료(길이 ${token.length})');
    } catch (e, st) {
      debugPrint('[FCM] 서버 토큰 PATCH 실패: $e');
      debugPrint('$st');
    }
  }
}
