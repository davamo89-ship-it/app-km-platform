import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/app_dependencies.dart';

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

      initialRoute: AppRoutes.splash,

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
