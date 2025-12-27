import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/main_screen.dart';

/// Point d'entrée pour le mode DÉVELOPPEMENT (localhost)
void main() => _runApp(Environment.production);

/// Point d'entrée pour le mode STAGING (staging.toto.tangagroup.com)
void mainStaging() => _runApp(Environment.staging);

/// Point d'entrée pour le mode PRODUCTION (toto.tangagroup.com)
void mainProduction() => _runApp(Environment.production);

void _runApp(Environment env) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'environnement
  EnvConfig.setEnvironment(env);

  // Configuration de l'orientation (portrait uniquement)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: TotoDelivererApp(),
    ),
  );
}

class TotoDelivererApp extends ConsumerStatefulWidget {
  const TotoDelivererApp({super.key});

  @override
  ConsumerState<TotoDelivererApp> createState() => _TotoDelivererAppState();
}

class _TotoDelivererAppState extends ConsumerState<TotoDelivererApp> {
  @override
  void initState() {
    super.initState();
    // Initialiser l'authentification au démarrage
    Future.microtask(() {
      ref.read(authProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Navigation conditionnelle basée sur l'état d'authentification
      home: authState.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : authState.isAuthenticated
              ? const MainScreen()
              : const LoginScreen(),

      // Configuration de la localisation
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
