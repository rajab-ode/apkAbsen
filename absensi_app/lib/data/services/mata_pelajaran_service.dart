import '../models/mata_pelajaran_model.dart';
import 'api_service.dart';

class MataPelajaranService {
  final _api = ApiService();

  Future<List<MataPelajaranModel>> getAll() async {
    final res = await _api.get('/mata-pelajaran');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => MataPelajaranModel.fromJson(e)).toList();
  }

  Future<void> create(String namaMapel) async {
    final res = await _api.post('/mata-pelajaran', {'nama_mapel': namaMapel});
    _api.parseResponse(res);
  }

  Future<void> delete(int idMapel) async {
    final res = await _api.delete('/mata-pelajaran/$idMapel');
    _api.parseResponse(res);
  }
}
