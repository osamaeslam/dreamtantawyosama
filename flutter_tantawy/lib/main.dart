import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/adaptive_home_screen.dart';
import 'screens/login_screen.dart';
import 'services/cart_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://demo-tantawy.supabase.co'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'demo-anon-key'),
    );
  } catch (e) {
    debugPrint('Supabase offline or initialized in mock mode: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
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

    return MaterialApp(
      title: 'مجموعة الطنطاوي للتجارة والتوزيع',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,

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
  }
}
