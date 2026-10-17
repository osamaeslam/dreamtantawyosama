import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/adaptive_home_screen.dart';
import 'screens/login_screen.dart';
import 'services/cart_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_provider.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL',
          defaultValue: 'https://rxthpgmlcsfckstpqhqf.supabase.co'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4dGhQZ21sY3NmY2tzdHBxaHFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NDIwMzgsImV4cCI6MjEwMzIxODAzOH0.2v4eRUKQjLM0xDomaE9HAiy_qTJ6NoijNuwC3JV1ZUA'),
    );
  } catch (e) {
    debugPrint('Supabase offline or initialized in mock mode: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
      ],
      child: const TantawyGroupApp(),
    ),
  );
}

class TantawyGroupApp extends StatelessWidget {
  const TantawyGroupApp({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultUser = AppUser(
      id: 'usr_001',
      name: 'مندوب الطنطاوي',
      username: 'rep_tantawy',
      role: 'sales_rep',
      branchName: 'فرع القاهرة الكبرى',
      phone: '01012345678',
    );

    return Consumer<ThemeModeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'مجموعة الطنطاوي للتجارة والتوزيع',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          locale: const Locale('ar', 'EG'),
          supportedLocales: const [
            Locale('ar', 'EG'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AdaptiveHomeScreen(currentUser: defaultUser),
          ),
        );
      },
    );
  }
}
