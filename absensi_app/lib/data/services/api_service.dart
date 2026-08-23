import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import 'auth_service.dart';

// Dilempar saat JWT expired/invalid — ditangkap di AuthProvider untuk auto-logout
class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ApiService {
  final _auth = AuthService();

  static const _timeout = Duration(seconds: 20);

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    return http
        .get(Uri.parse('${AppConstants.baseUrl}$path'), headers: await _headers())
        .timeout(_timeout, onTimeout: () => throw Exception('Koneksi timeout. Periksa jaringan Anda.'));
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return http
        .post(
          Uri.parse('${AppConstants.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Koneksi timeout. Periksa jaringan Anda.'));
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    return http
        .put(
          Uri.parse('${AppConstants.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Koneksi timeout. Periksa jaringan Anda.'));
  }

  Future<http.Response> delete(String path) async {
    return http
        .delete(Uri.parse('${AppConstants.baseUrl}$path'), headers: await _headers())
        .timeout(_timeout, onTimeout: () => throw Exception('Koneksi timeout. Periksa jaringan Anda.'));
  }

  Future<http.Response> postMultipart(
    String path,
    Map<String, String> fields, {
    String? fileField,
    String? filePath,
    String? fileName,
  }) {
    return _sendMultipart('POST', path, fields, fileField: fileField, filePath: filePath, fileName: fileName);
  }

  Future<http.Response> putMultipart(
    String path,
    Map<String, String> fields, {
    String? fileField,
    String? filePath,
    String? fileName,
  }) {
    return _sendMultipart('PUT', path, fields, fileField: fileField, filePath: filePath, fileName: fileName);
  }

  Future<http.Response> _sendMultipart(
    String method,
    String path,
    Map<String, String> fields, {
    String? fileField,
    String? filePath,
    String? fileName,
  }) async {
    final token = await _auth.getToken();
    final request = http.MultipartRequest(method, Uri.parse('${AppConstants.baseUrl}$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    if (fileField != null && filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath, filename: fileName));
    }
    final streamed = await request.send()
        .timeout(_timeout, onTimeout: () => throw Exception('Koneksi timeout. Periksa jaringan Anda.'));
    return http.Response.fromStream(streamed);
  }

  dynamic parseResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode == 401) throw const UnauthorizedException();
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Terjadi kesalahan');
  }
}
