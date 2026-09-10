import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/absensi_model.dart';
import '../../core/constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

class AbsensiService {
  final _api = ApiService();
  final _auth = AuthService();

  Future<AbsensiModel> recognize(List<double> embedding, {double? latitude, double? longitude}) async {
    final res = await _api.post('/absensi/recognize', {
      'embedding': embedding,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final data = _api.parseResponse(res);
    return AbsensiModel.fromJson(data['data']);
  }

  Future<Map<String, dynamic>> getAll({String? tanggal, String? search, int page = 1}) async {
    var query = '?page=$page&limit=20';
    if (tanggal != null) query += '&tanggal=$tanggal';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    final res = await _api.get('/absensi$query');
    final data = _api.parseResponse(res);
    return {
      'data': (data['data'] as List).map((e) => AbsensiModel.fromJson(e)).toList(),
      'total': data['total'] ?? 0,
      'hadir': data['hadir'] ?? 0,
      'izin': data['izin'] ?? 0,
      'tidakHadir': data['tidakHadir'] ?? 0,
    };
  }

  Future<List<AbsensiModel>> getMySiswa(int idSiswa) async {
    final res = await _api.get('/absensi/siswa/$idSiswa');
    final data = _api.parseResponse(res);
    return (data['data'] as List).map((e) => AbsensiModel.fromJson(e)).toList();
  }

  Future<String> downloadPdf({String? tanggal}) async {
    return _downloadFile(
      '/absensi/laporan/pdf${tanggal != null ? '?tanggal=$tanggal' : ''}',
      'laporan_absensi_${tanggal ?? 'semua'}.pdf',
    );
  }

  Future<String> downloadExcel({String? tanggal}) async {
    return _downloadFile(
      '/absensi/laporan/excel${tanggal != null ? '?tanggal=$tanggal' : ''}',
      'laporan_absensi_${tanggal ?? 'semua'}.xlsx',
    );
  }

  Future<String> _downloadFile(String path, String fileName) async {
    final token = await _auth.getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Gagal download file');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
