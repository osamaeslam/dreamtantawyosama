import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/adaptive_home_screen.dart';
import 'screens/login_screen.dart';
import 'services/cart_service.dart';
import 'services/config.dart';
import 'services/connectivity_service.dart';
import 'services/offline_cache_service.dart';
import 'services/offline_queue_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_provider.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.logConfig();

  try {
    await SupabaseService.initialize(
      supabaseUrl: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase offline or initialized in mock mode: $e');
  }

  final connectivity = ConnectivityService.instance;
  final queueService = OfflineQueueService(connectivity);

  // Eagerly check connectivity + load queued actions before first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await queueService.init();
    await connectivity.startWatching(interval: const Duration(seconds: 30));
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
        ChangeNotifierProvider.value(value: queueService),
        Provider(create: (_) => connectivity),
        Provider(create: (_) => OfflineCacheService()),
      ],
      child: const TantawyGroupApp(),
    ),
  );
}

class TantawyGroupApp extends StatelessWidget {
  const TantawyGroupApp({super.key});

  // Trigger an immediate connectivity check on resume so the queue drains
  // as soon as the app returns to the foreground.
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
          home: const LoginScreen(),
        );
      },
    );
  }
}
