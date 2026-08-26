class StravaConfig {
  const StravaConfig._();

  static const String authorizationUrl =
      'https://www.strava.com/oauth/mobile/authorize';

  static const String apiBaseUrl = 'https://www.strava.com/api/v3';

  static const String clientId = String.fromEnvironment('STRAVA_CLIENT_ID');

  static const String authBackendBaseUrl = String.fromEnvironment(
    'STRAVA_AUTH_BACKEND_URL',
  );

  static const String redirectUri = 'http://localhost:3000/api/v1/strava/callback';

  static const String appCallbackScheme = 'appkm';

static const String appCallbackHost = 'strava-callback';

  static const List<String> scopes = ['read', 'activity:read_all'];

  static String get scopeValue {
    return scopes.join(',');
  }

  static bool get hasClientId {
    return clientId.trim().isNotEmpty;
  }

  static bool get hasAuthBackend {
    return authBackendBaseUrl.trim().isNotEmpty;
  }

  static Uri buildAuthorizationUri({String? state}) {
    if (!hasClientId) {
      throw StateError('STRAVA_CLIENT_ID no está configurado.');
    }

    return Uri.parse(authorizationUrl).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'approval_prompt': 'auto',
        'scope': scopeValue,
        if (state != null && state.trim().isNotEmpty) 'state': state,
      },
    );
  }

  static Uri buildBackendUri(String path) {
    if (!hasAuthBackend) {
      throw StateError('STRAVA_AUTH_BACKEND_URL no está configurado.');
    }

    final normalizedBase = authBackendBaseUrl.endsWith('/')
        ? authBackendBaseUrl.substring(0, authBackendBaseUrl.length - 1)
        : authBackendBaseUrl;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
