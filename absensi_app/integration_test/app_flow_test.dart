// Integration / E2E tests — require a running backend and a real device/emulator.
//
// Run with:
//   flutter test integration_test/app_flow_test.dart
//
// Set the backend URL in AppConstants.baseUrl before running.
// Seed the DB with the default admin account (admin / admin123)
// and at least one siswa with a registered face.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:absensi_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Scenario 1: App launch shows loading then redirects ──────────────────
  group('App launch', () {
    testWidgets('shows loading indicator on startup', (tester) async {
      app.main();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Scenario 2: Login as admin ───────────────────────────────────────────
  group('Admin login flow', () {
    testWidgets('navigates to admin dashboard on valid login', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should land on login screen
      expect(find.byType(TextField), findsAtLeastNWidgets(2));

      // Enter credentials
      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'admin');
      await tester.enterText(fields.at(1), 'admin123');
      await tester.pump();

      // Tap login button
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Admin dashboard should be visible
      expect(find.text('Masukkan Data Siswa'), findsOneWidget);
    });

    testWidgets('shows error on invalid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'wronguser');
      await tester.enterText(fields.at(1), 'wrongpass');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Error message should be shown
      expect(find.textContaining('salah'), findsOneWidget);
    });
  });

  // ── Scenario 3: Siswa absensi screen ─────────────────────────────────────
  group('Siswa absensi screen', () {
    testWidgets('camera preview and absen button visible after login', (tester) async {
      // Login as siswa (requires siswa account in DB)
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'siswa01');    // adjust to seeded account
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Absen button should be visible
      expect(find.textContaining('Absen'), findsOneWidget);
    });
  });

  // ── Scenario 4: Guru dashboard ────────────────────────────────────────────
  group('Guru dashboard', () {
    testWidgets('shows kehadiran stats and izin card after login', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'guru01');    // adjust to seeded account
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Hadir'), findsOneWidget);
      expect(find.text('Izin'), findsOneWidget);
      expect(find.text('Tidak Hadir'), findsOneWidget);
      expect(find.textContaining('Pengajuan Izin'), findsOneWidget);
    });
  });
}
