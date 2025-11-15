import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/core/storage/storage_service.dart';
import 'package:partition_app/features/auth/models/auth_response_model.dart';
import 'package:partition_app/features/auth/models/user_model.dart';

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
}

