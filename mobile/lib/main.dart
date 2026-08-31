import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_dependencies.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppDependencies.instance.initialize();

  runApp(const AppKM());
}

class AppKM extends StatelessWidget {
  const AppKM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'App KM',

      theme: AppTheme.lightTheme,

      // Idioma principal de App KM
      locale: const Locale('es'),

      // Idiomas soportados
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],

      // Traducciones de los componentes nativos de Flutter.
      // Esto hace que calendarios, botones y otros controles
      // aparezcan en español.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      initialRoute: AppRoutes.splash,

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}