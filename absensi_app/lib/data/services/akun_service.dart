import '../models/akun_model.dart';
import 'api_service.dart';

class AkunService {
  final _api = ApiService();

  Future<Map<String, dynamic>> getPaginated({
    String? search,
    String? role,
    int page = 1,
  }) async {
    var query = '?page=$page&limit=9';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (role != null && role != 'semua') query += '&role=$role';
    final res = await _api.get('/akun$query');
    final data = _api.parseResponse(res);
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final total = data['total'] ?? 0;
    final limit = 9;
    return {
      'data': (data['data'] as List).map((e) => AkunModel.fromJson(e)).toList(),
      'total': total,
      'totalPages': ((total as int) / limit).ceil().clamp(1, 9999),
      'totalGuru': stats['guru'] ?? 0,
      'totalSiswa': stats['siswa'] ?? 0,
    };
  }

  Future<void> create(Map<String, dynamic> body) async {
    final res = await _api.post('/akun', body);
    _api.parseResponse(res);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/akun/$id', body);
    _api.parseResponse(res);
  }

  Future<void> delete(int id) async {
    final res = await _api.delete('/akun/$id');
    _api.parseResponse(res);
  }
}
