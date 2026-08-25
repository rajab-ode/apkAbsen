import '../models/jadwal_model.dart';
import 'api_service.dart';

class JadwalService {
  final _api = ApiService();

  Future<List<JadwalModel>> getMine() async {
    final res = await _api.get('/jadwal');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => JadwalModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final res = await _api.post('/jadwal', body);
    return _api.parseResponse(res);
  }

  Future<void> delete(int idJadwal) async {
    final res = await _api.delete('/jadwal/$idJadwal');
    _api.parseResponse(res);
  }

  Future<List<JadwalModel>> getForSiswa() async {
    final res = await _api.get('/jadwal/saya');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => JadwalModel.fromJson(e)).toList();
  }
}
