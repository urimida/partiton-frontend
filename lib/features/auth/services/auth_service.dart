import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/features/auth/models/auth_response_model.dart';
import 'package:partition_app/features/auth/models/user_model.dart';
import 'package:partition_app/features/auth/models/kakao_auth_response_model.dart';
import 'package:partition_app/features/auth/models/update_name_response_model.dart';
import 'package:partition_app/features/auth/models/household_response_model.dart';
import 'package:partition_app/features/auth/models/preference_response_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        AppConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // 토큰 저장
      await StorageService.setToken(authResponse.token);
      await StorageService.setUserId(authResponse.user.id);

      return authResponse;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.registerEndpoint,
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      
      // 토큰 저장
      await StorageService.setToken(authResponse.token);
      await StorageService.setUserId(authResponse.user.id);

      return authResponse;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await StorageService.clear();
  }

  Future<bool> isAuthenticated() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// 카카오 로그인
  Future<KakaoAuthResponseModel> loginWithKakao({
    required String kakaoAccessToken,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.kakaoLoginEndpoint,
        data: {
          'kakaoAccessToken': kakaoAccessToken,
        },
      );

      final kakaoAuthResponse = KakaoAuthResponseModel.fromJson(response.data);
      
      // 토큰 저장
      if (kakaoAuthResponse.result != null) {
        await StorageService.setToken(kakaoAuthResponse.result!.accessToken);
        await StorageService.setRefreshToken(kakaoAuthResponse.result!.refreshToken);
      }

      return kakaoAuthResponse;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 사용자 이름 업데이트
  Future<UpdateNameResponseModel> updateUserName({
    required String name,
  }) async {
    try {
      final response = await _apiClient.patch(
        AppConfig.updateUserNameEndpoint,
        data: {
          'name': name,
        },
      );

      return UpdateNameResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 그룹(가구) 생성
  Future<HouseholdResponseModel> createHousehold({
    required String name,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.householdsEndpoint,
        data: {
          'name': name,
        },
      );

      return HouseholdResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 선호도 등록
  Future<PreferenceResponseModel> registerPreferences({
    required List<PreferenceItem> preferences,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.userPreferencesEndpoint,
        data: {
          'preferences': preferences.map((p) => p.toJson()).toList(),
        },
      );

      return PreferenceResponseModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// 사용자 정보 조회
  /// 서버에서 사용자 정보를 가져오려고 시도하지만, 실패해도 예외를 던지지 않음
  Future<UserModel?> getUserInfo() async {
    try {
      final response = await _apiClient.get(
        AppConfig.updateUserNameEndpoint,
      );

      // 응답 형식에 따라 UserModel로 변환
      // 일반적으로 { result: { id, email, name, ... } } 형식일 것으로 예상
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // isSuccess가 false인 경우 null 반환
        if (data['isSuccess'] == false) {
          return null;
        }
        
        if (data['result'] != null) {
          final result = data['result'];
          if (result is Map<String, dynamic>) {
            return UserModel.fromJson(result);
          }
        }
        // result가 없으면 직접 UserModel로 변환 시도
        try {
          return UserModel.fromJson(data);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      // 서버 에러(500 등) 발생 시 null 반환 (로컬 스토리지 fallback 사용)
      // 예외를 던지지 않고 조용히 실패 처리
      return null;
    }
  }
}

