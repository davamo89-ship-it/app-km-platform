import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_dependencies.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/notifications/push_device_registration_service.dart';
import 'services/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  AppDependencies.instance.initialize();

  await PushNotificationService.instance.initialize();

  PushDeviceRegistrationService.instance.initialize();

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
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
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
