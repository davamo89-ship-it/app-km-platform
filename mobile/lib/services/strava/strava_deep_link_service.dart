import 'dart:async';

import 'package:app_links/app_links.dart';

import 'strava_connection_controller.dart';

class StravaDeepLinkService {
  StravaDeepLinkService({
    required StravaConnectionController connectionController,
    AppLinks? appLinks,
  }) : _connectionController = connectionController,
       _appLinks = appLinks ?? AppLinks();

  final StravaConnectionController _connectionController;

  final AppLinks _appLinks;

  StreamSubscription<Uri>? _subscription;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    final initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      await _processUri(initialUri);
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _processUri(uri);
      },
      onError: (_) {
        // El controlador conserva el estado actual.
        // Más adelante agregaremos registro de errores.
      },
    );
  }

  Future<bool> processCallbackForTesting(Uri uri) {
    return _processUri(uri);
  }

  Future<bool> _processUri(Uri uri) async {
    if (!_isStravaCallback(uri)) {
      return false;
    }

    return _connectionController.handleCallback(uri);
  }

  bool _isStravaCallback(Uri uri) {
    return uri.scheme == 'appkm' && uri.host == 'strava-callback';
  }

  Future<void> dispose() async {
    await _subscription?.cancel();

    _subscription = null;
    _initialized = false;
  }
}
