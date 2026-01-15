import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_service.dart';
import '../models/user.dart';

class AuthState extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  final ApiService api;

  String? _token;
  User? _user;
  bool _loading = false;

  AuthState({required this.api});

  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _token != null && _user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    // For the demo we only restore token; user will be fetched on login.
    notifyListeners();
  }

  Future<String?> login({required String username, required String password}) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await api.login(username: username, password: password);
      _token = res.token;
      _user = res.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);

      return null;
    } catch (e) {
      return _friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Invalid username or password.';
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'Cannot reach the server. Check API URL and that backend is running.';
    }
    return 'Something went wrong. Please try again.';
  }
}
