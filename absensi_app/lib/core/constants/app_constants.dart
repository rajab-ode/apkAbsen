class AppConstants {
  static const String serverUrl = 'http://192.168.1.27:3001';
  static const String baseUrl = '$serverUrl/api';
  static const String apkDownloadUrl = '$serverUrl/download/app-release.apk';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const double faceMatchThreshold = 0.80;
  static const int maxIzinFileSizeMB = 10;
}
