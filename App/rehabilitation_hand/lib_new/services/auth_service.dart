import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rehabilitation_hand/models/user_model.dart';
import 'package:rehabilitation_hand/core/utils/api_client.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _jwtToken;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  String? get jwtToken => _jwtToken;
  bool get isAuthenticated => _isAuthenticated;

  AuthService() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userJson = prefs.getString('user_data');

    if (token != null && userJson != null) {
      _jwtToken = token;
      _currentUser = User.fromJson(json.decode(userJson));
      _isAuthenticated = true;
      ApiClient.setAuthToken(token);
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      // TODO: 實際API呼叫
      // final response = await ApiClient.post('/auth/login', {
      //   'username': username,
      //   'password': password,
      // });

      // 模擬登入成功
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: '1',
        username: username,
        email: '$username@example.com',
        token: 'fake_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      _jwtToken = _currentUser!.token;
      _isAuthenticated = true;

      // 儲存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _jwtToken!);
      await prefs.setString('user_data', json.encode(_currentUser!.toJson()));

      ApiClient.setAuthToken(_jwtToken!);
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _jwtToken = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');

    ApiClient.clearAuthToken();
    notifyListeners();
  }
}
