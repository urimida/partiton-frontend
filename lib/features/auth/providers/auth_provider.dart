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

    // TODO: 퍼블리싱용 임시 처리 - 아무 입력이나 로그인 성공
    // 실제 백엔드 연동 시 아래 주석을 해제하고 더미 코드를 제거하세요
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 효과
    
    // 더미 사용자 생성
    _user = UserModel(
      id: 'demo-user-001',
      email: email.isNotEmpty ? email : 'demo@example.com',
      name: 'Demo User',
      createdAt: DateTime.now(),
    );
    
    DebugHelper.log('✅ 로그인 성공');
    DebugHelper.log('사용자 ID: ${_user?.id}');
    DebugHelper.log('사용자 이메일: ${_user?.email}');
    
    _setLoading(false);
    return true;

    // 실제 백엔드 연동 코드 (주석 처리됨)
    /*
    try {
      final authResponse = await _authService.login(email, password);
      _user = authResponse.user;
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
    */
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    _setLoading(true);
    _clearError();

    // TODO: 퍼블리싱용 임시 처리 - 아무 입력이나 회원가입 성공
    // 실제 백엔드 연동 시 아래 주석을 해제하고 더미 코드를 제거하세요
    await Future.delayed(const Duration(milliseconds: 500)); // 로딩 효과
    
    // 더미 사용자 생성
    _user = UserModel(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email.isNotEmpty ? email : 'demo@example.com',
      name: name ?? 'Demo User',
      createdAt: DateTime.now(),
    );
    
    _setLoading(false);
    return true;

    // 실제 백엔드 연동 코드 (주석 처리됨)
    /*
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
    */
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

