// Widget tests for the Tantawy Group multiplatform app.
//
// The app root (`TantawyGroupApp`) expects its providers to be installed by
// `main()`, so every test that boots the root widget has to supply the same
// `MultiProvider` tree. `SessionGate` resolves asynchronously (it probes the
// backend), so the login assertions are covered by rendering `LoginScreen`
// directly instead of racing the auth future.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tantawy_group/main.dart';
import 'package:tantawy_group/screens/login_screen.dart';
import 'package:tantawy_group/services/cart_service.dart';
import 'package:tantawy_group/services/theme_provider.dart';

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CartService()),
      ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
    ],
    child: child,
  );
}

Widget _buildApp() {
  return _wrapWithProviders(
    const MaterialApp(
      locale: Locale('ar', 'EG'),
      supportedLocales: [Locale('ar', 'EG')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    // Never hit the network for fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App root boots with the required providers', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithProviders(const TantawyGroupApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login screen renders the sign-in form', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('مجموعة الطنطاوي للتجارة'), findsOneWidget);
    expect(find.text('تسجيل الدخول إلى النظام'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
