import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_provider.dart';

// Gunakan ini di catch block semua screen yang memanggil API
// Contoh:
//   } catch (e) {
//     if (!handleApiError(context, e)) {
//       // handle error lain
//     }
//   }
//
// Returns true jika error ditangani (unauthorized → redirect login)
bool handleApiError(BuildContext context, Object error) {
  if (error is UnauthorizedException) {
    _doLogout(context);
    return true;
  }
  return false;
}

Future<void> _doLogout(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  await auth.handleUnauthorized();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
