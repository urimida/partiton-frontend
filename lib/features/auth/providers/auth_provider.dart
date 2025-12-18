import 'package:flutter/foundation.dart';
import 'package:partition_app/features/auth/models/user_model.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/shared/utils/debug_helper.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    DebugHelper.log('🔐 로그인 시도 시작');
    DebugHelper.log('이메일: $email');
    
    _setLoading(true);
    _clearError();

    try {
      final authResponse = await _authService.login(email, password);
      _user = authResponse.user;
      DebugHelper.log('✅ 로그인 성공');
      DebugHelper.log('사용자 ID: ${_user?.id}');
      DebugHelper.log('사용자 이메일: ${_user?.email}');
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('로그인 중 오류가 발생했습니다.');
      _setLoading(false);
      return false;
    }
  }

  /// 카카오 로그인
  /// 명세서에 따라 kakaoAccessToken만 전송
  /// 반환값: (성공 여부, userRole)
  Future<({bool success, String? userRole})> loginWithKakao({
    required String kakaoAccessToken,
  }) async {
    DebugHelper.log('🔐 카카오 로그인 시도 시작');
    DebugHelper.log('카카오 Access Token: ${kakaoAccessToken.substring(0, 20)}...');
    
    _setLoading(true);
    _clearError();

    try {
      final kakaoAuthResponse = await _authService.loginWithKakao(
        kakaoAccessToken: kakaoAccessToken,
      );
      
      DebugHelper.log('✅ 카카오 로그인 성공');
      String? userRole;
      if (kakaoAuthResponse.result != null) {
        DebugHelper.log('Access Token 저장 완료');
        DebugHelper.log('Refresh Token 저장 완료');
        DebugHelper.log('Access Token 만료 시간: ${kakaoAuthResponse.result!.accessTokenExpiresIn}ms');
        userRole = kakaoAuthResponse.result!.userRole;
        DebugHelper.log('User Role: $userRole');
      }
      
      _setLoading(false);
      return (success: true, userRole: userRole);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return (success: false, userRole: null);
    } catch (e) {
      DebugHelper.log('❌ 카카오 로그인 오류: $e');
      _setError('카카오 로그인 중 오류가 발생했습니다.');
      _setLoading(false);
      return (success: false, userRole: null);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final authResponse = await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      _user = authResponse.user;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('회원가입 중 오류가 발생했습니다.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _clearError();
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      _user = null;
    }
    notifyListeners();
  }

  /// 디버그용: 더미 유저로 로그인 상태 설정
  void setMockUserForDebug() {
    _user = UserModel(
      id: 'debug-user-001',
      email: 'debug@example.com',
      name: 'Debug User',
      createdAt: DateTime.now(),
    );
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

