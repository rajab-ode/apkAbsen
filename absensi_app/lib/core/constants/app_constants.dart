class AppConstants {
  // Default produksi. Untuk backend lokal (MySQL XAMPP + node app.js), override
  // saat menjalankan app -- tidak perlu mengubah file ini:
  //   emulator Android : flutter run --dart-define=SERVER_URL=http://10.0.2.2:3000
  //   HP fisik via LAN : flutter run --dart-define=SERVER_URL=http://<IP-PC>:3000
  // Build rilis tanpa flag tetap menunjuk ke produksi.
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://apismk.codingrame.com',
  );
  static const String baseUrl = '$serverUrl/api';
  static const String apkDownloadUrl = '$serverUrl/download/app-release.apk';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const double faceMatchThreshold = 0.80;
  static const int maxIzinFileSizeMB = 10;
}
