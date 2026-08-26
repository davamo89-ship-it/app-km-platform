import 'package:url_launcher/url_launcher.dart';

class StravaOAuthLauncher {
  const StravaOAuthLauncher();

  Future<void> openAuthorizationUri(Uri authorizationUri) async {
    final opened = await launchUrl(
      authorizationUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw const StravaOAuthLauncherException(
        'No fue posible abrir la autorización de Strava.',
      );
    }
  }
}

class StravaOAuthLauncherException implements Exception {
  const StravaOAuthLauncherException(this.message);

  final String message;

  @override
  String toString() {
    return 'StravaOAuthLauncherException: $message';
  }
}
