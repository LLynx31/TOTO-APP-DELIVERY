import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/env_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';

/// Point d'entrée pour le mode DÉVELOPPEMENT (localhost)
void main() => _runApp(Environment.development);

/// Point d'entrée pour le mode STAGING (staging.toto.tangagroup.com)
void mainStaging() => _runApp(Environment.staging);

/// Point d'entrée pour le mode PRODUCTION (toto.tangagroup.com)
void mainProduction() => _runApp(Environment.production);

void _runApp(Environment env) {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'environnement
  EnvConfig.setEnvironment(env);

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: TotoApp(),
    ),
  );
}

class TotoApp extends ConsumerWidget {
  const TotoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,

      // Locale
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
