import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_provider.dart';
import 'data/services/siswa_service.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';
import 'presentation/screens/admin/tambah_siswa_screen.dart';
import 'presentation/screens/admin/registrasi_wajah_screen.dart';
import 'presentation/screens/admin/kelola_database_screen.dart';
import 'presentation/screens/admin/kelola_akun_screen.dart';
import 'presentation/screens/admin/kelola_data_master_screen.dart';
import 'presentation/screens/siswa/absensi_screen.dart';
import 'presentation/screens/siswa/riwayat_absensi_screen.dart';
import 'presentation/screens/siswa/riwayat_izin_screen.dart';
import 'presentation/screens/siswa/ajukan_izin_screen.dart';
import 'presentation/screens/siswa/daftar_wajah_screen.dart';
import 'presentation/screens/guru/guru_dashboard_screen.dart';
import 'presentation/screens/guru/kelola_jadwal_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Absensi SMKN 5 Kendari',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('id', 'ID'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', 'ID'), Locale('en')],
        home: const _AppEntry(),
        routes: {
          '/login': (_) => const LoginScreen(),
          // Admin
          '/admin/dashboard': (_) => const AdminDashboardScreen(),
          '/admin/siswa/tambah': (_) => const TambahSiswaScreen(),
          '/admin/registrasi-wajah': (_) => const RegistrasiWajahScreen(),
          '/admin/database': (_) => const KelolaDatabaseScreen(),
          '/admin/akun': (_) => const KelolaAkunScreen(),
          '/admin/data-master': (_) => const KelolaDataMasterScreen(),
          // Siswa
          '/siswa/absensi': (_) => const AbsensiScreen(),
          '/siswa/riwayat': (_) => const RiwayatAbsensiScreen(),
          '/siswa/riwayat-izin': (_) => const RiwayatIzinScreen(),
          '/siswa/izin': (_) => const AjukanIzinScreen(),
          // Guru
          '/guru/dashboard': (_) => const GuruDashboardScreen(),
          '/guru/jadwal': (_) => const KelolaJadwalScreen(),
        },
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.tryAutoLogin();

      if (!mounted) return;

      if (!auth.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final role = auth.user!.role;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else if (role == 'guru') {
        Navigator.pushReplacementNamed(context, '/guru/dashboard');
      } else {
        // Siswa: cek apakah wajah sudah terdaftar
        final idSiswa = auth.user!.extraId ?? auth.user!.id;
        try {
          final siswa = await SiswaService().getById(idSiswa);
          if (!mounted) return;
          if (siswa.wajahTerdaftar) {
            Navigator.pushReplacementNamed(context, '/siswa/absensi');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DaftarWajahScreen()),
            );
          }
        } catch (_) {
          if (mounted) Navigator.pushReplacementNamed(context, '/siswa/absensi');
        }
      }
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
