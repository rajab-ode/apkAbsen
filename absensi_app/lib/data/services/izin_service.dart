import '../models/izin_model.dart';
import 'api_service.dart';

class IzinService {
  final _api = ApiService();

  Future<void> ajukan({
    required String tanggal,
    required String jenis,
    required String filePath,
    required String fileName,
  }) async {
    final res = await _api.postMultipart(
      '/izin',
      {'tanggal': tanggal, 'jenis': jenis},
      fileField: 'file_surat',
      filePath: filePath,
      fileName: fileName,
    );
    _api.parseResponse(res);
  }

  Future<List<IzinModel>> getAll() async {
    final res = await _api.get('/izin');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => IzinModel.fromJson(e)).toList();
  }

  Future<List<IzinModel>> getMySiswa(int idSiswa) async {
    final res = await _api.get('/izin/siswa/$idSiswa');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => IzinModel.fromJson(e)).toList();
  }

  Future<void> updateStatus(int idIzin, String status) async {
    final res = await _api.put('/izin/$idIzin/status', {'status': status});
    _api.parseResponse(res);
  }
}
