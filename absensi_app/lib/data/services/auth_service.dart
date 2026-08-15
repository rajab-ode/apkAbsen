import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<UserModel> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data);
      await _storage.write(key: AppConstants.tokenKey, value: user.token);
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(data));
      return user;
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Login gagal');
  }

  Future<UserModel?> getStoredUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
