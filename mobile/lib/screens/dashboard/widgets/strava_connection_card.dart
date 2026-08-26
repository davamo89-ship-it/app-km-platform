import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/strava/strava_connection_controller.dart';
import '../../../services/strava/strava_sync_controller.dart';
import 'card_shell.dart';
import 'inline_status_message.dart';
import 'strava_card_header.dart';

class StravaConnectionCard extends StatelessWidget {
  const StravaConnectionCard({
    super.key,
    required this.status,
    required this.syncStatus,
    required this.onConnect,
    required this.onSync,
    required this.onDisconnect,
    required this.onRetryConnection,
    required this.onRetrySync,
    this.errorMessage,
    this.syncErrorMessage,
  });

  final StravaConnectionStatus status;
  final StravaSyncStatus syncStatus;
  final VoidCallback onConnect;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;
  final VoidCallback onRetryConnection;
  final VoidCallback onRetrySync;
  final String? errorMessage;
  final String? syncErrorMessage;

  bool get _isChecking => status == StravaConnectionStatus.checking;

  bool get _isAuthorizing => status == StravaConnectionStatus.authorizing;

  bool get _isConnected => status == StravaConnectionStatus.connected;

  bool get _hasError => status == StravaConnectionStatus.error;

  bool get _isSynchronizing => syncStatus == StravaSyncStatus.synchronizing;

  bool get _syncSucceeded => syncStatus == StravaSyncStatus.success;

  bool get _syncFailed => syncStatus == StravaSyncStatus.error;

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _buildCheckingCard();
    }

    if (_isConnected) {
      return _buildConnectedCard();
    }

    if (_hasError) {
      return _buildErrorCard();
    }

    return _buildDisconnectedCard();
  }

  Widget _buildCheckingCard() {
    return CardShell(
      backgroundColor: Colors.white,
      borderColor: AppColors.primary.withValues(alpha: 0.20),
      child: const Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Comprobando conexión con Strava...',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedCard() {
    return CardShell(
      backgroundColor: const Color(0xFFFFF3ED),
      borderColor: const Color(0xFFFF8A50).withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StravaCardHeader(
            icon: Icons.directions_run_rounded,
            iconColor: Color(0xFFFC4C02),
            title: 'Conecta tu cuenta de Strava',
          ),
          const SizedBox(height: 10),
          const Text(
            'Sincroniza tus actividades y convierte automáticamente tus kilómetros en puntos.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isAuthorizing ? null : onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFC4C02),
              ),
              icon: _isAuthorizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(
                _isAuthorizing ? 'Abriendo Strava...' : 'Conectar con Strava',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return CardShell(
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      borderColor: AppColors.primary.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StravaCardHeader(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primary,
            title: 'Cuenta de Strava conectada',
          ),
          const SizedBox(height: 10),
          Text(
            _isSynchronizing
                ? 'Consultando y procesando las actividades registradas hoy...'
                : _syncSucceeded
                ? 'La última sincronización terminó correctamente.'
                : 'Ya puedes sincronizar las actividades registradas hoy.',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          if (_syncFailed) ...[
            const SizedBox(height: 12),
            InlineStatusMessage(
              icon: Icons.error_outline_rounded,
              color: Colors.red,
              message:
                  syncErrorMessage ??
                  'No fue posible completar la sincronización.',
            ),
          ],
          if (_syncSucceeded) ...[
            const SizedBox(height: 12),
            const InlineStatusMessage(
              icon: Icons.task_alt_rounded,
              color: AppColors.primary,
              message:
                  'Las actividades válidas fueron procesadas y los duplicados fueron omitidos.',
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSynchronizing
                  ? null
                  : (_syncFailed ? onRetrySync : onSync),
              icon: _isSynchronizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _syncFailed ? Icons.refresh_rounded : Icons.sync_rounded,
                    ),
              label: Text(
                _isSynchronizing
                    ? 'Sincronizando...'
                    : _syncFailed
                    ? 'Intentar nuevamente'
                    : _syncSucceeded
                    ? 'Sincronizar otra vez'
                    : 'Sincronizar actividades',
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _isSynchronizing ? null : onDisconnect,
              child: const Text('Desconectar cuenta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return CardShell(
      backgroundColor: Colors.red.withValues(alpha: 0.06),
      borderColor: Colors.red.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StravaCardHeader(
            icon: Icons.error_outline_rounded,
            iconColor: Colors.red,
            title: 'No se pudo verificar Strava',
          ),
          const SizedBox(height: 10),
          Text(
            errorMessage ?? 'Ocurrió un error al revisar la conexión.',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetryConnection,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
            ),
          ),
        ],
      ),
    );
  }
}
