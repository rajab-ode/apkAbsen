import '../models/siswa_model.dart';
import 'api_service.dart';

class SiswaService {
  final _api = ApiService();

  Future<List<SiswaModel>> getAll({String? search, int page = 1}) async {
    final query = '?page=$page${search != null ? '&search=$search' : ''}';
    final res = await _api.get('/siswa$query');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => SiswaModel.fromJson(e)).toList();
  }

  Future<SiswaModel> getById(int id) async {
    final res = await _api.get('/siswa/$id');
    return SiswaModel.fromJson(_api.parseResponse(res)['data']);
  }

  Future<void> create(Map<String, dynamic> body, {String? fotoPath}) async {
    if (fotoPath != null) {
      final fields = body.map((k, v) => MapEntry(k, v.toString()));
      await _api.postMultipart('/siswa', fields,
          fileField: 'foto', filePath: fotoPath, fileName: 'foto.jpg');
    } else {
      final res = await _api.post('/siswa', body);
      _api.parseResponse(res);
    }
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    final res = await _api.put('/siswa/$id', body);
    _api.parseResponse(res);
  }

  Future<void> delete(int id) async {
    final res = await _api.delete('/siswa/$id');
    _api.parseResponse(res);
  }

  Future<List<SiswaModel>> getTanpaAkun() async {
    final res = await _api.get('/siswa?no_account=true&limit=200');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => SiswaModel.fromJson(e)).toList();
  }

  Future<void> registerFace(int id, List<double> embedding) async {
    final res = await _api.post('/siswa/$id/wajah', {
      'embedding': embedding,
    });
    _api.parseResponse(res);
  }

  Future<Map<String, dynamic>> getPaginated({
    String? search,
    int page = 1,
  }) async {
    final query = '?page=$page&limit=9${search != null ? '&search=$search' : ''}';
    final res = await _api.get('/siswa$query');
    final data = _api.parseResponse(res);
    return {
      'data': (data['data'] as List).map((e) => SiswaModel.fromJson(e)).toList(),
      'total': data['total'] ?? 0,
      'totalPages': data['totalPages'] ?? 1,
    };
  }
}
