import 'package:flutter_test/flutter_test.dart';
import 'package:absensi_app/data/models/absensi_model.dart';
import 'package:absensi_app/data/models/izin_model.dart';
import 'package:absensi_app/data/models/siswa_model.dart';
import 'package:absensi_app/data/models/user_model.dart';
import 'package:absensi_app/data/models/akun_model.dart';

void main() {
  // ── UserModel ──────────────────────────────────────────────────────────────
  group('UserModel', () {
    final json = {
      'id': 1,
      'username': 'admin',
      'role': 'admin',
      'nama': 'Administrator',
      'token': 'jwt_token',
    };

    test('fromJson parses all fields', () {
      final m = UserModel.fromJson(json);
      expect(m.id, 1);
      expect(m.username, 'admin');
      expect(m.role, 'admin');
      expect(m.nama, 'Administrator');
      expect(m.token, 'jwt_token');
    });

    test('isAdmin returns true only for admin role', () {
      expect(UserModel.fromJson(json).isAdmin, isTrue);
      expect(UserModel.fromJson({...json, 'role': 'guru'}).isAdmin, isFalse);
    });

    test('isGuru returns true only for guru role', () {
      final guru = UserModel.fromJson({...json, 'role': 'guru'});
      expect(guru.isGuru, isTrue);
      expect(guru.isSiswa, isFalse);
    });

    test('isSiswa returns true only for siswa role', () {
      final siswa = UserModel.fromJson({...json, 'role': 'siswa'});
      expect(siswa.isSiswa, isTrue);
      expect(siswa.isAdmin, isFalse);
    });
  });

  // ── IzinModel ─────────────────────────────────────────────────────────────
  group('IzinModel', () {
    final fullJson = {
      'id_izin': 10,
      'nama_siswa': 'Budi Santoso',
      'NIS': '2021001',
      'tanggal': '2026-07-09',
      'jenis': 'sakit',
      'file_surat': 'surat/budi.pdf',
      'status': 'pending',
    };

    test('fromJson parses all fields', () {
      final m = IzinModel.fromJson(fullJson);
      expect(m.idIzin, 10);
      expect(m.namaSiswa, 'Budi Santoso');
      expect(m.nis, '2021001');
      expect(m.tanggal, '2026-07-09');
      expect(m.jenis, 'sakit');
      expect(m.fileSurat, 'surat/budi.pdf');
      expect(m.status, 'pending');
    });

    test('fromJson handles null file_surat', () {
      final m = IzinModel.fromJson({...fullJson, 'file_surat': null});
      expect(m.fileSurat, isNull);
    });

    test('fromJson uses default status "pending" when missing', () {
      final json = Map<String, dynamic>.from(fullJson)..remove('status');
      final m = IzinModel.fromJson(json);
      expect(m.status, 'pending');
    });

    test('fromJson handles missing optional string fields', () {
      final m = IzinModel.fromJson({
        'id_izin': 1,
        'tanggal': '2026-07-09',
        'jenis': 'izin',
        'status': 'approved',
      });
      expect(m.namaSiswa, '');
      expect(m.nis, '');
    });
  });

  // ── AbsensiModel ──────────────────────────────────────────────────────────
  group('AbsensiModel', () {
    final json = {
      'id_absensi': 5,
      'nama_siswa': 'Andi',
      'NIS': '2021002',
      'foto_path': 'foto/andi.jpg',
      'tanggal': '2026-07-09',
      'waktu': '07:30:00',
      'status': 'hadir',
    };

    test('fromJson parses all fields', () {
      final m = AbsensiModel.fromJson(json);
      expect(m.idAbsensi, 5);
      expect(m.namaSiswa, 'Andi');
      expect(m.nis, '2021002');
      expect(m.fotoPath, 'foto/andi.jpg');
      expect(m.tanggal, '2026-07-09');
      expect(m.waktu, '07:30:00');
      expect(m.status, 'hadir');
    });

    test('fromJson handles null foto_path', () {
      final m = AbsensiModel.fromJson({...json, 'foto_path': null});
      expect(m.fotoPath, isNull);
    });

    test('fromJson defaults waktu to empty string when missing', () {
      final m = AbsensiModel.fromJson({...json}..remove('waktu'));
      expect(m.waktu, '');
    });
  });

  // ── SiswaModel ────────────────────────────────────────────────────────────
  group('SiswaModel', () {
    final json = {
      'id_siswa': 1,
      'nama_siswa': 'Cici',
      'NIS': '2021003',
      'kelas': 'XI TJKT',
      'jurusan': 'Teknik Jaringan',
      'jenis_kelamin': 'P',
      'alamat': 'Jl. Bunga No. 1',
      'no_telepon': '08123456789',
      'foto': 'foto/cici.jpg',
      'data_wajah': '[0.1, 0.2]',
    };

    test('fromJson parses all fields', () {
      final m = SiswaModel.fromJson(json);
      expect(m.idSiswa, 1);
      expect(m.namaSiswa, 'Cici');
      expect(m.nis, '2021003');
      expect(m.kelas, 'XI TJKT');
    });

    test('wajahTerdaftar is true when data_wajah is not null', () {
      final m = SiswaModel.fromJson(json);
      expect(m.wajahTerdaftar, isTrue);
    });

    test('wajahTerdaftar is false when data_wajah is null', () {
      final m = SiswaModel.fromJson({...json, 'data_wajah': null});
      expect(m.wajahTerdaftar, isFalse);
    });
  });

  // ── AkunModel ─────────────────────────────────────────────────────────────
  group('AkunModel', () {
    final json = {
      'id': 2,
      'nama': 'Pak Guru',
      'peran': 'guru',
      'nis_nip': 'NIP12345',
      'username': 'guru01',
      'status': 'aktif',
      'email': 'guru@smkn5.sch.id',
      'no_telepon': '0812',
      'kelas': '',
      'mata_pelajaran': 'Matematika',
    };

    test('fromJson parses all fields', () {
      final m = AkunModel.fromJson(json);
      expect(m.id, 2);
      expect(m.nama, 'Pak Guru');
      expect(m.peran, 'guru');
      expect(m.mataPelajaran, 'Matematika');
    });
  });
}
