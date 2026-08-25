import '../models/kelas_model.dart';
import 'api_service.dart';

class KelasService {
  final _api = ApiService();

  Future<List<KelasModel>> getAll() async {
    final res = await _api.get('/kelas');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => KelasModel.fromJson(e)).toList();
  }

  Future<void> create(String namaKelas) async {
    final res = await _api.post('/kelas', {'nama_kelas': namaKelas});
    _api.parseResponse(res);
  }

  Future<void> delete(int idKelas) async {
    final res = await _api.delete('/kelas/$idKelas');
    _api.parseResponse(res);
  }
}
