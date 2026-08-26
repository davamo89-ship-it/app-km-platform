import 'dart:math';

import '../../core/config/strava_config.dart';
import '../../models/strava_auth_result.dart';
import '../../models/strava_token.dart';
import 'strava_auth_exception.dart';
import 'strava_repository.dart';
import 'strava_token_store.dart';

typedef AuthorizationUriBuilder = Uri Function({String? state});

typedef OAuthStateGenerator = String Function();

class StravaAuthService {
  StravaAuthService({
    required StravaRepository repository,
    required StravaTokenStore tokenStore,
    AuthorizationUriBuilder? authorizationUriBuilder,
    OAuthStateGenerator? stateGenerator,
    Random? random,
  }) : _repository = repository,
       _tokenStore = tokenStore,
       _authorizationUriBuilder =
           authorizationUriBuilder ?? StravaConfig.buildAuthorizationUri,
       _stateGenerator = stateGenerator,
       _random = random ?? Random.secure();

  final StravaRepository _repository;
  final StravaTokenStore _tokenStore;
  final AuthorizationUriBuilder _authorizationUriBuilder;
  final OAuthStateGenerator? _stateGenerator;
  final Random _random;

  String? _pendingState;

  Uri createAuthorizationUri() {
    final state = _stateGenerator?.call() ?? _generateState();

    if (state.trim().isEmpty) {
      throw const StravaAuthException(
        code: 'invalid_state_generator',
        message: 'No fue posible generar el estado de seguridad de OAuth.',
      );
    }

    _pendingState = state;

    return _authorizationUriBuilder(state: state);
  }

  Future<StravaAuthResult> handleCallback(Uri callbackUri) async {
    _validateCallback(callbackUri);

    final error = callbackUri.queryParameters['error'];

    if (error != null && error.isNotEmpty) {
      _pendingState = null;

      throw StravaAuthException(
        code: error,
        message: 'La autorización de Strava fue cancelada o rechazada.',
      );
    }

    final receivedState = callbackUri.queryParameters['state'];

    if (_pendingState == null ||
        receivedState == null ||
        receivedState != _pendingState) {
      _pendingState = null;

      throw const StravaAuthException(
        code: 'invalid_state',
        message: 'La respuesta de autorización no pudo verificarse.',
      );
    }

    final authorizationCode = callbackUri.queryParameters['code'];

    if (authorizationCode == null || authorizationCode.trim().isEmpty) {
      _pendingState = null;

      throw const StravaAuthException(
        code: 'missing_code',
        message: 'Strava no devolvió un código de autorización.',
      );
    }

    _pendingState = null;

    final grantedScopes = _parseCallbackScopes(
  callbackUri.queryParameters['scope'],
);

final exchangeResult = await _repository.exchangeCode(
  authorizationCode: authorizationCode,
);

final result = StravaAuthResult(
  token: exchangeResult.token,
  athlete: exchangeResult.athlete,
  grantedScopes: grantedScopes,
);

if (!result.canReadActivities) {
  throw const StravaAuthException(
    code: 'missing_activity_scope',
    message: 'No se autorizó el permiso para leer actividades.',
  );
}

await _tokenStore.saveSession(
  token: result.token,
  athlete: result.athlete,
  grantedScopes: result.grantedScopes,
);

return result;
  }

  Future<StravaToken?> getValidToken() async {
    final storedToken = await _tokenStore.readToken();

    if (storedToken == null) {
      return null;
    }

    if (!storedToken.isExpired) {
      return storedToken;
    }

    return _refreshStoredToken(storedToken);
  }

  Future<String?> getValidAccessToken() async {
    final token = await getValidToken();

    return token?.accessToken;
  }

  Future<bool> isConnected() async {
    final token = await getValidToken();

    return token != null;
  }

  Future<StravaAthlete?> getStoredAthlete() {
    return _tokenStore.readAthlete();
  }

  Future<Set<String>> getGrantedScopes() {
    return _tokenStore.readGrantedScopes();
  }

  Future<void> disconnect() {
    _pendingState = null;

    return _tokenStore.clear();
  }

  Future<StravaToken> _refreshStoredToken(StravaToken currentToken) async {
    try {
      final refreshedToken = await _repository.refreshToken(
        refreshToken: currentToken.refreshToken,
      );

      final athlete = await _tokenStore.readAthlete();
      final scopes = await _tokenStore.readGrantedScopes();

      if (athlete == null) {
        await _tokenStore.clear();

        throw const StravaAuthException(
          code: 'missing_athlete',
          message: 'La sesión guardada no contiene información del atleta.',
        );
      }

      await _tokenStore.saveSession(
        token: refreshedToken,
        athlete: athlete,
        grantedScopes: scopes,
      );

      return refreshedToken;
    } catch (_) {
      await _tokenStore.clear();
      rethrow;
    }
  }

Set<String> _parseCallbackScopes(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return <String>{};
  }

  return text
      .split(RegExp(r'[\s,]+'))
      .map((scope) => scope.trim())
      .where((scope) => scope.isNotEmpty)
      .toSet();
}

 void _validateCallback(Uri callbackUri) {
  final hasExpectedScheme =
      callbackUri.scheme == StravaConfig.appCallbackScheme;

  final hasExpectedHost =
      callbackUri.host == StravaConfig.appCallbackHost;

  if (!hasExpectedScheme || !hasExpectedHost) {
    throw const StravaAuthException(
      code: 'invalid_callback',
      message: 'La dirección de retorno de Strava no es válida.',
    );
  }
}

  String _generateState() {
    const characters =
        'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '0123456789';

    return List.generate(
      48,
      (_) => characters[_random.nextInt(characters.length)],
    ).join();
  }
}
