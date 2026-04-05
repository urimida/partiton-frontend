import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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

  /// 그룹(가구) 참여
  Future<HouseholdResponseModel> joinHousehold({
    required String inviteCode,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.householdsJoinEndpoint,
        data: {
          'inviteCode': inviteCode,
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

  /// 그룹(가구)에 속한 멤버 이름 목록. 정산 시 참여자 선택에 사용.
  /// API 형식: `{ isSuccess, result: [ { name } ] }` 또는 `result.members` 등 유연히 파싱.
  Future<List<String>> fetchHouseholdMemberNames() async {
    try {
      final response = await _apiClient.get(AppConfig.householdMembersEndpoint);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return _fallbackHouseholdMemberNames();
      }
      if (data['isSuccess'] == false) {
        return _fallbackHouseholdMemberNames();
      }
      final dynamic result = data['result'];
      List<dynamic>? list;
      if (result is List) {
        list = result;
      } else if (result is Map<String, dynamic>) {
        final m = result['members'] ??
            result['memberList'] ??
            result['users'] ??
            result['userList'];
        if (m is List) list = m;
      }
      if (list == null || list.isEmpty) {
        return _fallbackHouseholdMemberNames();
      }
      final names = <String>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          final n = e['name'] as String? ??
              e['nickname'] as String? ??
              e['userName'] as String?;
          if (n != null && n.trim().isNotEmpty) {
            names.add(n.trim());
          }
        }
      }
      if (names.isEmpty) {
        return _fallbackHouseholdMemberNames();
      }
      return names;
    } catch (e) {
      debugPrint('fetchHouseholdMemberNames: $e');
      return _fallbackHouseholdMemberNames();
    }
  }

  Future<List<String>> _fallbackHouseholdMemberNames() async {
    final names = <String>[];
    final u = await getUserInfo();
    if (u?.name != null && u!.name!.trim().isNotEmpty) {
      names.add(u.name!.trim());
    }
    final local = await StorageService.getUserName();
    if (local != null && local.trim().isNotEmpty) {
      final t = local.trim();
      if (!names.contains(t)) names.add(t);
    }
    for (var i = names.length; i < 4; i++) {
      names.add('그룹원 ${i + 1}');
    }
    return names;
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
        
        debugPrint('📥 /users/me API 응답 받음:');
        debugPrint('  - isSuccess: ${data['isSuccess']}');
        debugPrint('  - 전체 응답: $data');
        
        // isSuccess가 false인 경우 null 반환
        if (data['isSuccess'] == false) {
          debugPrint('  ⚠️ isSuccess가 false입니다');
          return null;
        }
        
        if (data['result'] != null) {
          final result = data['result'];
          debugPrint('  - result 타입: ${result.runtimeType}');
          
          if (result is Map<String, dynamic>) {
            debugPrint('  - result 내용: $result');
            debugPrint('  - result에 id 있음: ${result.containsKey('id')}');
            debugPrint('  - result에 email 있음: ${result.containsKey('email')}');
            debugPrint('  - result에 name 있음: ${result.containsKey('name')}');
            debugPrint('  - result의 name 값: ${result['name']}');
            
            final userModel = UserModel.fromJson(result);
            debugPrint('  ✅ UserModel 생성 성공');
            debugPrint('    - id: ${userModel.id}');
            debugPrint('    - email: ${userModel.email}');
            debugPrint('    - name: ${userModel.name}');
            
            return userModel;
          }
        }
        // result가 없으면 직접 UserModel로 변환 시도
        debugPrint('  ⚠️ result가 없거나 Map이 아닙니다. 직접 변환 시도...');
        try {
          debugPrint('  - 직접 변환 시도: $data');
          final userModel = UserModel.fromJson(data);
          debugPrint('  ✅ 직접 변환 성공');
          return userModel;
        } catch (e) {
          debugPrint('  ❌ 직접 변환 실패: $e');
          return null;
        }
      }
      debugPrint('  ❌ 응답이 Map이 아닙니다: ${response.data.runtimeType}');
      return null;
    } catch (e) {
      // 서버 에러(500 등) 발생 시 null 반환 (로컬 스토리지 fallback 사용)
      // 예외를 던지지 않고 조용히 실패 처리
      debugPrint('❌ /users/me API 호출 실패: $e');
      if (e is DioException && e.response != null) {
        debugPrint('  - 에러 응답 상태 코드: ${e.response!.statusCode}');
        debugPrint('  - 에러 응답 데이터: ${e.response!.data}');
      }
      return null;
    }
  }
}

