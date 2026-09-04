import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../core/config/api_config.dart';
import '../auth/auth_token_store.dart';

class RedemptionRealtimeService {
  RedemptionRealtimeService({
    AuthTokenStore? tokenStore,
    this.onRedemptionChanged,
  }) : _tokenStore = tokenStore ?? AuthTokenStore();

  final AuthTokenStore _tokenStore;
  final Future<void> Function()? onRedemptionChanged;

  HubConnection? _connection;
  bool _starting = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_disposed || _starting) {
      return;
    }

    final current = _connection;

    if (current != null &&
        current.state == HubConnectionState.Connected) {
      return;
    }

    _starting = true;

    try {
      final connection = HubConnectionBuilder()
          .withUrl(
            ApiConfig.athletesHubUrl('/hubs/redemptions'),
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                final token = await _tokenStore.getAccessToken();

                if (token == null || token.isEmpty) {
                  throw StateError(
                    'No hay un access token disponible para SignalR.',
                  );
                }

                return token;
              },
            ),
          )
          .withAutomaticReconnect()
          .build();

      connection.onclose(({error}) {
        debugPrint(
          'SignalR canjes: conexión cerrada'
          '${error == null ? '.' : ': $error'}',
        );
      });

      connection.onreconnecting(({error}) {
        debugPrint(
          'SignalR canjes: reconectando'
          '${error == null ? '...' : ': $error'}',
        );
      });

      connection.onreconnected(({connectionId}) {
        debugPrint(
          'SignalR canjes: reconectado. '
          'ConnectionId=${connectionId ?? '-'}',
        );
      });

      connection.on(
        'RedemptionChanged',
        (arguments) {
          debugPrint(
            'SignalR canjes: RedemptionChanged recibido.',
          );

          final callback = onRedemptionChanged;
          if (callback != null) {
            unawaited(callback());
          }
        },
      );

      _connection = connection;

      await connection.start();

      debugPrint(
        'SignalR canjes: conectado. '
        'ConnectionId=${connection.connectionId ?? '-'}',
      );
    } catch (error) {
      debugPrint(
        'SignalR canjes: no fue posible conectar: $error',
      );

      await _connection?.stop();
      _connection = null;
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    final connection = _connection;
    _connection = null;

    if (connection != null) {
      await connection.stop();
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(stop());
  }
}
