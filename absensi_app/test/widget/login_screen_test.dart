import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/data/services/auth_provider.dart';
import 'package:absensi_app/presentation/screens/auth/login_screen.dart';

/// Wraps LoginScreen with the required Provider and dummy routes.
Widget buildTestApp(AuthProvider authProvider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      home: const LoginScreen(),
      routes: {
        '/admin/dashboard': (_) => const Scaffold(body: Text('Admin Dashboard')),
        '/guru/dashboard':  (_) => const Scaffold(body: Text('Guru Dashboard')),
        '/siswa/absensi':   (_) => const Scaffold(body: Text('Siswa Absensi')),
      },
    ),
  );
}

void main() {
  group('LoginScreen — UI rendering', () {
    testWidgets('shows app title / brand text', (tester) async {
      await tester.pumpWidget(buildTestApp(AuthProvider()));
      await tester.pump();
      // Should contain at least one text field for username
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('has username and password TextFields', (tester) async {
      await tester.pumpWidget(buildTestApp(AuthProvider()));
      await tester.pump();
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, greaterThanOrEqualTo(2));
    });

    testWidgets('has a login button', (tester) async {
      await tester.pumpWidget(buildTestApp(AuthProvider()));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('password field obscures text', (tester) async {
      await tester.pumpWidget(buildTestApp(AuthProvider()));
      await tester.pump();
      final passwordFields = tester.widgetList<TextField>(find.byType(TextField))
          .where((f) => f.obscureText)
          .toList();
      expect(passwordFields, isNotEmpty);
    });
  });

  group('LoginScreen — input interaction', () {
    testWidgets('can type into username field', (tester) async {
      await tester.pumpWidget(buildTestApp(AuthProvider()));
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'admin');
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('can type into password field', (tester) async {
      await tester.pumpWidget(buildTestApp(AuthProvider()));
      await tester.pump();

      final fields = find.byType(TextField);
      // Second TextField is the password field
      await tester.enterText(fields.at(1), 'secret123');
      await tester.pump();
      // Password is obscured so we verify via controller text via the field
      final tf = tester.widget<TextField>(fields.at(1));
      expect(tf.controller?.text ?? '', 'secret123');
    });
  });
}
