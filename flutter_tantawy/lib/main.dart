import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/adaptive_home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
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
     connectivity.startWatching(interval: const Duration(seconds: 30));
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
          home: const SessionGate(),
        );
      },
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService.instance.refreshOrReauth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return AdaptiveHomeScreen(currentUser: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}
