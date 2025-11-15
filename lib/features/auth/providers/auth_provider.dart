import 'package:flutter/foundation.dart';
import 'package:partition_app/features/auth/models/user_model.dart';
import 'package:partition_app/features/auth/services/auth_service.dart';
import 'package:partition_app/core/network/api_exception.dart';

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
    _setLoading(true);
    _clearError();

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

